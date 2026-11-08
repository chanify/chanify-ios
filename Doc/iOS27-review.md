# iOS runtime review — 2026-11-08

Scope: iOS startup, lifecycle, notification input, message persistence and unread
counts after the CocoaPods migration and Protobuf upgrade. This is a focused
review of core paths, not a certification of every screen or device combination.

## Findings and fixes

- **P0 — Startup stopped on iOS 27.2.** LLDB stopped in UIKit's
  `UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption` path. Adopted a
  single-window Scene lifecycle, with window creation tied to `UIWindowScene`.
  Process initialization remains in AppDelegate; foreground/background handling,
  URL contexts, web activities, shortcuts and cold-start notification responses
  are handled by the scene delegate. The existing router window reference is
  retained for compatibility.
- **P1 — Messages could be lost on database failure.** Channel/unread writes
  previously ignored failures after the message insert, and inbox draining removed
  entries even when ingestion returned no model. The transaction now checks all
  writes and commit, rolls back on failure, and reports failure to the caller.
  Pending entries are removed only after successful persistence or an intentional
  blocklist discard. Foreground deliveries that fail ingestion are retained too.
- **P1 — First-message unread counts were doubled.** Channel creation initialized
  unread to one, then the same delivery incremented it again. Creation starts at
  zero and only a newly inserted, alerting message in an unread channel adds one.
- **P1 — Malformed notification input could cause selector exceptions.** Added
  dictionary/string validation and clear output parameters on rejected packets.
  Invalid protobuf message content now rejects the model instead of returning a
  partially initialized object. Notification responses for a different account,
  and dismissal responses, no longer navigate the current account's UI.
- **P1 — Simulator notifications could fail before login/key synchronization.**
  Added account/key-length checks before slicing the encryption key, validated
  mock fields, and preserved production-format packets without rewriting them.
- **P2 — Simulator message ID construction was incorrect.** Converted timeval
  microseconds to integer nanoseconds, corrected the fourth nonce header byte,
  and used memcpy for unaligned message-ID fields.

## Validation

- Xcode 27.2, iOS scheme, iPhone 17 simulator (iOS 27.2): build passed; process
  remained running after launch; the router window had a scene and root controller.
- `Tests/iOS/ReviewChecks.lldb`: passed checks for the scene window, malformed
  packet rejection, simulator packet handling, timestamp units, unread counts
  (first 1 / duplicate 1 / second 2), active-channel unread zero, SQL-trigger-induced
  rollback, successful retry and blocklist discard. SQLite temporary databases and
  synthetic encryption keys isolate these checks from the current account.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer python3 Scripts/check-dependencies.py`:
  passed, including Protobuf wire-format compatibility and malformed-input errors.
- `git diff --check`: passed.

To repeat the simulator checks, launch the iOS Debug scheme with LLDB attached,
interrupt the process, then run `command source <repo>/Tests/iOS/ReviewChecks.lldb`
in the Xcode debug console. Resume or stop the process afterwards. The simulator
helper checks are not intended for a physical-device build.

## Remaining verification

Real-device APNs registration and encrypted delivery, locked-device notification
service/content extensions, account login and existing-install database upgrades,
camera/photo permission flows, audio playback and widget refresh still require
end-to-end verification. Simulator startup also emitted file-protection resource
errors; actual lock/unlock file access needs a physical device. The macOS link
errors recorded in the dependency README remain outside this iOS-focused review.
