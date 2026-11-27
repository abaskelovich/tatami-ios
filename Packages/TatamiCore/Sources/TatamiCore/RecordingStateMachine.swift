import Foundation

public struct RecordingStateMachine: Sendable {
    public enum State: Codable, Sendable, Equatable {
        case idle, requestingPermission, recording, finalizing
        case saved
        case failed(reason: String)
    }

    public enum Event: Sendable, Equatable {
        case requestPermission, permissionGranted, stop, save, reset, retryFinalization
        case fail(reason: String)
    }

    public struct InvalidTransition: Error, Sendable, Equatable {
        public let state: State
        public let event: Event
    }

    public private(set) var state: State = .idle
    public init() {}

    @discardableResult
    public mutating func send(_ event: Event) -> Result<State, InvalidTransition> {
        let next: State
        switch (state, event) {
        case (.idle, .requestPermission): next = .requestingPermission
        case (.requestingPermission, .permissionGranted): next = .recording
        case (.recording, .stop): next = .finalizing
        case (.finalizing, .save): next = .saved
        case (.failed, .retryFinalization): next = .finalizing
        case (.requestingPermission, .fail(let reason)),
             (.recording, .fail(let reason)),
             (.finalizing, .fail(let reason)):
            next = .failed(reason: reason)
        case (.saved, .reset), (.failed, .reset): next = .idle
        default: return .failure(InvalidTransition(state: state, event: event))
        }
        state = next
        return .success(next)
    }
}
