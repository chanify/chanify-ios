import Foundation

// Transport/account substitutes only; the view model is compiled unchanged.
enum CHWatchConfigurationStatus { case waiting, received, failed }
final class CHUserModel {
    let uid: String
    init(_ uid: String) { self.uid = uid }
}
struct CHNodeModel {
    let nid: String, name: String, version: String, endpoint: String
    let icon: String?
}
final class CHMessageModel {
    let mid: String
    var title: String? = "Synthetic title"
    init(_ mid: String) { self.mid = mid }
    func summaryBodyText() -> String { "Synthetic summary" }
}
final class CHUserDataSource {
    struct Request {
        let cursor: String?
        let count: Int
        let completion: ([CHMessageModel], String?, Bool, Error?) -> Void
    }
    var requests: [Request] = []
    func loadWatchMessages(beforeMID: String?, count: Int, completion: @escaping ([CHMessageModel], String?, Bool, Error?) -> Void) {
        requests.append(Request(cursor: beforeMID, count: count, completion: completion))
    }
    func message(withMID mid: String) -> CHMessageModel? { nil }
    func loadNodes() -> [CHNodeModel] { [] }
}
final class CHLogic {
    static let shared = CHLogic()
    var me: CHUserModel?
    var userDataSource: CHUserDataSource?
    var configurationStatus: CHWatchConfigurationStatus = .received
    var lastConfigurationDate: Date?
    var processingInbox = false
    var inboxHasPendingMessages = false
    var pendingMessageID: String?
    func refreshWatchMessages() { processingInbox = true }
    func consumePendingMessageID(_ mid: String) { if pendingMessageID == mid { pendingMessageID = nil } }
}
