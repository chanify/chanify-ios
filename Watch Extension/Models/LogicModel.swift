//
//  LogicModel.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/20.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

struct NodeModel: Identifiable {
    var id: String
    let name: String
    let icon: String?
    let version: String
    let endpoint: String
}

struct WatchMessage: Identifiable {
    let id: String
    let title: String
    let summary: String
    let date: Date?
    let truncated: Bool

    init(_ message: CHMessageModel) {
        id = message.mid
        title = String((message.title ?? "").prefix(120))
        let text = String(message.summaryBodyText().prefix(2049))
        truncated = text.count > 2048
        summary = String(text.prefix(2048))
        if let timestamp = UInt64(String(message.mid.prefix(16)), radix: 16), timestamp > 0 {
            date = Date(timeIntervalSince1970: Double(timestamp) / 1_000_000_000)
        } else {
            date = nil
        }
    }
#if DEBUG
    init(previewID: String, title: String, summary: String, date: Date) {
        id = previewID
        self.title = title
        self.summary = summary
        self.date = date
        truncated = false
    }
#endif

}

struct WatchMessageRoute: Identifiable {
    let id = UUID()
    let messageID: String
    let accountID: String
}

final class LogicModel: ObservableObject {
    @Published var me: CHUserModel?
    @Published var nodes: [NodeModel] = []
    @Published var configurationStatus: CHWatchConfigurationStatus = .waiting
    @Published var lastConfigurationDate: Date?
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined

    @Published var messages: [WatchMessage] = []
    @Published var loadingMessages = false
    @Published var messageLoadFailed = false
    @Published var hasMoreMessages = false
    @Published var inboxProcessing = false
    @Published var inboxHasPendingMessages = false
    @Published var messageRoute: WatchMessageRoute?
    @Published var messageUpdatesAvailable = false
    private var browsingHistory = false
    private var messageQueryID = UUID()
    private var messageCursor: String?
    private weak var messageDataSource: CHUserDataSource?

    func updateAccount(_ account: CHUserModel?) {
        if me?.uid != account?.uid {
            messageQueryID = UUID()
            messages = []
            messageCursor = nil
            messageDataSource = nil
            hasMoreMessages = false
            loadingMessages = false
            messageLoadFailed = false
            messageRoute = nil
            messageUpdatesAvailable = false
            browsingHistory = false
        }
        me = account
        refreshMessageState()
    }

    func refreshMessageState(markUpdates: Bool = false) {
        inboxProcessing = CHLogic.shared.processingInbox
        inboxHasPendingMessages = CHLogic.shared.inboxHasPendingMessages
        if !inboxProcessing {
            if messageDataSource !== CHLogic.shared.userDataSource {
                messageQueryID = UUID()
                loadingMessages = false
                reloadMessages()
            } else if browsingHistory || loadingMessages {
                // Preserve the visible history and any page request already in flight.
                if markUpdates { messageUpdatesAvailable = true }
            } else {
                reloadMessages()
            }
        }
        if let mid = CHLogic.shared.pendingMessageID { openMessage(mid) }
    }

    func requestMessageRefresh() {
        browsingHistory = false
        messageUpdatesAvailable = false
        messageQueryID = UUID()
        loadingMessages = false
        messageLoadFailed = false
        CHLogic.shared.refreshWatchMessages()
        refreshMessageState()
    }

    func reloadMessages() {
        browsingHistory = false
        messageUpdatesAvailable = false
        loadMessagePage(reset: true)
    }

    func loadMoreMessages() {
        guard !loadingMessages, hasMoreMessages else { return }
        browsingHistory = true
        loadMessagePage(reset: false)
    }

    private func loadMessagePage(reset: Bool) {
        guard let uid = me?.uid, uid == CHLogic.shared.me?.uid,
              let dataSource = CHLogic.shared.userDataSource else { return }
        let query = UUID()
        messageDataSource = dataSource
        messageQueryID = query
        loadingMessages = true
        messageLoadFailed = false
        dataSource.loadWatchMessages(beforeMID: reset ? nil : messageCursor, count: 20) { [weak self] page, cursor, hasMore, error in
            guard let self = self, self.messageQueryID == query,
                  self.me?.uid == uid, CHLogic.shared.me?.uid == uid,
                  CHLogic.shared.userDataSource === dataSource else { return }
            self.loadingMessages = false
            if error != nil {
                self.messageLoadFailed = true
                return
            }
            let snapshots = page.map(WatchMessage.init)
            if reset {
                self.messages = snapshots
            } else {
                let existing = Set(self.messages.map(\.id))
                self.messages.append(contentsOf: snapshots.filter { !existing.contains($0.id) })
            }
            self.messageCursor = cursor
            self.hasMoreMessages = hasMore && cursor != nil
        }
    }

    func openMessage(_ mid: String) {
        guard let uid = me?.uid, CHLogic.shared.me?.uid == uid else { return }
        if messageRoute?.messageID != mid {
            messageRoute = WatchMessageRoute(messageID: mid, accountID: uid)
        }
        CHLogic.shared.consumePendingMessageID(mid)
    }

    func messageSnapshot(_ mid: String, accountID: String) -> WatchMessage? {
        guard me?.uid == accountID, CHLogic.shared.me?.uid == accountID,
              let message = CHLogic.shared.userDataSource?.message(withMID: mid) else { return nil }
        return WatchMessage(message)
    }

    init() {
        me = CHLogic.shared.me
        nodes = Self.loadNodes()
        configurationStatus = CHLogic.shared.configurationStatus
        lastConfigurationDate = CHLogic.shared.lastConfigurationDate
    }

#if DEBUG
    // Layout previews contain only synthetic summaries and never open an account.
    init(previewMessages: [WatchMessage]) {
        messages = previewMessages
        notificationStatus = .authorized
        configurationStatus = .received
    }
#endif

    var configurationStatusTitle: LocalizedStringKey {
        switch configurationStatus {
        case .received: return "ConfigurationReceived"
        case .failed: return "ConfigurationFailedShort"
        default: return "WaitingForConfiguration"
        }
    }

    func refreshStatus() {
        configurationStatus = CHLogic.shared.configurationStatus
        lastConfigurationDate = CHLogic.shared.lastConfigurationDate
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }

    static func loadNodes() ->[NodeModel] {
        var nodes = [NodeModel]()
        if let ds = CHLogic.shared.userDataSource {
            for model in ds.loadNodes() {
                nodes.append(NodeModel(id: model.nid, name: model.name, icon: model.icon, version: model.version, endpoint: model.endpoint))
            }
        }
        return nodes;
    }
}
