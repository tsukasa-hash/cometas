import Combine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [ManagedTask] = []

    private let registrationStore: TaskRegistrationStoring
    private let widgetReloader: WidgetTimelineReloading

    init(
        registrationStore: TaskRegistrationStoring = UserDefaultsTaskRegistrationStore(),
        widgetReloader: WidgetTimelineReloading = WidgetCenterTimelineReloader()
    ) {
        self.registrationStore = registrationStore
        self.widgetReloader = widgetReloader
        reload()
    }

    var canAddTask: Bool {
        tasks.count < AppSettings.maximumTaskCount
    }

    func reload() {
        tasks = registrationStore.registeredTasks
    }

    @discardableResult
    func addTask() -> ManagedTask? {
        guard canAddTask, let task = registrationStore.registerNextTask() else {
            return nil
        }
        reload()
        return task
    }

    func deleteTask(_ task: ManagedTask) {
        registrationStore.deleteTask(task)
        reload()
        widgetReloader.reload()
    }

    func moveTask(_ task: ManagedTask, to targetTask: ManagedTask) {
        guard
            task != targetTask,
            let sourceIndex = tasks.firstIndex(of: task),
            let targetIndex = tasks.firstIndex(of: targetTask)
        else {
            return
        }

        tasks.move(
            fromOffsets: IndexSet(integer: sourceIndex),
            toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
        )
        registrationStore.setTaskOrder(tasks)
    }
}

struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    @State private var expandedTask: ManagedTask?
    @State private var expandedTaskFrame: CGRect = .zero
    @State private var draggedTask: ManagedTask?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.tasks) { task in
                        TaskDisclosureRow(
                            task: task,
                            isExpanded: expandedTask == task,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedTask = expandedTask == task ? nil : task
                                }
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.deleteTask(task)
                                    if expandedTask == task {
                                        expandedTask = nil
                                    }
                                }
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                        .onDrag {
                            draggedTask = task
                            return NSItemProvider(object: String(task.rawValue) as NSString)
                        }
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: TaskRowDropDelegate(
                                targetTask: task,
                                draggedTask: $draggedTask,
                                moveTask: { draggedTask, targetTask in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.moveTask(draggedTask, to: targetTask)
                                    }
                                }
                            )
                        )
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ExpandedTaskFramePreferenceKey.self,
                                    value: expandedTask == task
                                        ? proxy.frame(in: .named("taskList"))
                                        : .zero
                                )
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: "taskList")
            .onPreferenceChange(ExpandedTaskFramePreferenceKey.self) { frame in
                expandedTaskFrame = frame
            }
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    guard
                        let taskToClose = expandedTask,
                        !expandedTaskFrame.contains(value.location)
                    else {
                        return
                    }

                    DispatchQueue.main.async {
                        guard expandedTask == taskToClose else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedTask = nil
                        }
                    }
                }
            )
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollBounceBehavior(.basedOnSize)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let newTask = viewModel.addTask() else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedTask = newTask
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!viewModel.canAddTask)
                    .accessibilityLabel(
                        viewModel.canAddTask ? "タスクを追加" : "登録上限の5件に達しています"
                    )
                }
            }
        }
        .onAppear {
            viewModel.reload()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            viewModel.reload()
        }
    }
}

private struct ExpandedTaskFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let nextFrame = nextValue()
        if nextFrame != .zero {
            value = nextFrame
        }
    }
}

private struct TaskRowDropDelegate: DropDelegate {
    let targetTask: ManagedTask
    @Binding var draggedTask: ManagedTask?
    let moveTask: (ManagedTask, ManagedTask) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedTask, draggedTask != targetTask else { return }
        moveTask(draggedTask, targetTask)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedTask = nil
        return true
    }
}

private struct TaskDisclosureRow: View {
    @StateObject private var viewModel: SingleItemViewModel
    @EnvironmentObject private var historyStore: HistoryStore

    let isExpanded: Bool
    let onToggle: () -> Void

    init(task: ManagedTask, isExpanded: Bool, onToggle: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SingleItemViewModel(task: task))
        self.isExpanded = isExpanded
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.item.isEmpty ? "名称未設定" : viewModel.item)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("\(viewModel.interval.label)ごと")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(DatePresentation.remainingDaysText(until: viewModel.nextDueDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                editor
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            viewModel.reloadFromSettings()
        }
    }

    private var editor: some View {
        VStack(spacing: 0) {
            LabeledContent("タスク名") {
                TextField(
                    "名称",
                    text: Binding(
                        get: { viewModel.item },
                        set: { viewModel.setItem($0) }
                    )
                )
                .multilineTextAlignment(.trailing)
            }
            .frame(minHeight: 44)

            Divider()

            Picker(
                "間隔",
                selection: Binding(
                    get: { viewModel.interval },
                    set: { viewModel.setInterval($0) }
                )
            ) {
                ForEach(Interval.displayOrder) { interval in
                    Text("\(interval.label)ごと").tag(interval)
                }
            }
            .pickerStyle(.menu)
            .frame(minHeight: 44)

            Divider()

            DatePicker(
                "次回",
                selection: Binding(
                    get: { viewModel.nextDueDate },
                    set: { viewModel.setNextDueDate($0) }
                ),
                displayedComponents: .date
            )
            .environment(\.locale, DatePresentation.locale)
            .frame(minHeight: 44)

            Divider()

            HStack(spacing: 12) {
                Button("やった") {
                    viewModel.handleDone(historyStore: historyStore)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("今回はやらない") {
                    viewModel.handleSkip(historyStore: historyStore)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .controlSize(.regular)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(HistoryStore())
}
