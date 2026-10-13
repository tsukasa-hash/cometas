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

    var canAddTask: Bool { tasks.count < AppSettings.maximumTaskCount }
    var registrationLimitText: String { "\(tasks.count)/\(AppSettings.maximumTaskCount)" }

    func reload() { tasks = registrationStore.registeredTasks }

    @discardableResult
    func addTask() -> ManagedTask? {
        guard canAddTask, let task = registrationStore.registerNextTask() else { return nil }
        reload()
        return task
    }

    func deleteTask(_ task: ManagedTask) {
        registrationStore.deleteTask(task)
        reload()
        widgetReloader.reload()
    }

    func moveTask(_ task: ManagedTask, to targetTask: ManagedTask) {
        guard task != targetTask,
              let sourceIndex = tasks.firstIndex(of: task),
              let targetIndex = tasks.firstIndex(of: targetTask) else { return }
        tasks.move(fromOffsets: IndexSet(integer: sourceIndex),
                   toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex)
        registrationStore.setTaskOrder(tasks)
    }
}

private enum TaskHomeStyle {
    static let paper = Color(red: 245 / 255, green: 243 / 255, blue: 237 / 255)
    static let card = Color(red: 251 / 255, green: 250 / 255, blue: 246 / 255)
    static let ink = Color(red: 41 / 255, green: 45 / 255, blue: 43 / 255)
    static let muted = Color(red: 134 / 255, green: 137 / 255, blue: 130 / 255)
    static let sage = Color(red: 104 / 255, green: 123 / 255, blue: 107 / 255)
    static let sageSoft = Color(red: 223 / 255, green: 229 / 255, blue: 220 / 255)
    static let line = Color(red: 226 / 255, green: 224 / 255, blue: 217 / 255)
}

