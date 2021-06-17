//
//  WidgetKit.swift
//  iOS
//
//  Created by WizJin on 2021/6/17.
//

import Foundation
import WidgetKit

@objc(CHWidgetKit)
class CHWidgetKit : NSObject {
    @objc static func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
