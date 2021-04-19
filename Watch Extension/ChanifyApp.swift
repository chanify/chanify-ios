//
//  ChanifyApp.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI

@main
struct ChanifyApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "general")
    }
}