struct TaskListView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @StateObject private var viewModel: TaskListViewModel
    @State private var expandedTask: ManagedTask?
    @State private var draggedTask: ManagedTask?
    @State private var isShowingCreation = false

    init(viewModel: TaskListViewModel = TaskListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var dueSoonCount: Int {
        viewModel.tasks.filter { task in
            let days = Calendar.current.dateComponents(
                [.day], from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: AppSettings.nextDueDate(task: task))
            ).day ?? 0
            return (0...3).contains(days)
        }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Text("\(dueSoonCount)件がもうすぐです")
                        .font(.system(size: 13))
                        .foregroundStyle(TaskHomeStyle.muted)
                        .padding(.top, 21)
                        .padding(.bottom, 14)

                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.tasks) { task in
                            TaskDisclosureRow(
                                task: task,
                                isExpanded: expandedTask == task,
                                onToggle: { withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedTask = expandedTask == task ? nil : task
                                } }
                            )
                            .environmentObject(historyStore)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteTask(task)
                                    if expandedTask == task { expandedTask = nil }
                                } label: { Label("削除", systemImage: "trash") }
                            }
                            .onDrag {
                                draggedTask = task
                                return NSItemProvider(object: String(task.rawValue) as NSString)
                            }
                            .onDrop(of: [UTType.plainText], delegate: TaskRowDropDelegate(
                                targetTask: task,
                                draggedTask: $draggedTask,
                                moveTask: { source, target in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.moveTask(source, to: target)
                                    }
                                }
                            ))
                        }
                    }

                    if viewModel.canAddTask {
                        Button {
                            isShowingCreation = true
                        } label: {
                            Label("タスクを追加", systemImage: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(TaskHomeStyle.sage)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background {
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(TaskHomeStyle.sage.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(TaskHomeStyle.paper.ignoresSafeArea())
            .scrollBounceBehavior(.basedOnSize)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingCreation) {
                TaskCreationView(onSave: { name, interval, lastDoneDate in
                    guard let task = viewModel.addTask() else { return }
                    let editor = SingleItemViewModel(task: task)
                    editor.setItem(name)
                    editor.setInterval(interval)
                    editor.setLastDoneDate(lastDoneDate)
                    expandedTask = task
                })
            }
        }
        .tint(TaskHomeStyle.sage)
        .onAppear { viewModel.reload() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.reload()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("cometas")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(TaskHomeStyle.sage)
                Text("次にすること")
                    .font(.system(size: 29, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(TaskHomeStyle.ink)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(viewModel.tasks.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(TaskHomeStyle.ink)
                Text("/ 5")
                    .font(.system(size: 11))
                    .foregroundStyle(TaskHomeStyle.muted)
            }
        }
//        .padding(.top, 2)
    }
}

private struct TaskCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var interval: Interval = .oneMonth
    @State private var lastDoneDate = Calendar.current.startOfDay(for: Date())
    let onSave: (String, Interval, Date) -> Void

    private var nextDueDate: Date {
        NextDueDateCalculator.calculate(from: lastDoneDate, interval: interval)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("新しい習慣")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(TaskHomeStyle.sage)
                    Text("忘れたくないことを\nひとつだけ。")
                        .font(.system(size: 25, weight: .bold))
                        .tracking(-0.6)
                        .foregroundStyle(TaskHomeStyle.ink)
                    Text("必要な頃に、cometasが静かにお知らせします。")
                        .font(.system(size: 11))
                        .foregroundStyle(TaskHomeStyle.muted)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("タスク名").font(.system(size: 10, weight: .semibold)).foregroundStyle(TaskHomeStyle.muted)
                        TextField("例：加湿器の手入れ", text: $name)
                            .font(.system(size: 13))
                            .padding(.horizontal, 11).frame(height: 40)
                            .background(TaskHomeStyle.paper, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(TaskHomeStyle.sage.opacity(0.65), lineWidth: 1))
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("繰り返し間隔").font(.system(size: 10, weight: .semibold)).foregroundStyle(TaskHomeStyle.muted)
                        Picker("繰り返し間隔", selection: $interval) {
                            ForEach(Interval.displayOrder) { value in Text("\(value.label)ごと").tag(value) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6).frame(height: 40)
                        .background(TaskHomeStyle.paper, in: RoundedRectangle(cornerRadius: 9))
                    }
                    DatePicker("最終実施日", selection: $lastDoneDate, displayedComponents: .date)
                        .font(.system(size: 10, weight: .semibold))
                        .environment(\.locale, DatePresentation.locale)
                        .padding(.horizontal, 10).frame(height: 40)
                        .background(TaskHomeStyle.paper, in: RoundedRectangle(cornerRadius: 9))
                    HStack {
                        Text("次回予定日").foregroundStyle(TaskHomeStyle.muted)
                        Spacer()
                        Text(nextDueDate.formatted(DatePresentation.ymdFormat)).foregroundStyle(TaskHomeStyle.ink)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10).frame(height: 40)
                    .background(TaskHomeStyle.paper, in: RoundedRectangle(cornerRadius: 9))
                    Button {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        onSave(trimmedName, interval, lastDoneDate)
                        dismiss()
                    } label: {
                        Text("タスクを追加")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(TaskHomeStyle.sage, in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                    .padding(.top, 2)
                }
                .padding(14)
                .background(TaskHomeStyle.card, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(TaskHomeStyle.line.opacity(0.55), lineWidth: 0.7))
            }
            .padding(.horizontal, 20)
        }
        .background(TaskHomeStyle.paper.ignoresSafeArea())
        .navigationTitle("新しいタスク")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("戻る")
            }
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
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool { draggedTask = nil; return true }
}

private struct TaskDisclosureRow: View {
    @StateObject private var viewModel: SingleItemViewModel
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var isEditing = false
    let isExpanded: Bool
    let onToggle: () -> Void

    init(task: ManagedTask, isExpanded: Bool, onToggle: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SingleItemViewModel(task: task))
        self.isExpanded = isExpanded
        self.onToggle = onToggle
    }

    private var dueText: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: viewModel.nextDueDate)
        ).day ?? 0
        switch days {
        case 0: return "今日"
        case 1...: return "あと\(days)日"
        default: return "\(-days)日超過"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: onToggle) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.item.isEmpty ? "名称未設定" : viewModel.item)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(TaskHomeStyle.ink)
                                .lineLimit(1)
                            Text("次回 \(viewModel.nextDueDate.formatted(.dateTime.locale(DatePresentation.locale).month().day().weekday(.abbreviated)))")
                                .font(.system(size: 12))
                                .foregroundStyle(TaskHomeStyle.muted)
                        }
                        Spacer(minLength: 2)
                        Text(dueText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isDueSoon ? TaskHomeStyle.sage : TaskHomeStyle.muted)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(isDueSoon ? TaskHomeStyle.sageSoft : .clear, in: Capsule())
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TaskHomeStyle.muted.opacity(0.75))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .frame(width: 16)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    viewModel.handleDone(historyStore: historyStore)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(TaskHomeStyle.sage)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(TaskHomeStyle.sage.opacity(0.26), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
                .accessibilityLabel("\(viewModel.item)を完了")
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 85)

            if isExpanded {
                Rectangle().fill(TaskHomeStyle.line).frame(height: 1).padding(.horizontal, 14)
                if isEditing { editor } else { details }
            }
        }
        .background(TaskHomeStyle.card, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(TaskHomeStyle.line.opacity(0.55), lineWidth: 0.7))
        .onAppear { viewModel.reloadFromSettings() }
        .onChange(of: isExpanded) { _, expanded in
            if expanded { viewModel.reloadFromSettings(); isEditing = false }
        }
    }

    private var isDueSoon: Bool {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: viewModel.nextDueDate)
        ).day ?? 0
        return (0...3).contains(days)
    }

    private var details: some View {
        VStack(spacing: 0) {
            detailLine("最終実施日", value: viewModel.lastDoneDate.formatted(DatePresentation.ymdFormat))
            detailLine("次回予定日", value: viewModel.nextDueDate.formatted(DatePresentation.ymdFormat))
            detailLine("繰り返し", value: "\(viewModel.interval.label)ごと")
            HStack(spacing: 20) {
                Button { isEditing = true } label: {
                    Label("編集", systemImage: "pencil").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(TaskHomeStyle.ink).frame(maxWidth: .infinity, minHeight: 40)
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(TaskHomeStyle.line, lineWidth: 1))
                }
                Button { viewModel.handleDone(historyStore: historyStore) } label: {
                    Label("完了", systemImage: "checkmark").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 40)
                        .background(TaskHomeStyle.sage, in: RoundedRectangle(cornerRadius: 11))
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 22)
            Button("今回はスキップ") { viewModel.handleSkip(historyStore: historyStore) }
                .font(.system(size: 13)).foregroundStyle(TaskHomeStyle.muted)
                .padding(.top, 22)
        }
        .padding(.horizontal, 14).padding(.bottom, 30)
    }

    private var editor: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                editorLabel("タスク名")
                TextField("タスク名", text: Binding(get: { viewModel.item }, set: viewModel.setItem))
                    .font(.system(size: 12))
                    .padding(.horizontal, 10).frame(height: 34)
                    .background(TaskHomeStyle.paper, in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(TaskHomeStyle.line, lineWidth: 1))
            }
            editorDivider
            HStack(spacing: 10) {
                editorLabel("繰り返し")
                Picker("繰り返し", selection: Binding(get: { viewModel.interval }, set: viewModel.setInterval)) {
                    ForEach(Interval.displayOrder) { Text("\($0.label)ごと").tag($0) }
                }
                .pickerStyle(.menu)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                .background(TaskHomeStyle.paper, in: RoundedRectangle(cornerRadius: 9))
            }
            editorDivider
            HStack(spacing: 10) {
                editorLabel("最終実施日")
                DatePicker("最終実施日", selection: Binding(get: { viewModel.lastDoneDate }, set: viewModel.setLastDoneDate), displayedComponents: .date)
                    .labelsHidden().datePickerStyle(.compact)
                    .environment(\.locale, DatePresentation.locale)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            editorDivider
            HStack(spacing: 10) {
                editorLabel("次回予定日")
                DatePicker("次回予定日", selection: Binding(get: { viewModel.nextDueDate }, set: viewModel.setNextDueDate), displayedComponents: .date)
                    .labelsHidden().datePickerStyle(.compact)
                    .environment(\.locale, DatePresentation.locale)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 12) {
                Button("キャンセル") { viewModel.reloadFromSettings(); isEditing = false }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TaskHomeStyle.muted)
                    .frame(maxWidth: .infinity, minHeight: 40)
                Button("保存") { isEditing = false }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(TaskHomeStyle.sage, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private var editorDivider: some View {
        Rectangle().fill(TaskHomeStyle.line).frame(height: 0.7)
    }

    private func editorLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10))
            .foregroundStyle(TaskHomeStyle.muted)
            .frame(width: 76, alignment: .leading)
    }

    private func detailLine(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(TaskHomeStyle.muted)
            Spacer()
            Text(value).foregroundStyle(TaskHomeStyle.ink).fontWeight(.medium)
        }
        .font(.system(size: 14))
        .frame(height: 46)
        .overlay(alignment: .bottom) { Rectangle().fill(TaskHomeStyle.line).frame(height: 0.7) }
    }
}

#Preview {
    TaskListView().environmentObject(HistoryStore())
}
