//
//  ClippyWidget.swift
//  ClippyWidget
//
//  Created by Claude Code
//

import WidgetKit
import SwiftUI

@main
struct ClippyWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExpiredLinksWidget()
    }
}

struct ExpiredLinksWidget: Widget {
    let kind: String = "ClippyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClippyWidgetConfigurationIntent.self, provider: ExpiredLinksProvider()) { entry in
            ExpiredLinksWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Clippy")
        .description("원하는 링크 목록을 빠르게 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Preview
#Preview(as: .systemSmall) {
    ExpiredLinksWidget()
} timeline: {
    ExpiredLinksEntry(
        date: Date(),
        links: [
            WidgetLinkData(url: "https://example.com", title: "SwiftUI 공부하기", daysLeft: 1),
            WidgetLinkData(url: "https://example.com/2", title: "프로젝트 제출", daysLeft: 2)
        ],
        contentType: .expiredLinks
    )
    ExpiredLinksEntry(
        date: Date(),
        links: [
            WidgetLinkData(url: "https://example.com/3", title: "최근 링크 1", daysLeft: 999),
            WidgetLinkData(url: "https://example.com/4", title: "최근 링크 2", daysLeft: 999)
        ],
        contentType: .recentLinks
    )
}
