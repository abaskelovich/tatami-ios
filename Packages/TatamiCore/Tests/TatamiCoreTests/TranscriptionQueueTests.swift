import XCTest
@testable import TatamiCore

final class TranscriptionQueueTests: XCTestCase {
    func testPersistsBeforeNetworkAndPassesRecordingIDKey() async throws {
        let store = InMemoryJobStore()
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        let item = recording()
        try await queue.enqueue(item)
        let before = try await store.allJobs()
        let initialKeys = await network.keys
        XCTAssertEqual(before.map(\.state), [.pendingUpload])
        XCTAssertTrue(initialKeys.isEmpty)
        try await queue.processPending()
        let states = await network.observedStates
        let keys = await network.keys
        XCTAssertEqual(states, [.uploading(attempt: 1)])
        XCTAssertEqual(keys, [item.id.description])
    }

    func testFailedPersistencePreventsNetwork() async throws {
        let store = RejectingStore()
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        do {
            try await queue.enqueue(recording())
            XCTFail("Expected storage failure")
        } catch {}
        try await queue.processPending()
        let keys = await network.keys
        XCTAssertTrue(keys.isEmpty)
    }

    func testFailureKeepsRecordingAndSchedulesRetry() async throws {
        let store = InMemoryJobStore()
        let clock = TestClock()
        let queue = TranscriptionQueue(store: store, transcriber: FakeTranscriber(failuresBeforeSuccess: 1), clock: clock)
        let item = recording()
        try await queue.enqueue(item)
        try await queue.processPending()
        let jobs = try await store.allJobs()
        XCTAssertEqual(jobs.count, 1)
        XCTAssertEqual(jobs.first?.recording, item)
        XCTAssertEqual(jobs.first?.state, .failed(reason: "transcription", attempt: 1))
        XCTAssertEqual(jobs.first?.nextAttemptAt, clock.now().addingTimeInterval(2))
    }

    func testRetryWaitsThenMarksTranscribed() async throws {
        let store = InMemoryJobStore()
        let clock = TestClock()
        let queue = TranscriptionQueue(store: store, transcriber: FakeTranscriber(failuresBeforeSuccess: 1, text: "done"), clock: clock)
        try await queue.enqueue(recording())
        try await queue.processPending()
        try await queue.processPending()
        let waiting = try await store.allJobs()
        XCTAssertEqual(waiting.first?.state, .failed(reason: "transcription", attempt: 1))
        clock.advance(2)
        try await queue.processPending()
        let finished = try await store.allJobs()
        XCTAssertEqual(finished.first?.state, .transcribed(text: "done"))
        XCTAssertNil(finished.first?.nextAttemptAt)
    }

    func testBackoffDoublesAndCaps() async throws {
        let store = InMemoryJobStore()
        let clock = TestClock()
        let queue = TranscriptionQueue(store: store, transcriber: FakeTranscriber(failuresBeforeSuccess: 10),
                                       clock: clock, baseDelay: 2, maximumDelay: 5)
        try await queue.enqueue(recording())
        for (index, delay) in [2.0, 4.0, 5.0, 5.0].enumerated() {
            try await queue.processPending()
            let jobs = try await store.allJobs()
            XCTAssertEqual(jobs.first?.state, .failed(reason: "transcription", attempt: index + 1))
            XCTAssertEqual(jobs.first?.nextAttemptAt, clock.now().addingTimeInterval(delay))
            clock.advance(delay)
        }
    }

    func testEligibleJobsAreProcessedFIFO() async throws {
        let store = InMemoryJobStore()
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        let first = recording(at: Date(timeIntervalSince1970: 10))
        let second = recording(at: Date(timeIntervalSince1970: 20))
        try await queue.enqueue(second)
        try await queue.enqueue(first)
        try await queue.processPending()
        let keys = await network.keys
        XCTAssertEqual(keys, [first.id.description, second.id.description])
    }

    func testReenqueueDoesNotDuplicateOrResetSuccess() async throws {
        let store = InMemoryJobStore()
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        let item = recording()
        try await queue.enqueue(item)
        try await queue.processPending()
        try await queue.enqueue(item)
        try await queue.processPending()
        let jobs = try await store.allJobs()
        let keys = await network.keys
        XCTAssertEqual(jobs.count, 1)
        XCTAssertEqual(jobs.first?.state, .transcribed(text: "test result"))
        XCTAssertEqual(keys.count, 1)
    }

    func testInterruptedUploadRecoversWithSameKey() async throws {
        let store = InMemoryJobStore()
        let item = recording()
        await store.insertIfAbsent(TranscriptionJob(recording: item, state: .uploading(attempt: 1)))
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        try await queue.processPending()
        let states = await network.observedStates
        let keys = await network.keys
        XCTAssertEqual(states, [.uploading(attempt: 2)])
        XCTAssertEqual(keys, [item.id.description])
    }

    func testConcurrentPassesDoNotUploadTwice() async throws {
        let store = InMemoryJobStore()
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        try await queue.enqueue(recording())
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 { group.addTask { try await queue.processPending() } }
            try await group.waitForAll()
        }
        let keys = await network.keys
        XCTAssertEqual(keys.count, 1)
    }

    func testResultWriteFailureRetainsJobAndAudioReference() async throws {
        let store = ResultRejectingStore()
        let network = InspectingTranscriber(store: store)
        let queue = TranscriptionQueue(store: store, transcriber: network)
        let item = recording()
        try await queue.enqueue(item)
        do {
            try await queue.processPending()
            XCTFail("Expected result persistence failure")
        } catch {}
        let retained = await store.allJobs()
        XCTAssertEqual(retained.first?.recording, item)
        XCTAssertEqual(retained.first?.state, .uploading(attempt: 1))
        // A fresh owner can recover the interrupted job, with the original key.
        let recovered = TranscriptionQueue(store: store, transcriber: network)
        do {
            try await recovered.processPending()
            XCTFail("Expected result persistence failure again")
        } catch {}
        let keys = await network.keys
        XCTAssertEqual(keys, [item.id.description, item.id.description])
    }
}
