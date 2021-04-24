//
//  NotificationController.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import WatchKit
import SwiftUI
import UserNotifications

class NotificationController: WKUserNotificationHostingController<NotificationView> {
    var message: String?

    override var body: NotificationView {
        NotificationView(text: message)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    override func didReceive(_ notification: UNNotification) {
        message = notification.request.content.body
        self.notificationActions = [UNNotificationAction]()
    }
}
