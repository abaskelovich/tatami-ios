import Foundation
import TatamiCore

func recording(id: RecordingID = RecordingID(), at date: Date = Date(timeIntervalSince1970: 100)) -> Recording {
    Recording(id: id, createdAt: date, duration: 3, fileName: "sample.wav", byteCount: 46)
}

final class TestClock: TatamiCore.Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var date = Date(timeIntervalSince1970: 1_000)
    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return date
    }
    func advance(_ seconds: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        date = date.addingTimeInterval(seconds)
    }
}

actor InspectingTranscriber: Transcribing {
    let store: any JobStore
    var keys: [String] = []
    var observedStates: [TranscriptionJob.State] = []
    init(store: any JobStore) { self.store = store }
    func transcribe(_ recording: Recording, idempotencyKey: String) async throws -> String {
        keys.append(idempotencyKey)
        let jobs = try await store.allJobs()
        if let job = jobs.first(where: { $0.id == recording.id }) {
            observedStates.append(job.state)
        }
        return "test result"
    }
}

actor RejectingStore: JobStore {
    func allJobs() -> [TranscriptionJob] { [] }
    func insertIfAbsent(_ job: TranscriptionJob) throws -> TranscriptionJob { throw FakeError.unavailable }
    func update(_ job: TranscriptionJob) throws { throw FakeError.unavailable }
}

actor ResultRejectingStore: JobStore {
    private var jobs: [TranscriptionJob] = []
    func allJobs() -> [TranscriptionJob] { jobs }
    func insertIfAbsent(_ job: TranscriptionJob) -> TranscriptionJob {
        if let existing = jobs.first(where: { $0.id == job.id }) { return existing }
        jobs.append(job)
        return job
    }
    func update(_ job: TranscriptionJob) throws {
        if case .transcribed = job.state { throw FakeError.unavailable }
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else {
            throw JobStoreError.missingJob
        }
        jobs[index] = job
    }
}
