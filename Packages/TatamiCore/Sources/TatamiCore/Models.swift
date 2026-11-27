import Foundation

public struct RecordingID: Codable, Sendable, Equatable, Hashable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString.lowercased() }
}

public struct Recording: Codable, Sendable, Equatable, Identifiable {
    public let id: RecordingID
    public let createdAt: Date
    public let duration: TimeInterval
    /// Relative to the capture directory; never a remote URL.
    public let fileName: String
    public let byteCount: Int64

    public init(id: RecordingID, createdAt: Date, duration: TimeInterval,
                fileName: String, byteCount: Int64) {
        self.id = id
        self.createdAt = createdAt
        self.duration = duration
        self.fileName = fileName
        self.byteCount = byteCount
    }
}

public struct TranscriptionJob: Codable, Sendable, Equatable, Identifiable {
    public enum State: Codable, Sendable, Equatable {
        case pendingUpload
        case uploading(attempt: Int)
        case transcribed(text: String)
        case failed(reason: String, attempt: Int)
    }

    public let recording: Recording
    public var state: State
    public var nextAttemptAt: Date?
    public var id: RecordingID { recording.id }
    public var idempotencyKey: String { id.description }

    public init(recording: Recording, state: State = .pendingUpload, nextAttemptAt: Date? = nil) {
        self.recording = recording
        self.state = state
        self.nextAttemptAt = nextAttemptAt
    }
}
