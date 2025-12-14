# 📎 Clippy

> 링크를 체계적으로 관리하고 마감일을 놓치지 않도록 도와주는 앱

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-16.4+-blue.svg)

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/kr/app/clippy-%EB%A7%81%ED%81%AC-%EC%A0%80%EC%9E%A5-%ED%8F%B4%EB%8D%94-%EB%B6%84%EB%A5%98-%EB%A7%88%EA%B0%90%EC%9D%BC-%EC%95%8C%EB%A6%BC/id6753625594)

## 💡 소개

**Clippy**는 링크를 카테고리별로 체계적으로 관리하고, 마감일이 있는 링크에 대해 알림을 제공하는 앱입니다. 웹 링크의 메타데이터를 자동으로 추출하여 썸네일과 제목을 제공하며, 즐겨찾기 기능과 검색 기능을 통해 효율적인 링크 관리를 지원합니다.

## ✨ 주요 기능

### 🗂️ 카테고리 관리
- 링크를 카테고리별로 분류하여 체계적으로 관리
- 커스텀 카테고리 생성 및 편집
- 카테고리별 색상 및 아이콘 설정
- 기본 "일반" 카테고리 제공

### 🔗 링크 저장 및 관리
- URL 입력 시 자동으로 메타데이터 추출 (제목, 썸네일, 설명)
- 링크별 메모 추가 기능
- 마감일 설정 및 관리
- 읽음/안읽음 상태 표시

### ⏰ 알림 시스템
- 마감일 하루 전 자동 알림
- 로컬 알림 스케줄링 시스템
- 알림 권한 요청 및 관리
- 마감 임박 링크 하이라이트

### 🔍 검색 및 필터링
- 제목, URL, 설명 기반 실시간 검색
- 즐겨찾기 링크만 별도 관리
- 최근 추가순, 제목순, 마감일순 정렬

### 📊 통계 및 대시보드
- **실시간 요약 정보**
  - 저장된 링크 총 개수
  - 마감 임박 링크 개수 (3일 이내)
  - 최근 추가된 링크 목록

- **캘린더 뷰**
  - 날짜별 링크 저장 현황 시각화
  - 마감일이 있는 링크 캘린더 표시
  - 월간 링크 저장 패턴 분석

- **주간 활동 분석**
  - 최근 7일간 링크 저장 추이 막대 그래프
  - 일별 저장 개수 비교

- **카테고리 분포 차트**
  - 도넛 차트로 카테고리별 링크 비율 시각화
  - 가장 많이 사용하는 카테고리 인사이트 제공

### 📤 외부 앱에서 바로 저장
- Safari 및 다른 앱에서 직접 링크 저장
- 공유 시 카테고리, 메모, 마감일 즉시 설정 가능

### 📱 홈 화면 위젯
- 홈 화면에서 바로 링크 확인
- 4가지 위젯 타입: 마감 임박, 최근 추가, 즐겨찾기, 읽지 않음
- Small/Medium 크기 지원

## 📸 스크린샷

<div align="center">
  <img src="screenshots/1.png" width="200" alt="스크린샷 1"/>
  <img src="screenshots/2.png" width="200" alt="스크린샷 2"/>
  <img src="screenshots/3.png" width="200" alt="스크린샷 3"/>
  <img src="screenshots/4.png" width="200" alt="스크린샷 4"/>
</div>

<div align="center">
  <img src="screenshots/5.png" width="200" alt="스크린샷 5"/>
  <img src="screenshots/6.png" width="200" alt="스크린샷 6"/>
  <img src="screenshots/7.png" width="200" alt="스크린샷 7"/>
  <img src="screenshots/8.png" width="200" alt="스크린샷 8"/>
</div>

## 🛠️ 기술 스택

### Frontend
- **Swift 5.0+**
- **UIKit**
- **SnapKit**
- **RxSwift/RxCocoa**

### Backend & Database
- **Realm**
- **Firebase**

### iOS Frameworks & Extensions
- **WidgetKit**
- **Share Extension**
- **LinkPresentation**
- **UserNotifications**
- **App Groups**

### Architecture
- **MVVM + Input/Output**
- **Repository Pattern** 

## 📁 프로젝트 구조

```
Clippy/
├── AppDelegate.swift              # 앱 진입점 및 Firebase 설정
├── SceneDelegate.swift            # Scene 생명주기 관리
├── Base/
│   └── BaseViewController.swift   # 기본 뷰컨트롤러
├── DataBase/
│   ├── RealmTable.swift           # Realm 데이터 모델
│   └── CategoryRepository.swift   # 데이터 접근 계층
├── Manager/
│   ├── LinkManager.swift          # 링크 관리 로직
│   ├── NotificationManager.swift  # 알림 관리
│   └── TooltipManager.swift       # 사용자 가이드
├── Model/
│   └── LinkMetadata.swift         # 링크 메타데이터 모델
├── View/
│   ├── Category/                  # 카테고리 관련 화면
│   ├── EditCategory/              # 카테고리 편집
│   ├── EditLink/                  # 링크 편집
│   ├── Like/                      # 즐겨찾기 화면
│   ├── LinkDetail/                # 링크 상세 화면
│   ├── LinkList/                  # 링크 목록 화면
│   ├── Search/                    # 검색 화면
│   ├── Statistics/                # 통계 및 차트 화면
│   └── Tooltip/                   # 사용자 가이드
├── Extension/                     # 확장 기능
├── Resource/                      # 리소스 및 유틸리티
└── Assets.xcassets/               # 앱 아이콘 및 이미지

ClippyShare/                       # Share Extension
└── ShareViewController.swift      # 공유 확장 UI

ClippyWidget/                      # Widget Extension
├── ClippyWidget.swift             # 위젯 진입점
├── WidgetConfiguration.swift      # 위젯 설정
├── ExpiredLinksProvider.swift     # 위젯 데이터 제공
└── ExpiredLinksWidgetView.swift   # 위젯 UI
```

