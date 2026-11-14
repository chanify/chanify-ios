//
//  ChanifyApp.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI
import Combine

@main
struct ChanifyApp: App {
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var delegate
    @StateObject public var model = LogicModel()
    private let logic = LogicDelegate()
    @Environment(\.scenePhase) private var scenePhase

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                if model.me == nil {
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("NotInit")
                            WatchStatusView()
                        }.padding()
                    }.environmentObject(model)
                }
                if model.me != nil {
                    ContentView().environmentObject(model).id(model.me?.uid)
                }
            }.onReceive(logic.userInfoUpdated, perform: { me in
                model.updateAccount(me)
            }).onReceive(logic.nodesUpdated, perform: { nodes in
                model.nodes = nodes
            }).onReceive(logic.messagesUpdated) { _ in
                model.refreshMessageState(markUpdates: true)
            }.onReceive(logic.openMessage) { mid in
                model.openMessage(mid)
            }.onReceive(logic.configurationUpdated) { _ in
                model.refreshStatus()
            }.onAppear {
                logic.logicUserInfoChanged(CHLogic.shared.me)
                model.refreshStatus()
                model.refreshMessageState()
            }.onChange(of: scenePhase) { phase in
                if phase == .active {
                    model.refreshStatus()
                    model.refreshMessageState()
                }
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "general")
        WKNotificationScene(controller: NotificationController.self, category: "text")
        WKNotificationScene(controller: NotificationController.self, category: "link")
    }
    
    class LogicDelegate : NSObject, CHLogicDelegate {
        let messagesUpdated = PassthroughSubject<Void, Never>()
        let openMessage = PassthroughSubject<String, Never>()
        let configurationUpdated = PassthroughSubject<Void, Never>()
        let userInfoUpdated = PassthroughSubject<CHUserModel?, Never>()
        let nodesUpdated = PassthroughSubject<[NodeModel], Never>()

        override init() {
            super.init()
            CHLogic.shared.addDelegate(self)
        }

        deinit {
            CHLogic.shared.removeDelegate(self)
        }

        @objc func logicWatchMessagesChanged() {
            messagesUpdated.send(())
        }

        @objc func logicWatchOpenMessage(_ mid: String) {
            openMessage.send(mid)
        }

        @objc func logicWatchConfigurationChanged() {
            configurationUpdated.send(())
        }

        @objc func logicUserInfoChanged(_ me: CHUserModel?) {
            self.userInfoUpdated.send(me)
            notifyNodeChanged()
        }
        
        @objc func logicNodeUpdated(_ nid: String) {
            notifyNodeChanged()
        }
        
        @objc func logicNodesUpdated(_ nids: [String]) {
            notifyNodeChanged()
        }
        
        private func notifyNodeChanged() {
            self.nodesUpdated.send(LogicModel.loadNodes())
        }
    }

    class ExtensionDelegate : NSObject, WKApplicationDelegate {
        func applicationDidFinishLaunching() {
            CHLogic.shared.launch()
        }
        
        func applicationDidBecomeActive() {
            CHLogic.shared.active()
        }
        
        func applicationWillResignActive() {
            CHLogic.shared.deactive()
        }
        
        func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
            CHLogic.shared.updatePushToken(deviceToken)
        }
        
        func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
            CHLogic.shared.receiveRemoteNotification(userInfo)
            completionHandler(.newData)
        }
    }
}
