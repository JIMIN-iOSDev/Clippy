//
//  WidgetConfiguration.swift
//  ClippyWidget
//
//  Created by Jimin on 11/03/25.
//

import Foundation
import AppIntents

/// 위젯에 표시할 콘텐츠 타입
enum WidgetContentType: String, AppEnum {
    case expiredLinks = "expired"
    case recentLinks = "recent"
    case favoriteLinks = "favorite"
    case unreadLinks = "unread"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "표시 내용"

    static var caseDisplayRepresentations: [WidgetContentType: DisplayRepresentation] = [
        .expiredLinks: "마감 임박 링크",
        .recentLinks: "최근 추가 링크",
        .favoriteLinks: "즐겨찾기",
        .unreadLinks: "읽지 않은 링크"
    ]
}

/// 위젯 설정 Intent
struct ClippyWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "위젯 설정"
    static var description = IntentDescription("표시할 링크 종류를 선택하세요")

    @Parameter(title: "표시 내용", default: .expiredLinks)
    var contentType: WidgetContentType

    init(contentType: WidgetContentType) {
        self.contentType = contentType
    }

    init() {
        self.contentType = .expiredLinks
    }
}
