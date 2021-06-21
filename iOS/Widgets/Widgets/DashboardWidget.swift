//
//  ChartsWidget.swift
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/15.
//

import WidgetKit
import SwiftUI
import Intents

struct DashboardEntry: TimelineEntry {
    let date: Date
    let configuration: DashboardConfigurationIntent
}

struct DashboardProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> DashboardEntry {
        DashboardEntry(date: Date(), configuration: DashboardConfigurationIntent())
    }

    func getSnapshot(for configuration: DashboardConfigurationIntent, in context: Context, completion: @escaping (DashboardEntry) -> ()) {
        let entry = DashboardEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: DashboardConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [DashboardEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = DashboardEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct DashboardEntryView : View {
    @Environment(\.colorScheme) var colorScheme

    var entry: DashboardProvider.Entry

    var body: some View {
        if !CHWidgetManager.shared.isLogin {
            Text("Please login first to continue!").font(.footnote)
        } else {
            ZStack {
                Color(.systemBackground)
                Text("Dashboard")
            }.colorScheme(colorScheme.withAppearance(entry.configuration.appearance))
        }
    }
}

struct DashboardWidget: Widget {
    let kind: String = "net.chanify.ios.widgets.charts"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: DashboardConfigurationIntent.self, provider: DashboardProvider()) { entry in
            DashboardEntryView(entry: entry)
        }
        .configurationDisplayName("Dashboard")
        .description("Show dashboard of timeline notification.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

