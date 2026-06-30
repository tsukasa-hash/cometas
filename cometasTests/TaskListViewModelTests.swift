import XCTest
@testable import cometas

final class TaskListViewModelTests: XCTestCase {
    /// 目的: 一覧右上に表示する登録数/上限数の文字列が、現在の登録数と上限5を反映することを保証する。
    func testRegistrationLimitTextReflectsCurrentCountAndMaximum() {
        let store = StubTaskRegistrationStore(tasks: [.primary, .secondary])
        let viewModel = TaskListViewModel(
            registrationStore: store,
            widgetReloader: NoopWidgetTimelineReloader()
        )

        XCTAssertEqual(viewModel.registrationLimitText, "2/5")
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
