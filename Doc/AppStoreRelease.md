# App Store release: 1.4.13 (77)

## Release notes — 简体中文

- 新增消息搜索，支持关键词高亮、分页与跳转到消息上下文。
- Apple Watch 新增最近消息、文本摘要详情与本地历史分页，改善通知定位和同步状态。
- 自建服务器支持发送令牌的创建、列表、改名、复制及吊销；需要节点声明相应能力。
- 修复迟到消息的列表显示与频道摘要刷新，改善未读角标同步。
- 改善 Watch 账户密钥同步重试，以及缺少节点密钥时的消息保留和恢复。

## What's New — English

- Search messages with highlighted matches, pagination, and navigation to their context.
- Browse recent messages and text summaries on Apple Watch, with local history pagination and improved notification navigation and sync status.
- Create, list, rename, copy, and revoke sending tokens on supported self-hosted servers.
- Fix late-arriving message display and channel previews, and improve unread badge updates.
- Improve Watch account-key sync retries and message recovery while node keys are unavailable.

## Scope and release gate

These are draft App Store Connect notes for 1.4.13 (77), not a record of approval or production deployment.
Historical search backfill is disabled by default, so older messages may not appear in search.
Watch shows text summaries (up to 2048 characters); it does not download attachments,
execute actions, or open message links. Server-wide sending tokens require a stateful
self-hosted node advertising `auth.server-token`; the official service and legacy nodes
keep their existing channel-token flow.

Before submission, complete a signed Release Archive, packaged bundle checks,
Organizer Validate, and TestFlight acceptance on physical devices. Record production
APNs, paired Watch, iOS 15, iPad, and upgrade results separately from simulator tests.
Generation fixes a server token's expiry at the first attempt; retry uses the same token
and expiry so a lost response cannot silently create another credential. To choose a
different expiry, finish/reconcile the existing attempt in the token list first.

## Build and package

Open `Chanify.xcworkspace`, select the shared Chanify-iOS scheme, and use a physical iOS device
or Any iOS Device for a Release Archive. Sign the app and every embedded
extension, including WatchWidgetsExtension, with the correct developer team.
The local machine needs the developer account and provisioning profiles;
simulator builds do not validate distribution signing or production APNs.

After changing `../web/privacy.md`, regenerate the bundled policy:

```sh
python3 Scripts/sync-privacy-policy.py
python3 Scripts/sync-privacy-policy.py --check
python3 Scripts/check-release-bundles.py /path/to/Chanify.xcarchive
```

The bundle check verifies matching versions, privacy manifests, and the offline
policy. Also run Validate App in Xcode Organizer. Verify distribution entitlements
include production APNs, the configured App Groups, and Keychain access groups.
Do not change the source development APNs entitlement to work around signing:
Xcode's distribution export applies the provisioning profile's entitlement.

## Privacy and App Store Connect

- Publish `../web/privacy.md` at https://www.chanify.net/privacy.html and verify it
  loads publicly. Updating the repository or bundling a copy does not publish it.
- Confirm the App Store Connect privacy answers against the deployed services.
  The app declares account and device identifiers linked to the user, for app
  functionality, without tracking. Account/device names, access-log metadata,
  message or attachment retention, and third-party hosting must also be considered
  according to the actual service operation and Apple's data-type definitions.
- Official access logs contain no message content, expire within 7 days, and
  there are no server-side backups (confirmed by the service operator). Keep the
  deployed logging configuration consistent with these statements. Self-hosted
  operators' policies can differ.
- Review export compliance for the complete app. The existing exemption flag is
  retained: cryptography uses Apple's Security and CryptoKit APIs. Do not assert
  that the app uses no encryption. Confirm the exemption answers with Apple's
  questionnaire before uploading; API usage alone is not a legal classification.
- Complete screenshots, support/privacy URLs, age-rating questions, review contact,
  version description, and required account/business declarations in App Store
  Connect. Use screenshots of this release on the supported device sizes.

Apple references:
https://developer.apple.com/app-store/app-privacy-details/
https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/

## TestFlight acceptance

- Create/import an account; update an existing installation with stored messages.
- Allow and deny notifications, camera, photos, and local-network access. Verify
  retrying after changing permission in Settings.
- Send a production push while foregrounded, backgrounded, and locked. Check text,
  image, file, audio, and notification actions that the selected server supports.
- Check widgets and paired Watch delivery; play an audio message in the background.
- Open Privacy Policy before login and from Settings. Test normal loading,
  offline loading, and an HTTP failure; the bundled policy should remain readable.
- Use a disposable account for deletion: verify center and configured nodes remove
  registrations, local messages/keys/files are removed, and Watch cleanup happens
  when it reconnects. Test a temporarily unavailable node and retry after recovery.
  Each deployed server must support `delete-user`. Do not test with a real account.

## Review notes (English)

Chanify lets a user send notifications to their own devices through an HTTP API.
Create a new account in the app, open a channel, and copy its sender token. Send a
test notification using the command below with that token. An external login
credential is not required for this flow. Keep the official service available
throughout review.

```sh
curl --form-string 'text=App Review test' \
  'https://api.chanify.net/v1/sender/<CHANNEL_TOKEN>'
```

The app also supports user-configured self-hosted servers. The HTTP transport
exception provides compatibility with those servers, including local-network
servers. The official API uses HTTPS. Background audio is used to continue
playing audio messages the user starts. Privacy Policy is available before login
and in Settings, with a bundled fallback if the website is unavailable. Permanent
account deletion is available in Settings; logging out is a separate action.

Replace the sample token only when testing. Do not commit real tokens or account
QR codes. If extra server configuration is needed for a review scenario, provide
the exact steps and temporary credentials privately in App Store Connect.
