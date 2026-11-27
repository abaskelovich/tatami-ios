import Foundation

public protocol AudioCapturing: Sendable {
    func requestPermission() async -> Bool
    func start() async throws
    func stop() async throws -> Recording
}

public protocol Transcribing: Sendable {
    func transcribe(_ recording: Recording, idempotencyKey: String) async throws -> String
}

/// One queue owns a store. Inserts must atomically preserve an existing job with the same ID.
/// There is deliberately no delete operation in this bootstrap.
public protocol JobStore: Sendable {
    func allJobs() async throws -> [TranscriptionJob]
    @discardableResult
    func insertIfAbsent(_ job: TranscriptionJob) async throws -> TranscriptionJob
    func update(_ job: TranscriptionJob) async throws
}

public protocol Clock: Sendable {
    func now() -> Date
}

public protocol IDGenerating: Sendable {
    func next() -> RecordingID
}

public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date { Date() }
}

public struct UUIDGenerator: IDGenerating {
    public init() {}
    public func next() -> RecordingID { RecordingID() }
}
