import SwiftUI
import WidgetKit

struct LauncherEntry: TimelineEntry {
    let date: Date
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry { LauncherEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        completion(LauncherEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        completion(Timeline(entries: [LauncherEntry(date: .now)], policy: .never))
    }
}

struct LauncherView: View {
    @Environment(\.widgetFamily) private var family

    private var content: some View {
        Group {
            if family == .accessoryRectangular {
                Label("Chanify", systemImage: "bell.fill")
            } else {
                Image(systemName: "bell.fill").widgetAccentable()
                    .accessibilityLabel("Chanify")
            }
        }
        .widgetURL(URL(string: "chanify://"))
    }

    var body: some View {
        if #available(watchOSApplicationExtension 10.0, *) {
            content.containerBackground(for: .widget) { Color.clear }
        } else {
            content
        }
    }
}

struct WatchWidgets: Widget {
    let kind = "net.chanify.watch.launcher"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LauncherProvider()) { _ in
            LauncherView()
        }
        .configurationDisplayName("Chanify")
        .description("Open Chanify to view your messages.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
