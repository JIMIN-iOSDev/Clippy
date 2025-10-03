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
        // 권한 요청은 사용자가 앱에 진입한 후에 하도록 수동으로 호출
    }
    
    // MARK: - Permission Request
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
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
        print("🔔 알림 등록 시도: \(title), 마감일: \(dueDate)")
        
        // 권한 상태 확인
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔐 알림 권한 상태: \(settings.authorizationStatus.rawValue)")
            print("🔔 알림 스타일: \(settings.alertSetting.rawValue)")
            print("🔊 사운드 설정: \(settings.soundSetting.rawValue)")
        }
        
        // 기존 알림 먼저 확인하고 취소
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let existingRequest = requests.first { $0.identifier == linkId }
            if existingRequest != nil {
                print("🔄 기존 알림 취소 후 새로 등록: \(title)")
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [linkId])
            }
        }
        
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        
        // 마감일이 오늘 이전인 경우에만 알림 등록하지 않음
        // 내일 마감인 경우도 오늘 6시 이전에 추가되었다면 알림 등록
        guard dueDate >= tomorrowStart else {
            print("⚠️ 마감일이 오늘 이전이므로 알림 등록하지 않음: \(title) - 마감일: \(dueDate), 내일 시작: \(tomorrowStart)")
            return
        }
        
        // 알림 시간: 마감일 하루 전 오후 6시
        let notificationDate = calendar.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        
        // 하루 전 날짜의 오후 2시로 설정
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 14
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Clippy"
        
        // 제목을 26자로 제한하고 요약 (링크 + 띄어쓰기 고려)
        let truncatedTitle = title.count > 26 ? String(title.prefix(26)) + "..." : title
        content.body = "\(truncatedTitle) 링크 마감일이 내일입니다!"
        content.sound = .default
        
        // 배지 설정하지 않음 (배지 사용 안 함)
        content.badge = nil
        
        // 알림 이미지 첨부 - 더 단순한 방식
        print("🔍 알림 이미지 첨부 시도...")
        
        // 다양한 이미지 이름으로 시도
        let imageNames = ["Clippy 로고", "AppIcon", "Clippy로고"]
        
        for imageName in imageNames {
            if let image = UIImage(named: imageName) {
                print("📷 \(imageName) 이미지 발견!")
                
                // Bundle의 캐시 디렉토리에 저장
                let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let filename = "notification_\(imageName.replacingOccurrences(of: " ", with: "_")).png"
                let imageURL = cacheDirectory.appendingPathComponent(filename)
                
                if let data = image.pngData() {
                    do {
                        try data.write(to: imageURL)
                        let attachment = try UNNotificationAttachment(identifier: "attachment", url: imageURL, options: nil)
                        content.attachments = [attachment]
                        print("✅ \(imageName) 알림 첨부 성공!")
                        break // 성공하면 루프 종료
                    } catch {
                        print("❌ \(imageName) 저장 실패: \(error)")
                    }
                }
            } else {
                print("❌ \(imageName) 이미지 없음")
            }
        }
        
        print("⚠️ 모든 이미지 첨부 실패")
        
        // 뱃지 제거
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: linkId, content: content, trigger: trigger)
        
        print("📅 알림 시간 설정: \(dateComponents)")
        print("🎯 예정된 알림 날짜: \(notificationDate)")
        
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
    
    /// 모든 저장된 링크에 대해 알림을 설정합니다 (새로 추가되는 링크는 제외)
    func setupNotificationsForAllLinks() {
        let repository = CategoryRepository()
        let categories = repository.readCategoryList()
        
        // 기존 모든 알림 제거
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        var notificationCount = 0
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        
        for category in categories {
            for link in category.category {
                if let deadline = link.deadline {
                    // 마감일이 내일 이후인 경우에만 알림 등록
                    // (새로 추가되는 링크는 LinkManager에서 별도로 등록되므로 여기서 제외)
                    guard deadline >= tomorrowStart else {
                        continue
                    }
                    
                    sendNotificationForLink(title: link.title, dueDate: deadline, url: link.url)
                    notificationCount += 1
                }
            }
        }
        
        print("📱 총 \(notificationCount)개의 알림을 설정했습니다 (기존 링크만)")
    }
    
    private func sendNotificationForLink(title: String, dueDate: Date, url: String) {
        // URL을 식별자로 사용
        let linkId = url.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        scheduleNotificationForLink(title: title, dueDate: dueDate, linkId: linkId)
    }
}