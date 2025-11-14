//
//  ExpiredLinksProvider.swift
//  ClippyWidget
//
//  Created by Claude Code
//

import WidgetKit
import SwiftUI
import RealmSwift
import AppIntents

struct ExpiredLinksProvider: AppIntentTimelineProvider {
    typealias Entry = ExpiredLinksEntry
    typealias Intent = ClippyWidgetConfigurationIntent

    func placeholder(in context: Context) -> ExpiredLinksEntry {
        ExpiredLinksEntry(
            date: Date(),
            links: [WidgetLinkData(url: "https://example.com", title: "예시 링크", daysLeft: 1)],
            contentType: .expiredLinks
        )
    }

    func snapshot(for configuration: ClippyWidgetConfigurationIntent, in context: Context) async -> ExpiredLinksEntry {
        ExpiredLinksEntry(
            date: Date(),
            links: fetchLinks(for: configuration.contentType),
            contentType: configuration.contentType
        )
    }

    func timeline(for configuration: ClippyWidgetConfigurationIntent, in context: Context) async -> Timeline<ExpiredLinksEntry> {
        let currentDate = Date()
        let links = fetchLinks(for: configuration.contentType)

        // 현재 시간의 엔트리 생성
        let entry = ExpiredLinksEntry(
            date: currentDate,
            links: links,
            contentType: configuration.contentType
        )

        // 1시간마다 업데이트
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))

        return timeline
    }

    private func fetchLinks(for contentType: WidgetContentType) -> [WidgetLinkData] {
        print("🔷 [Widget] fetchLinks 시작 - 타입: \(contentType.rawValue)")

        // App Group을 통해 공유된 Realm 접근
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jimin.Clippy") else {
            return []
        }

        let realmURL = appGroupURL.appendingPathComponent("default.realm")

        // 파일 존재 확인
        if FileManager.default.fileExists(atPath: realmURL.path) {
            print("✅ [Widget] Realm 파일 존재 확인")
        } else {
            print("❌ [Widget] Realm 파일이 존재하지 않음")
            return []
        }

        var config = Realm.Configuration()
        config.fileURL = realmURL
        config.schemaVersion = 3

        do {
            let realm = try Realm(configuration: config)

            // 전체 링크 개수 확인
            let allLinks = realm.objects(LinkList.self)

            // contentType에 따라 다른 쿼리 실행
            let filteredLinks: Results<LinkList>

            switch contentType {
            case .expiredLinks:
                // 마감일이 3일 이내인 링크
                let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
                filteredLinks = realm.objects(LinkList.self)
                    .filter("deadline != nil AND deadline <= %@", threeDaysLater)
                    .sorted(byKeyPath: "deadline", ascending: true)
                print("🔷 [Widget] 마감 임박 링크 개수: \(filteredLinks.count)")

            case .recentLinks:
                // 최근 추가된 링크 (ObjectId는 생성 시간 포함)
                filteredLinks = realm.objects(LinkList.self)
                    .sorted(byKeyPath: "id", ascending: false)
                print("🔷 [Widget] 최근 링크 개수: \(filteredLinks.count)")

            case .favoriteLinks:
                // 즐겨찾기 링크
                filteredLinks = realm.objects(LinkList.self)
                    .filter("likeStatus == true")
                    .sorted(byKeyPath: "id", ascending: false)
                print("🔷 [Widget] 즐겨찾기 링크 개수: \(filteredLinks.count)")

            case .unreadLinks:
                // 읽지 않은 링크
                filteredLinks = realm.objects(LinkList.self)
                    .filter("isOpened == false")
                    .sorted(byKeyPath: "id", ascending: false)
                print("🔷 [Widget] 읽지 않은 링크 개수: \(filteredLinks.count)")
            }

            let result = Array(filteredLinks.prefix(5).map { link in
                let daysLeft: Int
                if let deadline = link.deadline {
                    // 앱과 동일하게 startOfDay를 사용하여 날짜만 비교
                    let calendar = Calendar.current
                    let startOfToday = calendar.startOfDay(for: Date())
                    let startOfDueDate = calendar.startOfDay(for: deadline)
                    daysLeft = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0
                } else {
                    daysLeft = 999 // 마감일 없음
                }

                print("🔷 [Widget] 변환: \(link.title)")
                return WidgetLinkData(
                    url: link.url,
                    title: link.title,
                    daysLeft: daysLeft
                )
            })

            print("✅ [Widget] 최종 반환 개수: \(result.count)")
            return result
        } catch {
            print("❌ [Widget] Realm 접근 오류: \(error)")
            return []
        }
    }
}

// Timeline Entry
struct ExpiredLinksEntry: TimelineEntry {
    let date: Date
    let links: [WidgetLinkData]
    let contentType: WidgetContentType
}

// Widget에서 사용할 간단한 링크 데이터 모델
struct WidgetLinkData: Identifiable {
    let id = UUID()
    let url: String
    let title: String
    let daysLeft: Int

    var displayDaysLeft: String {
        if daysLeft == 0 {
            return "오늘"
        } else if daysLeft < 0 {
            return "마감"
        } else {
            return "D-\(daysLeft)"
        }
    }

    var statusColor: Color {
        if daysLeft <= 0 {
            return .red
        } else if daysLeft == 1 {
            return .orange
        } else {
            return .green
        }
    }
}
