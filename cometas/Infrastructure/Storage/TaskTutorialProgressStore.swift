import Foundation

protocol TaskTutorialProgressStoring {
    var hasCompletedCurrentTutorial: Bool { get }
    func markCurrentTutorialCompleted()
}

struct UserDefaultsTaskTutorialProgressStore: TaskTutorialProgressStoring {
    static let currentTutorialVersion = 1

    private let defaults: UserDefaults
    private let completedVersionKey = "taskTutorialCompletedVersion"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompletedCurrentTutorial: Bool {
        defaults.integer(forKey: completedVersionKey) >= Self.currentTutorialVersion
    }

    func markCurrentTutorialCompleted() {
        defaults.set(Self.currentTutorialVersion, forKey: completedVersionKey)
    }
}
