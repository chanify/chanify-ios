//
//  ShortcutsWidget.swift
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/15.
//

import WidgetKit
import SwiftUI
import Intents

struct ShortcutsEntry: TimelineEntry {
    let date: Date
    let configuration: ShortcutsConfigurationIntent
}

struct ShortcutsProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> ShortcutsEntry {
        ShortcutsEntry(date: Date(), configuration: ShortcutsConfigurationIntent())
    }

    func getSnapshot(for configuration: ShortcutsConfigurationIntent, in context: Context, completion: @escaping (ShortcutsEntry) -> ()) {
        let entry = ShortcutsEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ShortcutsConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = ShortcutsEntry(date: Date(), configuration: configuration)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct ShortcutsEntryView : View {
    var entry: ShortcutsProvider.Entry

    var body: some View {
        ZStack {
            Color(.systemFill)
            HStack {
                Link(destination:URL(string: "chanify:///home")!) {
                    Image(systemName: "qrcode")
                        .resizable().scaledToFit()
                        .frame(width: 32, height: 32, alignment: .center)
                }
                Link(destination:URL(string: "chanify:///action/scan")!) {
                    Image(systemName: "qrcode.viewfinder")
                        .resizable().scaledToFit()
                        .frame(width: 32, height: 32, alignment: .center)
                }
                Link(destination:URL(string: "chanify:///channel")!) {
                    IconView(icon: "")
                        .frame(width: 32, height: 32, alignment: .center)
                }
            }
        }
    }
}

struct ShortcutsWidget: Widget {
    let kind: String = "net.chanify.ios.widgets.shortcuts"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ShortcutsConfigurationIntent.self, provider: ShortcutsProvider()) { entry in
            ShortcutsEntryView(entry: entry)
        }
        .configurationDisplayName("Shortcuts")
        .description("A quick way to open selected page in Chanify.")
        .supportedFamilies([.systemMedium])
    }
}

//struct ShortcutsWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        ShortcutsEntryView(entry: ShortcutsEntry(date: Date(), configuration: ShortcutsConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//    }
//}
