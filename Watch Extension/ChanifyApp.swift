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
                ContentView()
                    .environmentObject(model)
            }.onReceive(logic.userInfoUpdated, perform: { me in
                model.me = me
            }).onAppear() {
                logic.logicUserInfoChanged(CHLogic.shared.me)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "general")
    }
    
    class LogicDelegate : NSObject, CHLogicDelegate {
        let userInfoUpdated = PassthroughSubject<CHUserModel?, Never>()

        override init() {
            super.init()
            CHLogic.shared.addDelegate(self)
        }

        deinit {
            CHLogic.shared.removeDelegate(self)
        }

        func logicUserInfoChanged(_ me: CHUserModel?) {
            self.userInfoUpdated.send(me)
        }
    }

    class ExtensionDelegate : NSObject, WKExtensionDelegate {
        func applicationDidFinishLaunching() {
        }
    }
}
