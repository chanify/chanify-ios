# iOS 27 migration

## Build requirements

The deployment targets are iOS 15, macOS 12 and watchOS 9. Simulator validation
used Xcode 27.2 with iOS/watchOS 27.2; this does not establish release readiness.

Open `Chanify.xcworkspace` and select the `iOS` or `Watch` scheme. CocoaPods and
Ruby are no longer required. Dependencies are supplied by the local Swift package
in `Packages/ChanifyDependencies`. See its [README](../Packages/ChanifyDependencies/README.md)
for versions, licenses, source checksums and update instructions.

Protobuf generation requires **protoc 36.2**, matching Objective-C runtime 5.36.2.
Make the compiler available to Xcode through `PATH`, a standard Homebrew location,
or the `PROTOC` build setting. Generated sources belong in DerivedData and must
not be edited or committed.

## Compatibility notes

- iOS uses a single-window Scene lifecycle. Keep window creation and scene events
  in the scene delegate; the router retains its existing window reference.
- Watch account configuration is synchronized after session activation and pairing
  changes. Deletion history survives phone restarts and account changes. Node
  responses must still match the current account and latest configured node set
  before they can update storage.
- The iOS shortcuts widget keeps its iOS 15 compatibility path. The Watch WidgetKit
  extension provides an app launcher, not unread counts or a message timeline.
- Every embedded app and extension must match the main app's marketing/build
  versions and include its own privacy manifest. Review declarations when API or
  data use changes; packaged manifests do not update App Store Connect labels.
- HTTP and LAN access remain supported for self-hosted nodes. Preserve the local
  network usage descriptions and explain the ATS exception in review materials.

## Account deletion requires server deployment

Deploy the `/rest/v1/delete-user` implementations in `ccsrv/` and `server/` before
relying on the client deletion feature. Live deployment and end-to-end deletion
have not been verified.

The client deletes the account from configured non-system nodes first, then the
center service. Requests require an account signature and a nonce within five
minutes. Successful responses must contain HTTP 200, `deleted: true` and the
matching `uid`. The database operations support retries, but deletion across
multiple servers is not atomic: some nodes may already be deleted when a later
request fails. An unsupported endpoint returning 404 is not treated as success.

Until deletion completes, the initiating client keeps the account key and a
persistent pending marker, blocks automatic rebinding, and rejects ordinary
logout so the settings page remains available for retry. Local cleanup includes
account files, shared notification keys (including node keys), timeline and widget
data, delivered notifications and the account key. Keychain failures remain
retryable. The paired Watch applies historical deletions on a later configuration
sync.

Other clients can still automatically register the account again; there is no
server-side permanent revocation protocol. Exported keys, backups and copies on
other devices cannot be remotely erased. Use disposable accounts to validate
partial failures, offline nodes, retries, restarts and multiple devices before
release.

## Verification

Run from the `ios/` repository with the full Xcode developer directory selected:

```sh
python3 Scripts/check-dependencies.py
python3 Scripts/check-release-bundles.py /path/to/Chanify.xcarchive
git diff --check
```

The bundle checker also accepts an `.app`. It checks embedded bundle versions and
privacy manifest presence/basic structure; it does not replace signing validation
or a privacy review.

The LLDB checks below run against a Debug app after startup. Use a fresh process
for runtime mock classes, interrupt before sourcing a script, and follow each
script's comments. Deletion completion checks require resuming the process to let
the main queue drain, then interrupting again to run the final assertion. Resume
or stop the process afterwards.

| Script | Target | Coverage |
| --- | --- | --- |
| [ReviewChecks.lldb](../Tests/iOS/ReviewChecks.lldb) | iOS simulator | Scene window, malformed packets, message IDs, persistence, unread counts, rollback/retry, blocklist and account/node key cleanup |
| [DeletionRegression.lldb](../Tests/iOS/DeletionRegression.lldb) | iOS | Mocked Keychain failures, pending deletion/logout, stale callbacks and invalid responses |
| [WatchDeletionRegression.lldb](../Tests/iOS/WatchDeletionRegression.lldb) | Watch | Isolated historical deletion and invalid path rejection |
| [WatchNodeRegression.lldb](../Tests/iOS/WatchNodeRegression.lldb) | Watch | In-memory node removal, late writes and retained nodes |

For account import smoke testing, use a disposable account QR image through the
normal import flow. Verify login, channel/node loading, one persisted message,
duplicate delivery, read/unread changes and restoration after relaunch. Never
commit account images, private keys or decoded account URLs. Invoking scanner
methods through LLDB does not validate the system photo picker; injecting a
notification locally does not validate APNs or notification extensions.

The server regression commands, run in their respective repositories, are:

```sh
# server/
go test -tags test ./core ./model ./logic
# ccsrv/
go test ./core ./model
```

These Go tests remain unverified because dependency downloads were unavailable
in the validation environment.

## Remaining release checks and known limitations

- Produce a signed Release Archive and run Organizer Validate. Check provisioning,
  APNs/App Groups and the new Watch widget's bundle identifier. Only Debug builds
  and bundle checks have passed; archive validation remains incomplete.
- Test real-device APNs, locked-device file access, notification extensions,
  Watch mirroring/independent delivery, pairing changes and offline recovery.
  Empty notification content is not proof that the system suppresses an alert.
- Test existing-install upgrades, camera/photo permissions, media playback, Duo
  folding/unfolding and all affected layouts, widget appearance/configuration and
  complication selection/launching.
- Verify privacy labels/policy, screenshots, age rating and review instructions,
  including the fixed notification-processing purpose of user scripts.
- Existing Watch limitations remain: changes to an already-bound node's settings
  may not propagate, and re-adding a deleted node may be skipped because its old
  key is retained. These were not expanded into this migration's fixes.
- The macOS application still has unresolved `CHFormOption` and
  `CHScriptViewController` linker errors; dependency checks passing on macOS do not
  establish that the macOS application builds.
