import XCTest
import TatamiCore
@testable import Tatami

final class TatamiTests: XCTestCase {
    @MainActor
    func testDemoCaptureReachesDurableHistory() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(directory: directory)
        // A cancelled run performs initial loading but does not start the scheduler loop.
        let loading = Task { await model.run() }
        loading.cancel()
        await loading.value
        XCTAssertTrue(model.isReady)
        await model.toggleRecording()
        XCTAssertEqual(model.machine.state, .recording)
        await model.toggleRecording()
        XCTAssertEqual(model.machine.state, .saved)
        XCTAssertEqual(model.jobs.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("jobs.json").path))
        let restored = AppModel(directory: directory)
        let reload = Task { await restored.run() }
        reload.cancel()
        await reload.value
        XCTAssertEqual(restored.jobs, model.jobs)
    }
}
