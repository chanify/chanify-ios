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
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate
    @StateObject public var model = LogicModel()
    private let logic = LogicDelegate()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                if model.me == nil {
                    Text("NotInit")
                        .multilineTextAlignment(.center)
                        .padding()
                }
                if model.me != nil {
                    ContentView().environmentObject(model)
                }
            }.onReceive(logic.userInfoUpdated, perform: { me in
                model.me = me
            }).onReceive(logic.nodesUpdated, perform: { nodes in
                model.nodes = nodes
            }).onAppear() {
                logic.logicUserInfoChanged(CHLogic.shared.me)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "general")
        WKNotificationScene(controller: NotificationController.self, category: "text")
        WKNotificationScene(controller: NotificationController.self, category: "link")
    }
    
    class LogicDelegate : NSObject, CHLogicDelegate {
        let userInfoUpdated = PassthroughSubject<CHUserModel?, Never>()
        let nodesUpdated = PassthroughSubject<[NodeModel], Never>()

        override init() {
            super.init()
            CHLogic.shared.addDelegate(self)
        }

        deinit {
            CHLogic.shared.removeDelegate(self)
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

    class ExtensionDelegate : NSObject, WKExtensionDelegate {
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
