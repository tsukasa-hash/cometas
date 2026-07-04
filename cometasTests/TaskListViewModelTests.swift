import XCTest
@testable import cometas

final class TaskListViewModelTests: XCTestCase {
    /// 目的: 詳細表示と削除の案内が、どちらも実際のタスク行をハイライトすることを保証する。
    func testTutorialUsesTaskRowForDetailsAndDeletion() async {
        await MainActor.run {
            XCTAssertNil(TaskTutorialStep.welcome.target)
            XCTAssertEqual(TaskTutorialStep.openDetails.target, .taskRow)
            XCTAssertEqual(TaskTutorialStep.deleteTask.target, .deletePreview)
            XCTAssertTrue(TaskTutorialStep.welcome.showsPrimaryAction)
            XCTAssertTrue(TaskTutorialStep.addTask.showsPrimaryAction)
            XCTAssertTrue(TaskTutorialStep.openDetails.showsPrimaryAction)
            XCTAssertTrue(TaskTutorialStep.recordDone.showsPrimaryAction)
            XCTAssertTrue(TaskTutorialStep.deleteTask.showsPrimaryAction)
        }
    }

    /// 目的: 一覧上部に表示する登録数/上限数の文字列が、現在の登録数と上限5を反映することを保証する。
    func testRegistrationLimitTextReflectsCurrentCountAndMaximum() async {
        await MainActor.run {
            let store = StubTaskRegistrationStore(tasks: [.primary, .secondary])
            let viewModel = TaskListViewModel(
                registrationStore: store,
                widgetReloader: NoopWidgetTimelineReloader()
            )

            XCTAssertEqual(viewModel.registrationLimitText, "2/5")
        }
    }
}

private final class StubTaskRegistrationStore: TaskRegistrationStoring {
    var tasks: [ManagedTask]

    init(tasks: [ManagedTask]) {
        self.tasks = tasks
    }

    var registeredTasks: [ManagedTask] {
        tasks
    }

    func registerNextTask() -> ManagedTask? {
        nil
    }

    func deleteTask(_ task: ManagedTask) {
        tasks.removeAll { $0 == task }
    }

    func setTaskOrder(_ tasks: [ManagedTask]) {
        self.tasks = tasks
    }
}
