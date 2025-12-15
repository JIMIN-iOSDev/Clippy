# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Developer Preferences

- I am an iOS developer with 5 years of experience
- Respond in Korean unless otherwise requested
- Write code that avoids concurrency issues and memory leaks
- Follow MVVM architecture, SnapKit for layout, UIKit codebase (no Storyboards), and write testable code
- Avoid duplicate file names and class names

## Project Overview

**Clippy** is an iOS link management app that helps users organize links by category and provides deadline notifications. The app automatically extracts metadata from URLs (title, thumbnail, description) and offers favorites, search, and sorting features for efficient link management.

- **Platform**: iOS 16.0+
- **Language**: Swift 5.0+
- **Development Environment**: Xcode 16.4+

## Build & Development Commands

### Building the Project
```bash
# Build the main app target
xcodebuild -project Clippy.xcodeproj -scheme Clippy -configuration Debug build

# Build for running on simulator
xcodebuild -project Clippy.xcodeproj -scheme Clippy -sdk iphonesimulator -configuration Debug build

# Clean build folder
xcodebuild -project Clippy.xcodeproj -scheme Clippy clean
```

### Running Tests
This project does not currently have unit tests configured. Tests can be added using:
```bash
xcodebuild test -project Clippy.xcodeproj -scheme Clippy -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Package Management
Dependencies are managed via Swift Package Manager (SPM). To resolve packages:
```bash
xcodebuild -resolvePackageDependencies -project Clippy.xcodeproj
```

## Architecture & Design Patterns

### MVVM + Repository Pattern
The app follows MVVM architecture with a Repository pattern for data access:

- **View**: UIKit-based ViewControllers in `Clippy/View/`
- **ViewModel**: Logic is embedded within ViewControllers using RxSwift's Input/Output pattern (note: separate ViewModel files do not exist - ViewControllers handle their own reactive logic)
- **Model**: Data models in `Clippy/Model/` and Realm tables in `Clippy/DataBase/RealmTable.swift`
- **Repository**: `CategoryRepository` in `Clippy/DataBase/` - single source for all database operations

### Key Architectural Components

#### 1. LinkManager (Singleton)
`Clippy/Manager/LinkManager.swift` is the central coordinator for link operations:
- Manages link metadata caching (both data and images)
- Fetches metadata using Apple's LinkPresentation framework
- Provides reactive streams via RxSwift (BehaviorRelay)
- Handles link CRUD operations and coordinates with Repository
- **Important**: Always use `LinkManager.shared` for link operations, not Repository directly from ViewControllers

#### 2. CategoryRepository
`Clippy/DataBase/CategoryRepository.swift` is the data access layer:
- All Realm database operations (CRUD for categories and links)
- Links can belong to multiple categories (many-to-many relationship)
- Default "일반" (General) category is created automatically and cannot be deleted
- When deleting categories, links are automatically moved to "일반" category

#### 3. NotificationManager (Singleton)
`Clippy/Manager/NotificationManager.swift` handles local notifications:
- Schedules notifications 1 day before deadline at 2:00 PM
- Automatically cancels/updates notifications when links are modified or deleted
- Uses link URL as notification identifier

#### 4. Data Flow
```
View → LinkManager → CategoryRepository → Realm
                ↓
         RxSwift Streams → View Updates
```

### Realm Data Model

The app uses a many-to-many relationship between Categories and Links:

**Category** (Clippy/DataBase/RealmTable.swift:11)
- `id: ObjectId` (primary key)
- `name: String` - category name
- `colorIndex: Int` - color scheme index
- `iconName: String` - SF Symbol name
- `category: List<LinkList>` - links in this category

**LinkList** (Clippy/DataBase/RealmTable.swift:30)
- `id: ObjectId` (primary key)
- `url: String` - unique link URL
- `title: String` - extracted or user-provided title
- `thumbnail: String` - image URL/path
- `memo: String?` - user notes
- `deadline: Date?` - optional due date
- `likeStatus: Bool` - favorite status
- `isOpened: Bool` - read/unread status
- `openCount: Int` - number of times opened
- `parentCategory: LinkingObjects<Category>` - reverse reference

**Important**: The same URL can appear in multiple categories. When updating or deleting links, operations affect all instances across categories.

## RxSwift Patterns

The app extensively uses RxSwift/RxCocoa for reactive programming:

### Observable Streams
Key observables from `LinkManager`:
- `links: Observable<[LinkMetadata]>` - all links
- `recentLinks: Observable<[LinkMetadata]>` - 10 most recent links
- `savedLinksCount: Observable<Int>` - total link count
- `expiredLinksCount: Observable<Int>` - links expiring within 3 days
- `isLoading: Observable<Bool>` - loading state

### NotificationCenter Events
Use these for cross-component communication (see `Clippy/Extension/NotificationName.swift`):
- `.categoryDidCreate` - category created
- `.categoryDidUpdate` - category modified
- `.categoryDidDelete` - category deleted
- `.linkDidCreate` - link created
- `.linkDidDelete` - link deleted

**Example**: When a category is updated, `LinkManager` listens to `.categoryDidUpdate` and refreshes link data automatically.

## Share Extension

**ClippyShare** is a Share Extension target that allows saving links from other apps:
- Located in `ClippyShare/` directory
- Uses App Group `group.com.jimin.Clippy` for data sharing with main app
- Shares Realm database with main app via App Group container
- Has its own UI built with SnapKit

## UI Implementation

### Layout
- **SnapKit** is used for all Auto Layout code
- No Storyboards/XIBs - 100% programmatic UI
- Base class: `BaseViewController` (Clippy/Base/BaseViewController.swift)

### Color System
Custom colors defined in `Clippy/Extension/UIColor+Extension.swift`:
- `.clippyBlue` - primary brand color (RGB: 33/255, 150/255, 243/255)
- Category colors defined in `CategoryColor` enum

### Reusable Components
- `ReusableViewProtocol` for cell identifiers
- Custom table/collection view cells in respective View folders

## Key Features Implementation

### 1. Link Metadata Extraction
Uses Apple's **LinkPresentation** framework:
- `LinkManager.fetchLinkMetadata(for:)` fetches title, description, and thumbnail
- Implements fallback logic for sites that don't provide metadata
- Caches images to avoid repeated network calls
- Default fallback: domain-based title generation + app logo

### 2. Notification System
- Local notifications scheduled via `NotificationManager`
- Triggered 1 day before deadline at 2:00 PM (14:00)
- Notifications include link title (truncated to 26 chars) and app icon
- Automatically managed when links are created/updated/deleted

### 3. Caching Strategy
`LinkManager` maintains two caches:
- `linkCache: [String: LinkMetadata]` - link data cache (key: URL)
- `imageCache: [String: UIImage]` - thumbnail cache with thread-safe access via `imageCacheQueue`

## Firebase Integration

Configured in `AppDelegate.swift`:
- **Firebase Analytics** - user behavior tracking
- **Firebase Crashlytics** - crash reporting
- **Firebase Messaging** - FCM token generation (push notifications not yet implemented)

## Common Development Patterns

### Adding a New Link
```swift
// Via LinkManager (preferred)
LinkManager.shared.addLink(
    url: url,
    title: title,
    description: description,
    categories: [(name: "카테고리명", colorIndex: 0)],
    dueDate: deadline
)

