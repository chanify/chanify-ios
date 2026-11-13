import Foundation

func check(_ value: @autoclosure () -> Bool, _ message: String) {
    guard value() else { fatalError("FAIL: \(message)") }
}
func mid(_ value: Int) -> String { String(format: "%016llx", value) }
func messages(_ newest: Int, _ oldest: Int) -> [CHMessageModel] {
    stride(from: newest, through: oldest, by: -1).map { CHMessageModel(mid($0)) }
}

let logic = CHLogic.shared
let account = CHUserModel("synthetic-a")
let store = CHUserDataSource()
logic.me = account
logic.userDataSource = store
let model = LogicModel()
model.refreshMessageState()
check(store.requests.count == 1 && store.requests[0].cursor == nil, "initial page starts")
model.refreshMessageState()
check(store.requests.count == 1 && !model.messageUpdatesAvailable, "duplicate appearance does not replace a pending page or show a false update hint")
store.requests[0].completion(messages(100, 81), mid(81), true, nil)
check(model.messages.count == 20 && !model.loadingMessages, "initial page completes")
model.loadMoreMessages()
check(store.requests.count == 2 && store.requests[1].cursor == mid(81), "older page uses tail cursor")
model.refreshMessageState(markUpdates: true)
check(store.requests.count == 2 && model.messages.count == 20 && model.messageUpdatesAvailable, "automatic update preserves in-flight history paging")
store.requests[1].completion(messages(80, 61), mid(61), true, nil)
check(model.messages.map(\.id) == messages(100, 61).map(\.mid), "history page is appended despite an automatic update")
model.refreshMessageState(markUpdates: true)
check(store.requests.count == 2 && model.messages.count == 40, "automatic update preserves all loaded pages")
model.loadMoreMessages()
check(store.requests[2].cursor == mid(61), "automatic update preserves tail cursor")
store.requests[2].completion([], nil, false, NSError(domain: "synthetic", code: 1))
check(model.messages.count == 40 && model.messageLoadFailed && model.hasMoreMessages, "failed older page preserves history and retry position")
model.loadMoreMessages()
check(store.requests[3].cursor == mid(61), "retry uses the same history cursor")
store.requests[3].completion(messages(60, 41), mid(41), true, nil)
check(model.messages.count == 60 && !model.messageLoadFailed, "history retry succeeds")
model.loadMoreMessages()
check(store.requests[4].cursor == mid(41), "next older page starts")
model.requestMessageRefresh()
check(model.messages.count == 60 && model.inboxProcessing && !model.messageUpdatesAvailable && store.requests.count == 5, "explicit refresh waits for inbox completion and retains cached display")
store.requests[4].completion(messages(40, 21), mid(21), true, nil)
check(model.messages.count == 60, "late older page cannot override explicit refresh")
logic.processingInbox = false
model.refreshMessageState(markUpdates: true)
check(store.requests.count == 6 && store.requests[5].cursor == nil, "explicit refresh starts a fresh page after inbox completion")
store.requests[5].completion(messages(105, 86), mid(86), true, nil)
check(model.messages.map(\.id) == messages(105, 86).map(\.mid), "only explicit refresh resets the history window")
print("PASS: production Watch model preserves loaded history, pending paging and cursor; explicit refresh and retries remain correct")

model.reloadMessages()
let staleRequest = store.requests.last!
let replacement = CHUserDataSource()
logic.userDataSource = replacement
model.refreshMessageState()
check(replacement.requests.count == 1 && model.loadingMessages, "same-account storage replacement replaces a pending query")
staleRequest.completion(messages(999, 980), mid(980), true, nil)
check(model.messages.first?.id == mid(105) && model.loadingMessages, "stale storage cannot replace visible content or complete the new query")
replacement.requests[0].completion(messages(200, 181), mid(181), true, nil)
check(model.messages.first?.id == mid(200) && !model.loadingMessages, "replacement storage completes normally")
model.loadMoreMessages()
replacement.requests.last!.completion([], nil, false, NSError(domain: "synthetic", code: 2))
check(model.messageLoadFailed, "history read failure is visible")
model.requestMessageRefresh()
check(!model.messageLoadFailed && model.inboxProcessing, "explicit refresh clears a previous read error before inbox processing")
logic.processingInbox = false
model.refreshMessageState(markUpdates: true)
let oldAccountRequest = replacement.requests.last!
let otherAccount = CHUserModel("synthetic-b")
let otherStore = CHUserDataSource()
logic.me = otherAccount
logic.userDataSource = otherStore
model.updateAccount(otherAccount)
check(model.messages.isEmpty && !model.messageUpdatesAvailable && otherStore.requests.count == 1, "account change resets window and update state")
oldAccountRequest.completion(messages(180, 161), mid(161), true, nil)
check(model.messages.isEmpty, "old account page is rejected")
otherStore.requests[0].completion(messages(20, 1), mid(1), true, nil)
model.loadMoreMessages()
let logoutRequest = otherStore.requests.last!
logic.me = nil
logic.userDataSource = nil
model.updateAccount(nil)
logoutRequest.completion(messages(200, 181), mid(181), true, nil)
check(model.messages.isEmpty && !model.loadingMessages && !model.hasMoreMessages && !model.messageUpdatesAvailable, "logout cancels paging and clears all view state")
print("PASS: production Watch model rejects stale storage/account callbacks and resets correctly on account changes and logout")
