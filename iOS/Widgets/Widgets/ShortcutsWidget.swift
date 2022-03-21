//
//  ShortcutsWidget.swift
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/15.
//

import WidgetKit
import SwiftUI
import Intents

extension EntryType {
    public var type: String {
        if let id = self.identifier {
            if let index = id.firstIndex(of: ".") {
                return String(id.prefix(upTo: index))
            }
            return id
        }
        return ""
    }
    
    public var code: String {
        if let id = self.identifier {
            if let index = id.firstIndex(of: ".") {
                return String(id.suffix(from: id.index(after: index)))
            }
        }
        return ""
    }
    
    public var title: String {
        switch type {
        case "none":
            return ""
        case "action":
            return code.localized;
        case "channel":
            return CHWidgetManager.shared.channelName(code)
        default:
            let text = self.displayString
            if let index = text.firstIndex(of: ":") {
                return String(self.displayString.suffix(from: text.index(after: index)))
            }
            return text
        }
    }
    
    public var icon: String {
        if type == "channel" {
            return CHWidgetManager.shared.channelIcon(code)
        }
        return ""
    }
    
    public var linkURL: URL {
        switch type {
        case "action":
            if code == "scan" {
                return URL(string: "chanify:///action/scan")!
            }
        case "channel":
            return URL(string: "chanify:///page/channel?cid=\(code)")!
        default:
            break
        }
        return URL(string: "chanify:///")!
    }

}

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
        let title = entry.title
        if title.isEmpty {
            Color(.clear)
        } else {
            switch entry.type {
            case "action":
                Link(destination: entry.linkURL) {
                    VStack(alignment: .center) {
                        IconView(icon: Image(systemName: "qrcode.viewfinder"), tint: .label, background: .systemFill)
                        Text(entry.title).font(.system(size: 10)).lineLimit(1)
                    }
                }
            default:
                Link(destination: entry.linkURL) {
                    VStack(alignment: .center) {
                        IconView(icon: entry.icon)
                        Text(entry.title).font(.system(size: 10)).lineLimit(1)
                    }
                }
            }
        }
    }
}

struct ShortcutsEntryView : View {
    @Environment(\.colorScheme) var colorScheme

    var entry: ShortcutsProvider.Entry

    var body: some View {
        if !CHWidgetManager.shared.isLogin {
            Text("Please login first to continue!").font(.footnote)
        } else {
            GeometryReader { geometry in
                ZStack {
                    Color(.systemBackground)
                    if let entries = entry.configuration.entries {
                        ForEach(0..<entries.count, id: \.self) { i in
                            let frame = LayoutItem(geometry, i, entry.configuration)
                            EntryItemView(entry: entries[i])
                                .frame(width: frame.width, height: frame.height, alignment: .center)
                                .position(frame.origin)
                        }
                    }
                }.colorScheme(colorScheme.withAppearance(entry.configuration.appearance))
            }
        }
    }
    
    private func LayoutItem(_ geometry: GeometryProxy, _ index: Int, _ configuration: ShortcutsConfigurationIntent) -> CGRect {
        let size = geometry.size.height * 0.4
        var frame = CGRect(x: 0, y: 0, width: size, height: size);
        let margin = CGPoint(x: (geometry.size.width - size * 4.0)/5.0, y: (geometry.size.height - size * 2.0)/3.0)
        frame.size.width += margin.x
        switch configuration.alignment {
        case .right:
            frame.origin.x = geometry.size.width -  size*0.5 - margin.x - frame.size.width * CGFloat(index/2)
            frame.origin.y = size*0.5 + margin.y + (size + margin.y) * CGFloat(index%2)
        case .top:
            frame.origin.x = size*0.5 + margin.x + frame.size.width * CGFloat(index%4)
            frame.origin.y = size*0.5 + margin.y + (size + margin.y) * CGFloat(index/4)
        case .bottom:
            frame.origin.x = size*0.5 + margin.x + frame.size.width * CGFloat(index%4)
            frame.origin.y = geometry.size.height - size*0.5 - margin.y - (size + margin.y) * CGFloat(index/4)
        default:
            frame.origin.x = size*0.5 + margin.x + frame.size.width * CGFloat(index/2)
            frame.origin.y = size*0.5 + margin.y + (size + margin.y) * CGFloat(index%2)
        }
        return frame
    }
}

struct ShortcutsWidget: Widget {
    let kind: String = "net.chanify.ios.widgets.shortcuts"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ShortcutsConfigurationIntent.self, provider: ShortcutsProvider()) { entry in
            ShortcutsEntryView(entry: entry)
        }
        .configurationDisplayName("Shortcuts")
        .description("The shortcut to open selected targets.")
        .supportedFamilies([.systemMedium])
    }
}
