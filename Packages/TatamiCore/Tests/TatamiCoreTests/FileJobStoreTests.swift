import Foundation
import XCTest
@testable import TatamiCore

final class FileJobStoreTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: directory) }
        return directory
    }

    func testRoundTripSurvivesNewInstanceAndUpdate() async throws {
        let url = try temporaryDirectory().appendingPathComponent("nested/jobs.json")
        let first = FileJobStore(fileURL: url)
        var job = TranscriptionJob(recording: recording())
        try await first.insertIfAbsent(job)
        let second = FileJobStore(fileURL: url)
        let restored = try await second.allJobs()
        XCTAssertEqual(restored, [job])
        job.state = .failed(reason: "transcription", attempt: 2)
        job.nextAttemptAt = Date(timeIntervalSince1970: 2_000)
        try await second.update(job)
        let afterUpdate = try await FileJobStore(fileURL: url).allJobs()
        XCTAssertEqual(afterUpdate, [job])
    }

    func testDuplicateInsertPreservesExistingJob() async throws {
        let url = try temporaryDirectory().appendingPathComponent("jobs.json")
        let store = FileJobStore(fileURL: url)
        let item = recording()
        let done = TranscriptionJob(recording: item, state: .transcribed(text: "done"))
        try await store.insertIfAbsent(done)
        let existing = try await store.insertIfAbsent(TranscriptionJob(recording: item))
        let jobs = try await store.allJobs()
        XCTAssertEqual(existing, done)
        XCTAssertEqual(jobs, [done])
    }

    func testCorruptFileIsNotOverwritten() async throws {
        let url = try temporaryDirectory().appendingPathComponent("jobs.json")
        let original = Data("invalid json".utf8)
        try original.write(to: url)
        let store = FileJobStore(fileURL: url)
        do {
            try await store.insertIfAbsent(TranscriptionJob(recording: recording()))
            XCTFail("Expected decode failure")
        } catch {}
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testAllStatesAreCodable() throws {
        let states: [TranscriptionJob.State] = [
            .pendingUpload, .uploading(attempt: 1), .transcribed(text: "Пример"),
            .failed(reason: "transcription", attempt: 2)
        ]
        for state in states {
            let job = TranscriptionJob(recording: recording(), state: state)
            let data = try JSONEncoder().encode(job)
            XCTAssertEqual(try JSONDecoder().decode(TranscriptionJob.self, from: data), job)
        }
    }
}
