---
name: swift-ios
description: iOS app development with Swift and SwiftUI. Covers UIKit when needed, iOS-specific APIs, App Store guidelines, and mobile UX patterns. Use for any iOS-targeted development.
user-invocable: true
argument-hint: "[iOS feature or component]"
---

# iOS Development Skill

You are an expert iOS developer. Your role is to build high-quality iOS applications following Apple's Human Interface Guidelines and Swift best practices.

## iOS Development Principles

### SwiftUI First
- Use SwiftUI for new UI development
- Fall back to UIKit only when necessary
- Bridge SwiftUI and UIKit when needed
- Use UIViewRepresentable/UIViewControllerRepresentable

### iOS-Specific Considerations
- Support Dynamic Type for accessibility
- Handle different device sizes
- Respect Safe Area
- Support Dark Mode
- Handle orientation changes
- Optimize for battery life

## Architecture Patterns

### MVVM with SwiftUI
```swift
// Model
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
}

// ViewModel
@Observable
class UserViewModel {
    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let repository: UserRepository

    init(repository: UserRepository = .live) {
        self.repository = repository
    }

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            users = try await repository.fetchUsers()
        } catch {
            self.error = error
        }
    }
}

// View
struct UserListView: View {
    @State private var viewModel = UserViewModel()

    var body: some View {
        List(viewModel.users) { user in
            UserRow(user: user)
        }
        .task {
            await viewModel.loadUsers()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### The Composable Architecture (TCA)
```swift
@Reducer
struct UserFeature {
    @ObservableState
    struct State: Equatable {
        var users: [User] = []
        var isLoading = false
    }

    enum Action {
        case loadUsers
        case usersLoaded([User])
        case userTapped(User)
    }

    @Dependency(\.userClient) var userClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadUsers:
                state.isLoading = true
                return .run { send in
                    let users = try await userClient.fetchUsers()
                    await send(.usersLoaded(users))
                }
            case let .usersLoaded(users):
                state.isLoading = false
                state.users = users
                return .none
            case .userTapped:
                return .none
            }
        }
    }
}
```

## SwiftUI Patterns

### Reusable Components
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

### View Modifiers
```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

### Navigation
```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink("Users", value: Route.users)
                NavigationLink("Settings", value: Route.settings)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .users:
                    UserListView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}
```

## iOS APIs

### Networking
```swift
actor NetworkClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }
}
```

### Core Data
```swift
@Model
final class Item {
    var timestamp: Date
    var title: String

    init(timestamp: Date = .now, title: String) {
        self.timestamp = timestamp
        self.title = title
    }
}

// Or with SwiftData
struct ContentView: View {
    @Query(sort: \Item.timestamp, order: .reverse)
    private var items: [Item]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }
}
```

### Push Notifications
```swift
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
```

## Human Interface Guidelines

### Layout
- Use standard margins (16pt)
- Respect safe areas
- Support all device sizes
- Use adaptive layouts

### Typography
- Use Dynamic Type
- Prefer system fonts
- Maintain hierarchy

### Color
- Support Dark Mode
- Use semantic colors
- Ensure contrast

### Interaction
- Minimum tap target: 44×44pt
- Provide haptic feedback
- Show loading states

## App Store Guidelines

### Required
- Privacy manifest
- App icons (all sizes)
- Launch screen
- Supported orientations

### Review Considerations
- In-app purchases via StoreKit
- User data privacy
- Content moderation
- Age ratings

## Testing Strategy

```swift
// Unit Test
final class UserViewModelTests: XCTestCase {
    func testLoadUsers() async {
        let mockRepository = MockUserRepository()
        mockRepository.users = [User.mock]

        let viewModel = UserViewModel(repository: mockRepository)
        await viewModel.loadUsers()

        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
}

// UI Test
final class UserListUITests: XCTestCase {
    func testUserListDisplays() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Users"].exists)
        XCTAssertTrue(app.cells.count > 0)
    }
}

// Preview
#Preview {
    UserListView()
        .environment(UserViewModel())
}
```

## Project Structure

```
MyApp/
├── App/
│   ├── MyApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Users/
│   │   ├── UserListView.swift
│   │   ├── UserDetailView.swift
│   │   └── UserViewModel.swift
│   └── Settings/
│       └── SettingsView.swift
├── Core/
│   ├── Network/
│   ├── Storage/
│   └── Extensions/
├── UI/
│   ├── Components/
│   └── Modifiers/
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    └── UITests/
```

## Remember

- SwiftUI first, UIKit when needed
- Always support accessibility
- Test on multiple devices
- Follow HIG religiously
- Optimize for performance
- Handle all error states
