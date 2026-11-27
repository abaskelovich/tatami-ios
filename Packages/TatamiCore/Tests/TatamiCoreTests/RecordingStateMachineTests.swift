import XCTest
@testable import TatamiCore

final class RecordingStateMachineTests: XCTestCase {
    func testCaptureLifecycleAndReset() throws {
        var machine = RecordingStateMachine()
        XCTAssertEqual(machine.state, .idle)
        XCTAssertEqual(try machine.send(.requestPermission).get(), .requestingPermission)
        XCTAssertEqual(try machine.send(.permissionGranted).get(), .recording)
        XCTAssertEqual(try machine.send(.stop).get(), .finalizing)
        XCTAssertEqual(try machine.send(.save).get(), .saved)
        XCTAssertEqual(try machine.send(.reset).get(), .idle)
    }

    func testInvalidTransitionReturnsErrorWithoutMutation() {
        var machine = RecordingStateMachine()
        guard case .failure(let error) = machine.send(.stop) else {
            return XCTFail("Expected invalid transition")
        }
        XCTAssertEqual(error.state, .idle)
        XCTAssertEqual(error.event, .stop)
        XCTAssertEqual(machine.state, .idle)
    }

    func testPermissionFailureCanReset() throws {
        var machine = RecordingStateMachine()
        try machine.send(.requestPermission).get()
        XCTAssertEqual(try machine.send(.fail(reason: "permission")).get(), .failed(reason: "permission"))
        XCTAssertEqual(try machine.send(.reset).get(), .idle)
    }

    func testFinalizationFailureNeverBecomesSaved() throws {
        var machine = RecordingStateMachine()
        try machine.send(.requestPermission).get()
        try machine.send(.permissionGranted).get()
        try machine.send(.stop).get()
        try machine.send(.fail(reason: "storage")).get()
        XCTAssertThrowsError(try machine.send(.save).get())
        XCTAssertEqual(machine.state, .failed(reason: "storage"))
    }

    func testFailedFinalizationCanRetryAndSave() throws {
        var machine = RecordingStateMachine()
        try machine.send(.requestPermission).get()
        try machine.send(.permissionGranted).get()
        try machine.send(.stop).get()
        try machine.send(.fail(reason: "storage")).get()
        XCTAssertEqual(try machine.send(.retryFinalization).get(), .finalizing)
        XCTAssertEqual(try machine.send(.save).get(), .saved)
    }
}