// Repository handles Realm writes internally
// LinkManager automatically schedules notification if deadline exists
```

### Observing Link Changes
```swift
LinkManager.shared.links
    .bind(to: tableView.rx.items) { tableView, row, link in
        // Configure cell
    }
    .disposed(by: disposeBag)
```

### Category Operations
```swift
let repository = CategoryRepository()

// Create
repository.createCategory(name: "New Category", colorIndex: 0, iconName: "folder")

// Update
repository.updateCategory(oldName: "Old", newName: "New", colorIndex: 1, iconName: "star")

// Delete (moves links to "일반")
repository.deleteCategory(name: "Category Name")
```

## Important Constraints

1. **"일반" Category**: Cannot be deleted, serves as fallback for orphaned links
2. **URL Uniqueness**: Same URL can exist in multiple categories but maintains single LinkList object
3. **Notification Scheduling**: Only schedules for deadlines tomorrow or later (not for past/today)
4. **Cache Management**: When links are deleted, both link and image caches must be cleared
5. **Thread Safety**: Image cache operations use `imageCacheQueue` (concurrent with barriers for writes)

## App Group Configuration

The app uses App Group for data sharing between main app and Share Extension:
- **App Group ID**: `group.com.jimin.Clippy`
- Shared Realm database path configured via App Group container
- Both targets must have App Group entitlement configured

## Testing Notifications Locally

To test deadline notifications:
1. Set deadline to tomorrow's date
2. Notification will be scheduled for today at 2:00 PM
3. Check pending notifications: `UNUserNotificationCenter.current().getPendingNotificationRequests()`
4. For immediate testing, modify `NotificationManager.scheduleNotificationForLink()` to use shorter intervals

## Code Organization

```
Clippy/
├── AppDelegate.swift          # Firebase setup, notification delegates
├── SceneDelegate.swift        # Window/scene lifecycle
├── Base/                      # Base view controller
├── DataBase/
│   ├── RealmTable.swift       # Realm object models
│   └── CategoryRepository.swift # Data access layer
├── Manager/
│   ├── LinkManager.swift      # Central link coordinator (singleton)
│   ├── NotificationManager.swift # Notification scheduling (singleton)
│   └── TooltipManager.swift   # User guide tooltips
├── Model/
│   └── LinkMetadata.swift     # Link metadata struct (not Realm)
├── View/                      # Feature-based view organization
│   ├── Category/              # Main category list view
│   ├── EditCategory/          # Category creation/editing
│   ├── EditLink/              # Link creation/editing
│   ├── Like/                  # Favorites view
│   ├── LinkDetail/            # Link detail view
│   ├── LinkList/              # Links within a category
│   ├── Search/                # Search functionality
│   └── Tooltip/               # User onboarding guides
├── Extension/                 # UIKit extensions, custom types
└── Resource/                  # Utilities, protocols, enums

ClippyShare/                   # Share Extension target
└── ShareViewController.swift  # Share extension UI
```

## Common Gotchas

1. **LinkManager must be used for link operations**: Don't call `CategoryRepository` methods directly from views - use `LinkManager.shared` which handles caching and notifications
2. **Refresh after external changes**: Call `LinkManager.shared.refreshLinks()` after Realm is modified outside LinkManager
3. **Category notifications**: Listen to `.categoryDidUpdate` and `.categoryDidDelete` to refresh link data when categories change
4. **Image caching**: Images are cached in-memory only; they reload on app restart but use cached Realm data for immediate display
5. **Deadline validation**: `NotificationManager` won't schedule notifications for deadlines before tomorrow
