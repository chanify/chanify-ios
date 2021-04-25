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
    var title: String?

    override var body: NotificationView {
        NotificationView(title:title, text: message)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    override func didReceive(_ notification: UNNotification) {
        message = notification.request.content.body
        title = notification.request.content.title
        self.notificationActions = [UNNotificationAction]()
    }
}
