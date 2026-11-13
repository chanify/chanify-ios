//
//  ContentView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI
import UserNotifications
import WatchKit

struct ContentView: View {
    @EnvironmentObject private var model: LogicModel

    var body: some View {
        List {
            Section {
                if model.loadingMessages && model.messages.isEmpty {
                    ProgressView()
                }
                if model.inboxProcessing {
                    Label("ReceivingMessages", systemImage: "arrow.triangle.2.circlepath")
                        .font(.footnote)
                }
                if model.messages.isEmpty && !model.loadingMessages && !model.inboxProcessing && !model.messageLoadFailed && !model.hasMoreMessages {
                    Text("NoRecentMessages").foregroundColor(.secondary)
                }
                ForEach(model.messages) { message in
                    NavigationLink(destination: WatchMessageDetailView(messageID: message.id, accountID: model.me?.uid ?? "")) {
                        WatchMessageRow(message: message)
                    }
                }
                if model.messageUpdatesAvailable {
                    Text("MessagesUpdatedHint").font(.footnote).foregroundColor(.secondary)
                }
                if model.messageLoadFailed {
                    Text("MessageLoadFailed").font(.footnote)
                }
                if model.inboxHasPendingMessages {
                    Text("MessagesPendingHint").font(.footnote).foregroundColor(.secondary)
                }
                if model.hasMoreMessages {
                    Button("LoadMoreMessages") { model.loadMoreMessages() }
                        .disabled(model.loadingMessages)
                }
                Button("RefreshMessages") { model.requestMessageRefresh() }
                    .disabled(model.inboxProcessing || model.loadingMessages)
            } footer: {
                Text("WatchMessagesScope").font(.footnote)
            }
            Section {
                NavigationLink("Nodes") { WatchNodesView() }
                NavigationLink(destination: ScrollView {
                    WatchStatusView().padding()
                }.navigationTitle(Text("WatchStatus"))) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WatchStatus")
                        Text(model.configurationStatusTitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(Text("RecentMessages"))
        .sheet(item: $model.messageRoute) { route in
            NavigationView {
                WatchMessageDetailView(messageID: route.messageID, accountID: route.accountID)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { model.messageRoute = nil }
                        }
                    }
            }.environmentObject(model)
        }
    }
}

struct WatchNodesView: View {
    @EnvironmentObject private var model: LogicModel

    var body: some View {
        List {
            if model.nodes.isEmpty {
                Text("NoNodesHint").font(.footnote).foregroundColor(.secondary)
            }
            ForEach(model.nodes) { node in
                NavigationLink(destination: NodeDetailView(nodeID: node.id, accountID: model.me?.uid)) {
                    NodeCell(node: node).frame(height: 50)
                }
            }
        }.navigationTitle(Text("Nodes"))
    }
}

struct WatchMessageRow: View {
    let message: WatchMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !message.title.isEmpty {
                Text(message.title).font(.headline).lineLimit(2)
            }
            Text(message.summary).font(.body).lineLimit(3)
            if let date = message.date {
                Text(date, style: .relative).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

struct WatchMessageDetailView: View {
    let messageID: String
    let accountID: String
    @EnvironmentObject private var model: LogicModel
    @Environment(\.dismiss) private var dismiss
    @State private var message: WatchMessage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let message = message {
                    if !message.title.isEmpty { Text(message.title).font(.headline) }
                    if let date = message.date {
                        Text(date, style: .date).font(.footnote).foregroundColor(.secondary)
                        Text(date, style: .time).font(.footnote).foregroundColor(.secondary)
                    }
                    Text(message.summary)
                    if message.truncated {
                        Text("LongMessageHint").font(.footnote).foregroundColor(.secondary)
                    }
                } else if model.inboxProcessing {
                    ProgressView()
                } else {
                    Text("MessageUnavailableHint")
                    Button("RefreshMessages") { model.requestMessageRefresh() }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle(Text("MessageSummary"))
        .onAppear { reloadMessage() }
        .onReceive(model.$inboxProcessing) { _ in reloadMessage() }
        .onChange(of: model.me?.uid) { _ in
            if model.me?.uid != accountID { message = nil; dismiss() }
        }
    }

    private func reloadMessage() {
        message = model.messageSnapshot(messageID, accountID: accountID)
    }
}

struct NodeCell: View {
    var node: NodeModel
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                let size = geometry.size.height
                IconView(icon: node.icon)
                    .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 2))
                    .frame(width: size - 10, height: size, alignment: .center)
                VStack(alignment: .leading) {
                    Text(node.name)
                        .font(.body)
                        .lineLimit(1)
                    Text(node.endpoint)
                        .font(.footnote)
                        .lineLimit(1)
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView().environmentObject(LogicModel(previewMessages: [
                WatchMessage(previewID: "sample-1", title: "服务恢复正常", summary: "所有服务检查通过，可以继续使用。", date: Date()),
                WatchMessage(previewID: "sample-2", title: "每日提醒", summary: "今天的任务已完成。更多内容请在 iPhone 查看。", date: Date().addingTimeInterval(-3600))
            ]))
        }
        .environment(\.locale, Locale(identifier: "zh-Hans"))
        .previewDisplayName("Message summaries")
    }
}
#endif

struct WatchStatusView: View {
    @EnvironmentObject private var model: LogicModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.configurationStatus == .failed {
                Label("ConfigurationFailed", systemImage: "exclamationmark.triangle")
                Button("RetryConfiguration") {
                    CHLogic.shared.retryWatchConfiguration()
                    model.refreshStatus()
                }
            } else if model.configurationStatus == .received {
                Text("ConfigurationReceived")
            } else {
                Text("WaitingForConfiguration")
            }
            if let date = model.lastConfigurationDate {
                Text("ConfigurationProcessedAt")
                Text(date, style: .date)
                Text(date, style: .time)
            }
            if model.notificationStatus == .denied {
                Label("NotificationsDenied", systemImage: "bell.slash")
            } else if model.notificationStatus == .notDetermined {
                Button("EnableNotifications") {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted { WKExtension.shared().registerForRemoteNotifications() }
                            model.refreshStatus()
                        }
                    }
                }
            } else {
                Label("NotificationsEnabled", systemImage: "bell")
            }
            Text("ConfigurationSyncHint")
                .foregroundColor(.secondary)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
