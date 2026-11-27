import Foundation

public enum FakeError: Error, Sendable { case notRecording, alreadyRecording, unavailable }

/// Demo only: writes a tiny silent WAV, never accesses a microphone.
public actor FakeAudioCapture: AudioCapturing {
    private let directory: URL
    private let clock: any Clock
    private let ids: any IDGenerating
    private var startedAt: Date?

    public init(directory: URL, clock: any Clock = SystemClock(), ids: any IDGenerating = UUIDGenerator()) {
        self.directory = directory
        self.clock = clock
        self.ids = ids
    }

    public func requestPermission() -> Bool { true }
    public func start() throws {
        guard startedAt == nil else { throw FakeError.alreadyRecording }
        startedAt = clock.now()
    }

    public func stop() throws -> Recording {
        guard let start = startedAt else { throw FakeError.notRecording }
        let id = ids.next()
        let fileName = "\(id.description).wav"
        // PCM mono, 8 kHz, 16 bit, one silent sample (46 bytes total).
        let bytes: [UInt8] = [
            82,73,70,70,38,0,0,0,87,65,86,69,102,109,116,32,
            16,0,0,0,1,0,1,0,64,31,0,0,128,62,0,0,2,0,16,0,
            100,97,116,97,2,0,0,0,0,0
        ]
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(bytes).write(to: directory.appendingPathComponent(fileName), options: .atomic)
        startedAt = nil
        return Recording(id: id, createdAt: start, duration: max(0, clock.now().timeIntervalSince(start)),
                         fileName: fileName, byteCount: Int64(bytes.count))
    }
}

public actor FakeTranscriber: Transcribing {
    private var failuresRemaining: Int
    private let text: String
    public init(failuresBeforeSuccess: Int = 0, text: String = "Демонстрационная расшифровка Tatami.") {
        self.failuresRemaining = max(0, failuresBeforeSuccess)
        self.text = text
    }
    public func transcribe(_ recording: Recording, idempotencyKey: String) throws -> String {
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw FakeError.unavailable
        }
        return text
    }
}
