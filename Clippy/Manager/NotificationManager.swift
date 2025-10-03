//
//  NotificationManager.swift
//  Clippy
//
//  Created by Jimin on Today
//

import UserNotifications
import UIKit

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Permission Request
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ 알림 권한 요청 실패: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("✅ 알림 권한 허용됨")
                // 권한 설정 완료 후 기존 알림들 설정
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.setupNotificationsForAllLinks()
                }
            } else {
                print("❌ 알림 권한 거부됨")
            }
        }
    }
    
    // MARK: - Notification Management
    
    /// 링크의 마감일 하루 전 알림을 등록합니다
    func scheduleNotificationForLink(title: String, dueDate: Date, linkId: String) {
        // 마감일이 이미 지났거나 오늘인 경우 알림 등록하지 않음
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        guard dueDate > tomorrow else {
            print("⚠️ 마감일이 내일 이전이므로 알림 등록하지 않음: \(title)")
            return
        }
        
        // 알림 시간: 마감일 하루 전 오후 6시
        let calendar = Calendar.current
        let notificationDate = calendar.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        
        // 하루 전 날짜의 오후 6시로 설정
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Clippy"
        
        // 제목을 30자로 제한하고 요약
        let truncatedTitle = title.count > 30 ? String(title.prefix(30)) + "..." : title
        content.body = "\(truncatedTitle) - 마감일이 내일입니다!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: linkId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알림 등록 성공: \(title) - \(notificationDate)")
            }
        }
    }
    
    /// 특정 링크의 알림을 취소합니다
    func cancelNotificationForLink(linkId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [linkId])
        print("🗑️ 알림 취소: \(linkId)")
    }
    
    /// 특정 링크의 알림을 업데이트합니다 (기존 알림 취소 후 새로 등록)
    func updateNotificationForLink(title: String, oldDueDate: Date?, newDueDate: Date?, linkId: String) {
        // 기존 알림 먼저 취소
        if let oldDueDate = oldDueDate {
            cancelNotificationForLink(linkId: linkId + "_\(oldDueDate.timeIntervalSince1970)")
        }
        
        // 새 마감일이 있으면 새 알림 등록
        if let newDueDate = newDueDate {
            scheduleNotificationForLink(title: title, dueDate: newDueDate, linkId: linkId + "_\(newDueDate.timeIntervalSince1970)")
        }
    }
    
    // MARK: - Bulk Operations
    
    /// 모든 저장된 링크에 대해 알림을 설정합니다
    func setupNotificationsForAllLinks() {
        let repository = CategoryRepository()
        let categories = repository.readCategoryList()
        
        // 기존 모든 알림 제거
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        var notificationCount = 0
        
        for category in categories {
            for link in category.category {
                if let deadline = link.deadline {
                    sendNotificationForLink(title: link.title, dueDate: deadline, url: link.url)
                    notificationCount += 1
                }
            }
        }
        
        print("📱 총 \(notificationCount)개의 알림을 설정했습니다")
    }
    
    private func sendNotificationForLink(title: String, dueDate: Date, url: String) {
        // URL을 식별자로 사용
        let linkId = url.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        scheduleNotificationForLink(title: title, dueDate: dueDate, linkId: linkId)
    }
}