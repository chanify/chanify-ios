# Account import smoke check — 2026-11-08

Environment: Xcode 27.2, iPhone 17 simulator, iOS 27.2.

Input: `../doc/test_account.png` from the workspace root's `doc` directory.
The account image, decoded QR URL and private key were not copied into this
repository or printed in the results. The debugger transferred the image directly
into simulator memory.

## Passed

- Invoked the login screen's Import Account action and supplied the image to the
  existing scanner's `scanImage:` method. The scanner's normal QR decoding and
  login delegate callback performed the import.
- The backend returned account binding success. The app entered
  `CHTabBarViewController`, and the imported account matched the image's account.
- The account's message key and local database were ready. Initially there were
  three channels, one node and zero unread messages.
- Injected a local simulator notification containing `Codex iOS import smoke check`
  in the `Codex smoke test` channel through the existing mock/encrypted-message
  receiver path. The message decrypted and persisted successfully.
- Replayed the same packet: unread increased once, and the database retained one
  copy of the message.
- Opened the channel through the app router: `CHChannelViewController` loaded its
  collection view, and unread returned to zero.
- Loaded the Channels, Nodes and Settings view controllers without a runtime stop.
- Stopped and relaunched the app: login and message key were restored, the main
  tabs loaded, and exactly one copy of the test message persisted.

The imported account and the local test channel/message remain in the simulator.
No account logout or deletion was performed.

## Coverage limits

The automatic device interaction channel was unavailable. This check invoked
application actions via LLDB; it did not exercise the system photo picker or
perform visual/pixel-level assertions. QR decoding ran in the app's normal main
queue to avoid LLDB intercepting the decoder's internally handled C++ exceptions.
The injected notification bypassed APNs and the system notification service/content
extensions; physical-device delivery, lock-screen behavior and media permissions
remain separate verification steps. No production source changes were needed for
this smoke check.
