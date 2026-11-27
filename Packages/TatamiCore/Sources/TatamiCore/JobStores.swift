import Foundation

public enum JobStoreError: Error, Sendable {
    case missingJob, duplicateIDs
}

public actor InMemoryJobStore: JobStore {
    private var jobs: [TranscriptionJob] = []
    public init() {}
    public func allJobs() -> [TranscriptionJob] { jobs }
    public func insertIfAbsent(_ job: TranscriptionJob) -> TranscriptionJob {
        if let existing = jobs.first(where: { $0.id == job.id }) { return existing }
        jobs.append(job)
        return job
    }
    public func update(_ job: TranscriptionJob) throws {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else {
            throw JobStoreError.missingJob
        }
        jobs[index] = job
    }
}

/// Reads on each operation so a failed write never leaves an optimistic in-memory state.
/// A malformed existing file is surfaced, never replaced by an empty store.
public actor FileJobStore: JobStore {
    private let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func allJobs() throws -> [TranscriptionJob] { try read() }

    public func insertIfAbsent(_ job: TranscriptionJob) throws -> TranscriptionJob {
        var jobs = try read()
        if let existing = jobs.first(where: { $0.id == job.id }) { return existing }
        jobs.append(job)
        try write(jobs)
        return job
    }

    public func update(_ job: TranscriptionJob) throws {
        var jobs = try read()
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else {
            throw JobStoreError.missingJob
        }
        jobs[index] = job
        try write(jobs)
    }

    private func read() throws -> [TranscriptionJob] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let jobs = try JSONDecoder().decode([TranscriptionJob].self, from: Data(contentsOf: fileURL))
        guard Set(jobs.map(\.id)).count == jobs.count else { throw JobStoreError.duplicateIDs }
        return jobs
    }

    private func write(_ jobs: [TranscriptionJob]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        // Foundation writes a sibling temporary file and atomically replaces the destination.
        try JSONEncoder().encode(jobs).write(to: fileURL, options: .atomic)
    }
}
