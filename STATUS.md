---
schema_version: 1
project: "Tatami iOS"
session:
  id: "2026-11-27-ios-bootstrap"
  status: open
  opened_at: "2026-11-27T22:00:00+02:00"
  owner: claude
  stage: SLICE1_CI_GREEN
  goal: "Bootstrap the iOS client without a Mac: GitHub Actions build/test, unsigned IPA sideloaded to iPhone 14 Plus (iOS 18.6)"
  next_action: "Owner sideloads the Tatami-unsigned artifact with Sideloadly (docs/device-testing.md); then slice 2: real AVAudioEngine capture to durable file"
workspace:
  branch: "ios/bootstrap (monorepo worktree Tatami-iOS-Bootstrap); pushed via git subtree to github.com/abaskelovich/tatami-ios main"
  base_commit: "8276469"
  dirty: false
release:
  target: null
  readiness: unsigned-ci-only
blockers: []
manual_actions:
  - "Apple Developer Program intentionally deferred until the app proves itself; device builds use free Apple ID + Sideloadly (7-day expiry, no entitlements)."
---

# Current status

Last updated: 2026-11-27

- Canonical task `Tatami-iOS` created with owner authorization (root AGENTS).
- Slice 1 done and CI-verified (run 46064126253, Xcode 26.6): `TatamiCore`
  Swift package (19 tests, Linux), XcodeGen `project.yml`, Russian SwiftUI
  shell with fake capture/transcriber, unit + UI smoke test, unsigned
  `Tatami-unsigned.ipa` artifact.
- Not yet verified on the iPhone.
- Decisions: iOS 18.0 deployment target, iPhone only, Swift 5 mode,
  bundle id `com.tatami.assistant`, no third-party dependencies, keyboard
  extension later and without microphone.
