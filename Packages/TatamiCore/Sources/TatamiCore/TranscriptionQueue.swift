import Foundation

public actor TranscriptionQueue {
    private let store: any JobStore
    private let transcriber: any Transcribing
    private let clock: any Clock
    private let baseDelay: TimeInterval
    private let maximumDelay: TimeInterval
    private var isProcessing = false

    public init(store: any JobStore, transcriber: any Transcribing,
                clock: any Clock = SystemClock(), baseDelay: TimeInterval = 2,
                maximumDelay: TimeInterval = 300) {
        self.store = store
        self.transcriber = transcriber
        self.clock = clock
        self.baseDelay = max(1, baseDelay)
        self.maximumDelay = max(1, maximumDelay)
    }

    @discardableResult
    public func enqueue(_ recording: Recording) async throws -> TranscriptionJob {
        // No network work is allowed until this durable insert succeeds.
        try await store.insertIfAbsent(TranscriptionJob(recording: recording))
    }

    /// One pass over eligible jobs in capture order. The caller schedules later passes.
    /// Interrupted uploads are retried with the same idempotency key after process restart.
    public func processPending() async throws {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        let jobs = try await store.allJobs().sorted {
            if $0.recording.createdAt == $1.recording.createdAt {
                return $0.id.description < $1.id.description
            }
            return $0.recording.createdAt < $1.recording.createdAt
        }
        for var job in jobs {
            try Task.checkCancellation()
            let previousAttempt: Int
            switch job.state {
            case .transcribed: continue
            case .pendingUpload: previousAttempt = 0
            case .uploading(let attempt), .failed(_, let attempt): previousAttempt = attempt
            }
            if let deadline = job.nextAttemptAt, deadline > clock.now() { continue }
            let attempt = previousAttempt < Int.max ? previousAttempt + 1 : Int.max
            job.state = .uploading(attempt: attempt)
            job.nextAttemptAt = nil
            try await store.update(job)

            let text: String
            do {
                text = try await transcriber.transcribe(job.recording, idempotencyKey: job.idempotencyKey)
            } catch {
                // Store categories only; arbitrary errors may contain URLs, credentials or text.
                let category = error is CancellationError ? "cancelled" : "transcription"
                job.state = .failed(reason: category, attempt: attempt)
                let exponent = min(attempt - 1, 30)
                let delay = min(maximumDelay, baseDelay * pow(2.0, Double(exponent)))
                job.nextAttemptAt = clock.now().addingTimeInterval(delay)
                try await store.update(job)
                if error is CancellationError { throw CancellationError() }
                continue
            }
            job.state = .transcribed(text: text)
            // If this write fails, retain the durable uploading job and retry idempotently.
            try await store.update(job)
        }
    }
}
