//
//  ChartsWidget.swift
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/15.
//

import WidgetKit
import SwiftUI
import Intents

struct ChartsEntry: TimelineEntry {
    let date: Date
    let configuration: ChartsConfigurationIntent
}

struct ChartsProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> ChartsEntry {
        ChartsEntry(date: Date(), configuration: ChartsConfigurationIntent())
    }

    func getSnapshot(for configuration: ChartsConfigurationIntent, in context: Context, completion: @escaping (ChartsEntry) -> ()) {
        let entry = ChartsEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ChartsConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ChartsEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ChartsEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ChartsEntryView : View {
    var entry: ChartsProvider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

struct ChartsWidget: Widget {
    let kind: String = "net.chanify.ios.widgets.charts"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ChartsConfigurationIntent.self, provider: ChartsProvider()) { entry in
            ChartsEntryView(entry: entry)
        }
        .configurationDisplayName("Charts")
        .description("Show charts of timeline notification.")
    }
}

