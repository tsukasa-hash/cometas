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

    var registrationLimitText: String {
        "\(tasks.count)/\(AppSettings.maximumTaskCount)"
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
    @StateObject private var viewModel: TaskListViewModel
    @StateObject private var tutorialViewModel: TaskTutorialViewModel
    @State private var expandedTask: ManagedTask?
    @State private var expandedTaskFrame: CGRect = .zero
    @State private var draggedTask: ManagedTask?

    init(
        viewModel: TaskListViewModel = TaskListViewModel(),
        tutorialProgressStore: TaskTutorialProgressStoring = UserDefaultsTaskTutorialProgressStore()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _tutorialViewModel = StateObject(
            wrappedValue: TaskTutorialViewModel(progressStore: tutorialProgressStore)
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.tasks) { task in
                        let showsTutorialDeleteAction = tutorialViewModel.step == .deleteTask
                            && task == viewModel.tasks.first

                        ZStack(alignment: .trailing) {
                            if showsTutorialDeleteAction {
                                TutorialDeleteActionPreview()
                                    .transition(.move(edge: .trailing))
                            }

                            TaskDisclosureRow(
                                task: task,
                                isExpanded: expandedTask == task,
                                isTutorialTask: task == viewModel.tasks.first,
                                onToggle: {
                                    toggleTask(task)
                                }
                            )
                            .background(Color(uiColor: .systemBackground))
                            .offset(x: showsTutorialDeleteAction ? -80 : 0)
                        }
                        .clipped()
                        .animation(.easeInOut(duration: 0.25), value: showsTutorialDeleteAction)
                        .taskTutorialTarget(
                            showsTutorialDeleteAction ? .deletePreview : nil
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
                } header: {
                    HStack {
                        Spacer()
                        Text(viewModel.registrationLimitText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("登録数の上限")
                            .accessibilityValue(viewModel.registrationLimitText)
                    }
                    .textCase(nil)
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
                        setExpandedTaskWithoutAnimation(nil)
                    }
                }
            )
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("タスク一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VStack(spacing: 0) {
                        Button {
                            guard let newTask = viewModel.addTask() else { return }
                            setExpandedTaskWithoutAnimation(newTask)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(!viewModel.canAddTask)
                        .accessibilityLabel(
                            viewModel.canAddTask ? "タスクを追加" : "登録上限の5件に達しています"
                        )
                        .taskTutorialTarget(.addButton)

                    }
                }
            }
        }
        .taskTutorialOverlay(
            step: tutorialViewModel.step,
            onBack: handleTutorialBack,
            onNext: handleTutorialNext,
            onSkip: tutorialViewModel.finish
        )
        .onAppear {
            viewModel.reload()
            updateExpandedTask(for: tutorialViewModel.step)
        }
        .onChange(of: tutorialViewModel.step) { _, step in
            updateExpandedTask(for: step)
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            viewModel.reload()
        }
    }

    private func setExpandedTaskWithoutAnimation(_ task: ManagedTask?) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            expandedTask = task
        }
    }

    private func handleTutorialBack() {
        tutorialViewModel.goBack()
    }

    private func toggleTask(_ task: ManagedTask) {
        setExpandedTaskWithoutAnimation(expandedTask == task ? nil : task)
    }

    private func handleTutorialNext() {
        if tutorialViewModel.step == .addTask, viewModel.tasks.isEmpty {
            _ = viewModel.addTask()
        }
        tutorialViewModel.advance()
    }

    private func updateExpandedTask(for step: TaskTutorialStep?) {
        switch step {
        case .recordDone:
            setExpandedTaskWithoutAnimation(viewModel.tasks.first)
        case .openDetails, .deleteTask:
            setExpandedTaskWithoutAnimation(nil)
        case .welcome, .addTask, nil:
            break
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
    let isTutorialTask: Bool
    let onToggle: () -> Void

    init(
        task: ManagedTask,
        isExpanded: Bool,
        isTutorialTask: Bool,
        onToggle: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: SingleItemViewModel(task: task))
        self.isExpanded = isExpanded
        self.isTutorialTask = isTutorialTask
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
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(viewModel.interval.label)ごと")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
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
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .taskTutorialTarget(isTutorialTask ? .taskRow : nil)

            if isExpanded {
                Divider()
                editor
                    .transition(.identity)
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
                .taskTutorialTarget(isTutorialTask ? .doneButton : nil)

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

private struct TutorialDeleteActionPreview: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "trash")
                .font(.body.weight(.semibold))
            Text("削除")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(width: 80)
        .frame(maxHeight: .infinity)
        .background(Color(uiColor: .systemRed))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("削除ボタンの例")
    }
}

#Preview {
    TaskListView()
        .environmentObject(HistoryStore())
}
