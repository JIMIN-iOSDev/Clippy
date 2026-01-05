//
//  ExpiredLinksWidgetView.swift
//  ClippyWidget
//
//  Created by Jimin on 11/03/25.
//

import SwiftUI
import WidgetKit

struct ExpiredLinksWidgetView: View {
    var entry: ExpiredLinksEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.links.isEmpty {
            emptyStateView
        } else {
            switch widgetFamily {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            default:
                smallWidgetView
            }
        }
    }

    // MARK: - Helper Properties
    private var widgetTitle: String {
        switch entry.contentType {
        case .expiredLinks:
            return "마감 임박"
        case .recentLinks:
            return "최근 링크"
        case .favoriteLinks:
            return "즐겨찾기"
        case .unreadLinks:
            return "읽지 않음"
        }
    }

    private var emptyMessage: String {
        switch entry.contentType {
        case .expiredLinks:
            return "마감 임박 링크 없음"
        case .recentLinks:
            return "저장된 링크 없음"
        case .favoriteLinks:
            return "즐겨찾기 없음"
        case .unreadLinks:
            return "모두 읽었어요!"
        }
    }

    private var headerIcon: String {
        switch entry.contentType {
        case .expiredLinks:
            return "clock.fill"
        case .recentLinks:
            return "clock.arrow.circlepath"
        case .favoriteLinks:
            return "heart.fill"
        case .unreadLinks:
            return "envelope.fill"
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)

            Text(emptyMessage)
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Small Widget
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: headerIcon)
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text(widgetTitle)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.bottom, 8)

            Spacer()

            // 첫 번째 링크만 표시
            if let firstLink = entry.links.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(firstLink.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)

                    HStack {
                        Text(firstLink.displayDaysLeft)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(firstLink.statusColor)
                        Spacer()
                    }
                }
            }

            Spacer()

            // Footer - 추가 링크 개수
            if entry.links.count > 1 {
                Text("+\(entry.links.count - 1)개 더")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "clippy://expired-links"))
    }

    // MARK: - Medium Widget
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: headerIcon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                Text(widgetTitle)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(entry.links.count)개")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)

            // 링크 목록 (최대 3개)
            VStack(spacing: 8) {
                ForEach(entry.links.prefix(3)) { link in
                    Link(destination: URL(string: "clippy://link?url=\(link.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        HStack(spacing: 12) {
                            // D-day 표시 (마감 임박 링크일 때만)
                            if entry.contentType == .expiredLinks {
                                Text(link.displayDaysLeft)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(link.statusColor)
                                    .frame(width: 40, alignment: .leading)
                            }

                            // 링크 제목
                            Text(link.title)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            // 화살표
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if link.id != entry.links.prefix(3).last?.id {
                        Divider()
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}
