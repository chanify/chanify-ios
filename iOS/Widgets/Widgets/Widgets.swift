//
//  Widgets.swift
//  Widgets
//
//  Created by WizJin on 2021/6/15.
//

import WidgetKit
import SwiftUI

@main
struct Widgets : WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ShortcutsWidget()
        DashboardWidget()
    }
}
