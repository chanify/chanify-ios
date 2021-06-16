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

struct EntryItemView : View {
    var entry: EntryType
    
    var body: some View {
        Link(destination: URL(string: (entry.link ?? "")) ?? URL(string: "chanify:///home")!) {
            IconView(icon: entry.icon)
        }
    }
}

struct ShortcutsEntryView : View {
    @Environment(\.colorScheme) var colorScheme

    var entry: ShortcutsProvider.Entry

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                if let entries = entry.configuration.entries {
                    let size = geometry.size.height * 0.35
                    let margin = CGPoint(x: (geometry.size.width - size * 4.0)/5.0, y: geometry.size.height * 0.1)
                    let offset = CGPoint(x: size*0.5 + margin.x, y: size*0.5 + margin.y)
                    ForEach(0..<entries.count) { i in
                        EntryItemView(entry: entries[i])
                            .frame(width: size, height: size, alignment: .center)
                            .position(x: offset.x + (size + margin.x) * CGFloat(i%4), y: offset.y + (size + margin.y) * CGFloat(i/4))
                    }
                }
            }.colorScheme(colorScheme.withAppearance(entry.configuration.appearance))
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
//    static func entry(identifier: String, display: String, icon: String) -> EntryType {
//        let entry = EntryType(identifier: identifier, display: display)
//        entry.icon = icon
//        entry.link = "chanify:///action/scan"
//        return entry
//    }
//
//    static func configuration() -> ShortcutsConfigurationIntent {
//        let c = ShortcutsConfigurationIntent();
//        c.appearance = .dark
//        c.entries = [
//            entry(identifier: "action.scan", display: "Scan", icon: "sys://qrcode.viewfinder"),
//            entry(identifier: "action.channel.001", display: "Channel", icon: ""),
//            entry(identifier: "action.channel.002", display: "Channel", icon: ""),
//            entry(identifier: "action.channel.003", display: "Channel", icon: ""),
//            entry(identifier: "action.channel.004", display: "Channel", icon: "")
//        ]
//        return c
//    }
//
//    static var previews: some View {
//        ShortcutsEntryView(entry: ShortcutsEntry(date: Date(), configuration: configuration()))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//    }
//}
