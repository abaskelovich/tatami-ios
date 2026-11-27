# BACKLOG — Tatami iOS

- [x] Minimum iOS version (18.0) and signing strategy (unsigned CI + Sideloadly; paid program deferred).
- [x] Capture/history shell with fakes, unsigned GitHub Actions CI.
- [ ] First sideload on iPhone 14 Plus and launch check.
- [ ] Slice 2: real `AVAudioSession`/`AVAudioEngine` capture to a durable file, interruptions, orphan-file recovery.
- [ ] Slice 3: auth (Google Sign-In for iOS needs an iOS OAuth client and server audience) and batch `/transcribe` from `packages/api-contracts`.
- [ ] Keyboard extension that inserts ready results (no microphone).
- [ ] Apple Developer Program + TestFlight workflow — only once the app has proven itself.
