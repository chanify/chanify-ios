//
//  ChanifyApp.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI

@main
struct ChanifyApp: App {
    @StateObject public var model = LogicModel()
    private var logic = WatchLogic()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(model)
            }.onAppear() {
                model.me = logic.me
                logic.model = model
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "general")
    }
}
