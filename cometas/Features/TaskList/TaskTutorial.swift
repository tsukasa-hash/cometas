import Combine
import SwiftUI

enum TaskTutorialStep: Int, CaseIterable {
    case welcome
    case addTask
    case openDetails
    case recordDone
    case deleteTask

    var number: Int { rawValue + 1 }

    var title: String {
        switch self {
        case .welcome: return "コメタスへようこそ"
        case .addTask: return "タスクを追加"
        case .openDetails: return "詳細を開く"
        case .recordDone: return "実績を登録"
        case .deleteTask: return "タスクを削除"
        }
    }

    var message: String {
        switch self {
        case .welcome:
            return "かんたんなチュートリアルを始めます。"
        case .addTask:
            return "右上の＋から、忘れたくない家事を追加できます。"
        case .openDetails:
            return "タスクをタップすると、間隔や次回の日付を確認・変更できます。"
        case .recordDone:
            return "作業が終わったら「やった」をタップ。実施日が履歴に残ります。"
        case .deleteTask:
            return "タスクを左にスワイプすると、このように削除ボタンが現れます。"
        }
    }

    var actionTitle: String {
        switch self {
        case .welcome, .addTask, .openDetails, .recordDone: return "次へ"
        case .deleteTask: return "はじめる"
        }
    }

    var showsPrimaryAction: Bool {
        true
    }

    var target: TaskTutorialTarget? {
        switch self {
        case .welcome: return nil
        case .addTask: return .addButton
        case .openDetails: return .taskRow
        case .recordDone: return .doneButton
        case .deleteTask: return .deletePreview
        }
    }
}

final class TaskTutorialViewModel: ObservableObject {
    @Published private(set) var step: TaskTutorialStep?

    private let progressStore: TaskTutorialProgressStoring

    init(progressStore: TaskTutorialProgressStoring = UserDefaultsTaskTutorialProgressStore()) {
        self.progressStore = progressStore
        step = progressStore.hasCompletedCurrentTutorial ? nil : .welcome
    }

    func advance() {
        guard let step else { return }

        guard let nextStep = TaskTutorialStep(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        setStepWithoutAnimation(nextStep)
    }

    func goBack() {
        guard let step, let previousStep = TaskTutorialStep(rawValue: step.rawValue - 1) else {
            return
        }
        setStepWithoutAnimation(previousStep)
    }

    func finish() {
        progressStore.markCurrentTutorialCompleted()
        setStepWithoutAnimation(nil)
    }

    private func setStepWithoutAnimation(_ step: TaskTutorialStep?) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            self.step = step
        }
    }
}

enum TaskTutorialTarget: Hashable {
    case addButton
    case taskRow
    case doneButton
    case deletePreview
}

private struct TaskTutorialTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [TaskTutorialTarget: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [TaskTutorialTarget: Anchor<CGRect>],
        nextValue: () -> [TaskTutorialTarget: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, newValue in newValue }
    }
}

extension View {
    @ViewBuilder
    func taskTutorialTarget(_ target: TaskTutorialTarget?) -> some View {
        if let target {
            anchorPreference(key: TaskTutorialTargetPreferenceKey.self, value: .bounds) { anchor in
                [target: anchor]
            }
        } else {
            self
        }
    }

    func taskTutorialOverlay(
        step: TaskTutorialStep?,
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) -> some View {
        overlayPreferenceValue(TaskTutorialTargetPreferenceKey.self) { targets in
            GeometryReader { proxy in
                if let step {
                    TaskTutorialOverlay(
                        step: step,
                        targetFrame: step.target.flatMap { target in
                            targets[target].map { proxy[$0] }
                        },
                        containerSize: proxy.size,
                        onBack: onBack,
                        onNext: onNext,
                        onSkip: onSkip
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct TaskTutorialOverlay: View {
    let step: TaskTutorialStep
    let targetFrame: CGRect?
    let containerSize: CGSize
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    private var highlightedFrame: CGRect {
        guard let targetFrame else {
            return CGRect(x: containerSize.width / 2 - 22, y: 72, width: 44, height: 44)
        }
        return targetFrame.insetBy(dx: -8, dy: -7)
    }

    private var showsHighlight: Bool {
        step.target != nil
    }

    private var showsBubbleAboveTarget: Bool {
        highlightedFrame.midY > containerSize.height * 0.56
    }

    private var bubbleTop: CGFloat {
        let estimatedHeight: CGFloat = 205
        if !showsHighlight {
            return max(90, (containerSize.height - estimatedHeight) / 2)
        }
        if showsBubbleAboveTarget {
            return max(70, highlightedFrame.minY - estimatedHeight - 18)
        }
        return min(highlightedFrame.maxY + 18, containerSize.height - estimatedHeight - 24)
    }

    private var pointerOffset: CGFloat {
        min(max(highlightedFrame.midX - containerSize.width / 2, -130), 130)
    }

    var body: some View {
        ZStack(alignment: .top) {
            spotlight

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {}

            if showsHighlight {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: highlightedFrame.width, height: highlightedFrame.height)
                    .position(x: highlightedFrame.midX, y: highlightedFrame.midY)
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
                    .allowsHitTesting(false)
            }

            TutorialBubble(
                step: step,
                showsPointer: showsHighlight,
                pointsDown: showsBubbleAboveTarget,
                pointerOffset: pointerOffset,
                onBack: onBack,
                onNext: onNext,
                onSkip: onSkip
            )
            .padding(.horizontal, 24)
            .offset(y: bubbleTop)
        }
        .zIndex(100)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var spotlight: some View {
        if !showsHighlight {
            return AnyView(Color.black.opacity(0.52))
        }

        let containerFrame = CGRect(origin: .zero, size: containerSize)
        let hole = highlightedFrame.intersection(containerFrame)

        return AnyView(ZStack(alignment: .topLeading) {
            scrimRectangle(
                CGRect(x: 0, y: 0, width: containerSize.width, height: hole.minY)
            )
            scrimRectangle(
                CGRect(
                    x: 0,
                    y: hole.maxY,
                    width: containerSize.width,
                    height: containerSize.height - hole.maxY
                )
            )
            scrimRectangle(
                CGRect(x: 0, y: hole.minY, width: hole.minX, height: hole.height)
            )
            scrimRectangle(
                CGRect(
                    x: hole.maxX,
                    y: hole.minY,
                    width: containerSize.width - hole.maxX,
                    height: hole.height
                )
            )
        })
    }

    private func scrimRectangle(_ frame: CGRect) -> some View {
        Color.black.opacity(0.52)
            .frame(width: max(0, frame.width), height: max(0, frame.height))
            .offset(x: frame.minX, y: frame.minY)
    }
}

private struct TutorialBubble: View {
    let step: TaskTutorialStep
    let showsPointer: Bool
    let pointsDown: Bool
    let pointerOffset: CGFloat
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if showsPointer, !pointsDown { pointer }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(step.number) / \(TaskTutorialStep.allCases.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)

                    Spacer()

                    Button("スキップ", action: onSkip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(step.title)
                    .font(.headline)

                Text(step.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if step != .welcome {
                        Button("戻る", action: onBack)
                            .buttonStyle(.borderless)
                    }

                    Spacer()

                    if step.showsPrimaryAction {
                        Button(step.actionTitle, action: onNext)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                    }
                }
            }
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

            if showsPointer, pointsDown { pointer.rotationEffect(.degrees(180)) }
        }
    }

    private var pointer: some View {
        Triangle()
            .fill(Color(uiColor: .systemBackground))
            .frame(width: 20, height: 11)
            .offset(x: pointerOffset)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
