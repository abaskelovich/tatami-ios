import Foundation
import SwiftUI
import TatamiCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var machine = RecordingStateMachine()
    @Published private(set) var jobs: [TranscriptionJob] = []
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var lastErrorCategory: String?
    @Published private(set) var sceneDescription = "неизвестно"
    @Published private(set) var isReady = false

    private let audio: any AudioCapturing
    private let store: any JobStore
    private let queue: TranscriptionQueue
    private var startedAt: Date?
    private var pendingRecording: Recording?
    private var needsFinalization = false
    private var isActive = false

    init(directory: URL = URL.applicationSupportDirectory.appendingPathComponent("Tatami", isDirectory: true)) {
        let store = FileJobStore(fileURL: directory.appendingPathComponent("jobs.json"))
        self.store = store
        audio = FakeAudioCapture(directory: directory.appendingPathComponent("Recordings", isDirectory: true))
        queue = TranscriptionQueue(store: store, transcriber: FakeTranscriber())
    }

    var stateText: String {
        switch machine.state {
        case .idle: return "Готово к записи"
        case .requestingPermission: return "Подготовка записи"
        case .recording: return "Идёт демонстрационная запись"
        case .finalizing: return "Сохранение на устройстве"
        case .saved: return "Сохранено в очереди"
        case .failed: return "Не удалось завершить действие"
        }
    }

    var recordButtonTitle: String {
        if pendingRecording != nil || needsFinalization { return "Повторить сохранение" }
        return machine.state == .recording ? "Остановить" : "Записать"
    }

    var canToggle: Bool {
        guard isReady else { return false }
        switch machine.state {
        case .requestingPermission, .finalizing: return false
        default: return true
        }
    }

    func setScenePhase(_ phase: ScenePhase) {
        isActive = phase == .active
        switch phase {
        case .active: sceneDescription = "активно"
        case .inactive: sceneDescription = "неактивно"
        case .background: sceneDescription = "в фоне"
        @unknown default: sceneDescription = "неизвестно"
        }
    }

    func run() async {
        // A corrupt/unreadable store disables new captures rather than hiding existing data.
        do {
            try await refreshJobs()
            isReady = true
        } catch {
            lastErrorCategory = "storage"
            return
        }
        while !Task.isCancelled {
            if let start = startedAt { elapsed = max(0, Date().timeIntervalSince(start)) }
            if isActive {
                do {
                    try await queue.processPending()
                    try await refreshJobs()
                } catch is CancellationError {
                    return
                } catch {
                    lastErrorCategory = "storage"
                }
            }
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
        }
    }

    func toggleRecording() async {
        guard canToggle else { return }
        if pendingRecording != nil || needsFinalization {
            machine.send(.retryFinalization)
            await finalize()
            return
        }
        if machine.state == .recording {
            machine.send(.stop)
            await finalize()
            return
        }
        if machine.state != .idle { machine.send(.reset) }
        machine.send(.requestPermission)
        guard await audio.requestPermission() else {
            lastErrorCategory = "permission"
            machine.send(.fail(reason: "permission"))
            return
        }
        do {
            try await audio.start()
            startedAt = Date()
            elapsed = 0
            lastErrorCategory = nil
            machine.send(.permissionGranted)
        } catch {
            lastErrorCategory = "capture"
            machine.send(.fail(reason: "capture"))
        }
    }

    private func finalize() async {
        needsFinalization = true
        do {
            if pendingRecording == nil { pendingRecording = try await audio.stop() }
            startedAt = nil
            if let item = pendingRecording {
                elapsed = item.duration
                try await queue.enqueue(item)
            }
            // Clear the recovery reference only after the durable store accepted the job.
            pendingRecording = nil
            needsFinalization = false
            machine.send(.save)
            lastErrorCategory = nil
            try await refreshJobs()
        } catch {
            lastErrorCategory = "storage"
            if machine.state == .finalizing { machine.send(.fail(reason: "storage")) }
        }
    }

    private func refreshJobs() async throws {
        jobs = try await store.allJobs().sorted { $0.recording.createdAt > $1.recording.createdAt }
        if jobs.contains(where: { if case .failed = $0.state { return true }; return false }) {
            lastErrorCategory = "transcription"
        }
    }

    func count(_ category: JobCategory) -> Int {
        jobs.filter { JobCategory(state: $0.state) == category }.count
    }
}

enum JobCategory: String, CaseIterable {
    case pending = "В очереди", uploading = "Отправка", transcribed = "Готово", failed = "Повтор позже"

    init(state: TranscriptionJob.State) {
        switch state {
        case .pendingUpload: self = .pending
        case .uploading: self = .uploading
        case .transcribed: self = .transcribed
        case .failed: self = .failed
        }
    }
}
