import XCTest
@testable import Breath

@MainActor
final class ConfigurationViewModelTests: XCTestCase {

    nonisolated(unsafe) private var defaults: UserDefaults!
    nonisolated(unsafe) private var suiteName: String = ""

    override func setUp() {
        super.setUp()
        // Izolovaný suite pro každý test.
        suiteName = "test.breath.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testDefaultValuesMatchSessionConfigurationDefault() {
        let vm = ConfigurationViewModel(defaults: defaults)
        XCTAssertEqual(vm.speed, .standard)
        XCTAssertEqual(vm.rounds, 3)
        XCTAssertEqual(vm.breathsBeforeRetention, 35)
        XCTAssertTrue(vm.backgroundMusicEnabled)
        XCTAssertFalse(vm.hapticFeedback)
    }

    func testChangesArePersistedToDefaults() {
        let vm = ConfigurationViewModel(defaults: defaults)
        vm.rounds = 4
        vm.hapticFeedback = true

        let vm2 = ConfigurationViewModel(defaults: defaults)
        XCTAssertEqual(vm2.rounds, 4)
        XCTAssertTrue(vm2.hapticFeedback)
    }

    func testSetSpeedBlocksPremiumForFreeTier() {
        let vm = ConfigurationViewModel(defaults: defaults)
        let ok = vm.setSpeed(.fast, isPremium: false)
        XCTAssertFalse(ok)
        XCTAssertEqual(vm.speed, .standard)
    }

    func testSetSpeedAllowsPremiumForPaidTier() {
        let vm = ConfigurationViewModel(defaults: defaults)
        let ok = vm.setSpeed(.fast, isPremium: true)
        XCTAssertTrue(ok)
        XCTAssertEqual(vm.speed, .fast)
    }

    func testSetSpeedAllowsStandardForFreeTier() {
        let vm = ConfigurationViewModel(defaults: defaults)
        let ok = vm.setSpeed(.standard, isPremium: false)
        XCTAssertTrue(ok)
    }

    func testMakeSessionConfigurationReflectsCurrentState() {
        let vm = ConfigurationViewModel(defaults: defaults)
        vm.rounds = 2
        vm.breathsBeforeRetention = 40
        vm.pingAndGong = false

        let config = vm.makeSessionConfiguration()
        XCTAssertEqual(config.rounds, 2)
        XCTAssertEqual(config.breathsBeforeRetention, 40)
        XCTAssertFalse(config.pingAndGong)
    }
}