## 🚀 주요 기술적 도전과제

### 1. 메타데이터 자동 추출 시스템
- **문제**: URL만으로 제목, 썸네일, 설명을 자동으로 추출해야 함
- **해결**: Apple의 LinkPresentation 프레임워크를 활용한 메타데이터 자동 수집
- **결과**: 사용자 입력 없이 자동으로 링크 정보 완성

### 2. 실시간 알림 시스템 구현
- **문제**: 마감일 하루 전 정확한 알림 발송 및 백그라운드 처리
- **해결**: 로컬 알림 스케줄링 및 Firebase Messaging 연동 (향후 구현)
- **결과**: 앱이 종료되어도 안정적인 알림 제공

### 3. 반응형 UI 구현
- **문제**: 다양한 데이터 변화에 따른 실시간 UI 업데이트
- **해결**: RxSwift를 활용한 데이터 바인딩 및 상태 관리
- **결과**: 사용자 액션에 즉각적인 반응하는 부드러운 UX

### 4. 로컬 데이터베이스 최적화
- **문제**: 대량의 링크 데이터 효율적 저장 및 검색
- **해결**: Realm을 활용한 관계형 데이터 모델링 및 인덱싱
- **결과**: 빠른 검색 성능과 안정적인 데이터 관리

### 5. Share Extension을 통한 외부 앱 연동
- **문제**: Safari, Chrome 등 외부 앱에서 Clippy로 링크를 빠르게 저장하는 UX 구현
- **해결**: Share Extension 타겟 생성 및 App Groups를 통한 메인 앱과 데이터 공유
- **결과**: 별도 앱 실행 없이 공유 버튼으로 원터치 링크 저장 가능

### 6. Widget과 메인 앱 간 실시간 데이터 동기화
- **문제**: 메인 앱에서 링크를 추가/삭제할 때 위젯에 즉시 반영
- **해결**: App Groups 공유 Realm 컨테이너 및 WidgetCenter 자동 새로고침
- **결과**: 앱에서 변경 즉시 홈 화면 위젯 업데이트

### 7. 통계 데이터 시각화
- **문제**: 복잡한 링크 저장 패턴을 사용자가 쉽게 이해할 수 있도록 시각화
- **해결**: 커스텀 캘린더 뷰, 막대 그래프, 도넛 차트 구현
- **결과**: 직관적인 통계 정보 제공으로 사용 패턴 분석 가능

## 👨‍💻 개발 정보

- **개발 기간**: 
  - 핵심 개발: 2025.09.24 ~ 2025.10.03 (10일)
  - 유지보수: 2025.10.04 ~ 현재 (지속적 개선)
- **개발 인원**: 1명 (개인 프로젝트)
- **역할**: 기획, 디자인, 개발, 배포 전담
- **최소 지원 버전**: iOS 16.0+
- **개발 환경**: Xcode 16.4+, Swift 5.0+

## 🎓 학습 및 적용 기술

### 아키텍처 & 디자인 패턴
- **MVVM 패턴**: View와 비즈니스 로직 분리
- **Repository Pattern**: 데이터 접근 계층 추상화
- **Observer Pattern**: RxSwift를 통한 반응형 프로그래밍

### iOS 개발 기술
- **UIKit**: 네이티브 iOS UI 구현
- **Auto Layout**: SnapKit을 활용한 코드 기반 레이아웃
- **UserNotifications**: 로컬 알림 시스템 구현
- **LinkPresentation**: Apple 프레임워크를 활용한 링크 메타데이터 자동 추출

### iOS Extensions
- **Share Extension**: 외부 앱에서 링크 공유 기능 구현
- **WidgetKit**: 홈 화면 위젯 개발 (4가지 타입)
- **App Groups**: 메인 앱과 Extension 간 데이터 공유

### 데이터 관리
- **Realm**: 로컬 데이터베이스 설계 및 최적화
- **데이터 모델링**: 관계형 데이터베이스 설계
- **Thread-safe 캐싱**: Concurrent Queue를 활용한 이미지 캐시 구현

### 데이터 시각화
- **커스텀 캘린더**: 날짜별 링크 저장 현황 시각화
- **차트 구현**: 막대 그래프, 도넛 차트
- **인사이트 분석**: 사용 패턴 분석 및 통계 제공

### 외부 서비스 연동
- **Firebase Analytics**: 사용자 행동 분석 및 앱 사용 패턴 파악
- **Firebase Crashlytics**: 앱 크래시 모니터링 및 안정성 개선
- **Firebase Messaging**: 푸시 알림 서비스 (향후 구현 예정)

## 📞 문의사항

프로젝트에 대한 문의사항이 있으시면 언제든 남겨주세요.

[📝 문의하기](https://docs.google.com/forms/d/e/1FAIpQLSf9TrZJPPv5E3wA16mhgbTF02z1VVVOfZJ7xoiL2L1sJhZDTw/viewform)

---

**Clippy** - 링크 관리의 새로운 경험을 제공합니다! 📎✨
