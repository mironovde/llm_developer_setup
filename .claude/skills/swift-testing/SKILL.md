---
name: swift-testing
description: Swift testing strategies including unit tests, UI tests, snapshot testing, and TDD. Covers XCTest, Quick/Nimble, and testing best practices. Use for any Swift testing needs.
user-invocable: true
argument-hint: "[component or feature to test]"
---

# Swift Testing Skill

You are an expert in Swift testing. Your role is to ensure code quality through comprehensive testing strategies including unit tests, integration tests, UI tests, and snapshot tests.

## Testing Principles

### Test Pyramid
```
        /\
       /UI\        <- Few, slow, high-confidence
      /----\
     /Integr\      <- Some, medium speed
    /--------\
   /   Unit   \    <- Many, fast, focused
  /-----------\
```

### Test Characteristics (FIRST)
- **Fast**: Tests should run quickly
- **Independent**: No test depends on another
- **Repeatable**: Same result every time
- **Self-validating**: Pass or fail, no interpretation
- **Timely**: Written with/before code

## XCTest Fundamentals

### Basic Test Structure
```swift
import XCTest
@testable import MyApp

final class UserServiceTests: XCTestCase {
    // System under test
    var sut: UserService!
    var mockRepository: MockUserRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserService(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchUser_withValidId_returnsUser() async throws {
        // Arrange
        let expectedUser = User(id: "1", name: "John")
        mockRepository.stubbedUser = expectedUser

        // Act
        let user = try await sut.fetchUser(id: "1")

        // Assert
        XCTAssertEqual(user.id, expectedUser.id)
        XCTAssertEqual(user.name, expectedUser.name)
    }

    func test_fetchUser_withInvalidId_throwsError() async {
        // Arrange
        mockRepository.shouldThrowError = true

        // Act & Assert
        do {
            _ = try await sut.fetchUser(id: "invalid")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is UserServiceError)
        }
    }
}
```

### Test Naming Convention
```swift
// Pattern: test_[method]_[scenario]_[expectedResult]

func test_login_withValidCredentials_returnsToken() { }
func test_login_withInvalidPassword_throwsAuthError() { }
func test_calculateTotal_withEmptyCart_returnsZero() { }
func test_formatDate_withNilInput_returnsPlaceholder() { }
```

## Mocking and Stubbing

### Protocol-Based Mocking
```swift
// Protocol
protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
}

// Mock Implementation
class MockUserRepository: UserRepositoryProtocol {
    // Stubbed return values
    var stubbedUser: User?
    var shouldThrowError = false

    // Call tracking
    var fetchUserCallCount = 0
    var fetchUserReceivedIds: [String] = []
    var saveUserCallCount = 0
    var saveUserReceivedUsers: [User] = []

    func fetchUser(id: String) async throws -> User {
        fetchUserCallCount += 1
        fetchUserReceivedIds.append(id)

        if shouldThrowError {
            throw TestError.mockError
        }

        guard let user = stubbedUser else {
            throw TestError.notFound
        }

        return user
    }

    func saveUser(_ user: User) async throws {
        saveUserCallCount += 1
        saveUserReceivedUsers.append(user)

        if shouldThrowError {
            throw TestError.mockError
        }
    }
}
```

### Dependency Injection for Testing
```swift
// Production code
class UserService {
    private let repository: UserRepositoryProtocol
    private let analytics: AnalyticsProtocol

    init(
        repository: UserRepositoryProtocol = UserRepository(),
        analytics: AnalyticsProtocol = Analytics.shared
    ) {
        self.repository = repository
        self.analytics = analytics
    }
}

// Test
func test_example() {
    let mockRepo = MockUserRepository()
    let mockAnalytics = MockAnalytics()
    let sut = UserService(repository: mockRepo, analytics: mockAnalytics)
    // Test with mocks
}
```

## Async Testing

### Testing Async Functions
```swift
func test_fetchData_returnsExpectedResult() async throws {
    // Arrange
    let expected = "data"
    mockService.stubbedResult = expected

    // Act
    let result = try await sut.fetchData()

    // Assert
    XCTAssertEqual(result, expected)
}

// Testing async sequences
func test_stream_emitsExpectedValues() async {
    // Arrange
    let expected = [1, 2, 3]
    var received: [Int] = []

    // Act
    for await value in sut.numberStream() {
        received.append(value)
        if received.count == expected.count { break }
    }

    // Assert
    XCTAssertEqual(received, expected)
}
```

### Testing Publishers (Combine)
```swift
import Combine

func test_publisher_emitsExpectedValues() {
    // Arrange
    var cancellables = Set<AnyCancellable>()
    let expectation = expectation(description: "Values received")
    var receivedValues: [Int] = []

    // Act
    sut.valuesPublisher
        .sink { completion in
            if case .finished = completion {
                expectation.fulfill()
            }
        } receiveValue: { value in
            receivedValues.append(value)
        }
        .store(in: &cancellables)

    sut.emitValues()

    // Assert
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(receivedValues, [1, 2, 3])
}
```

## SwiftUI Testing

### Testing ViewModels
```swift
@Observable
class CounterViewModel {
    private(set) var count = 0

    func increment() { count += 1 }
    func decrement() { count -= 1 }
}

final class CounterViewModelTests: XCTestCase {
    var sut: CounterViewModel!

    override func setUp() {
        super.setUp()
        sut = CounterViewModel()
    }

    func test_increment_increasesCountByOne() {
        sut.increment()
        XCTAssertEqual(sut.count, 1)
    }

    func test_decrement_decreasesCountByOne() {
        sut.count = 5
        sut.decrement()
        XCTAssertEqual(sut.count, 4)
    }
}
```

### Snapshot Testing (swift-snapshot-testing)
```swift
import SnapshotTesting
import SwiftUI

final class ButtonSnapshotTests: XCTestCase {
    func test_primaryButton_lightMode() {
        let view = AppButton("Click Me", style: .primary) {}
            .frame(width: 200)

        assertSnapshot(of: view, as: .image)
    }

    func test_primaryButton_darkMode() {
        let view = AppButton("Click Me", style: .primary) {}
            .frame(width: 200)
            .preferredColorScheme(.dark)

        assertSnapshot(of: view, as: .image)
    }

    func test_buttonStates() {
        let states: [(String, AppButton.Style)] = [
            ("primary", .primary),
            ("secondary", .secondary),
            ("ghost", .ghost),
            ("destructive", .destructive)
        ]

        for (name, style) in states {
            let view = AppButton("Button", style: style) {}
                .frame(width: 200)

            assertSnapshot(of: view, as: .image, named: name)
        }
    }
}
```

## UI Testing (XCUITest)

### Basic UI Test
```swift
import XCUITest

final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func test_login_withValidCredentials_showsHomeScreen() {
        // Find and fill email field
        let emailField = app.textFields["emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("test@example.com")

        // Find and fill password field
        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText("password123")

        // Tap login button
        app.buttons["loginButton"].tap()

        // Verify home screen appears
        let homeTitle = app.staticTexts["Welcome"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 10))
    }

    func test_login_withInvalidCredentials_showsError() {
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText("wrong@example.com")

        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")

        app.buttons["loginButton"].tap()

        let errorMessage = app.staticTexts["Invalid credentials"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
}
```

### Page Object Pattern
```swift
// Page object
struct LoginPage {
    let app: XCUIApplication

    var emailField: XCUIElement {
        app.textFields["emailTextField"]
    }

    var passwordField: XCUIElement {
        app.secureTextFields["passwordTextField"]
    }

    var loginButton: XCUIElement {
        app.buttons["loginButton"]
    }

    var errorMessage: XCUIElement {
        app.staticTexts["errorLabel"]
    }

    func login(email: String, password: String) {
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
    }
}

// Usage in test
func test_login_flow() {
    let loginPage = LoginPage(app: app)
    loginPage.login(email: "test@example.com", password: "password123")

    XCTAssertTrue(HomePage(app: app).welcomeLabel.waitForExistence(timeout: 5))
}
```

## Test Doubles

### Types of Test Doubles
```swift
// Dummy: Passed but never used
class DummyLogger: LoggerProtocol {
    func log(_ message: String) { }
}

// Stub: Provides canned answers
class StubUserRepository: UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> User {
        return User(id: id, name: "Stub User")
    }
}

// Spy: Records interactions
class SpyAnalytics: AnalyticsProtocol {
    var trackedEvents: [String] = []

    func track(_ event: String) {
        trackedEvents.append(event)
    }
}

// Mock: Verifies expectations
class MockPaymentService: PaymentServiceProtocol {
    var processPaymentCalled = false
    var expectedAmount: Decimal?

    func processPayment(amount: Decimal) async throws {
        processPaymentCalled = true
        if let expected = expectedAmount {
            assert(amount == expected, "Unexpected amount")
        }
    }
}

// Fake: Working implementation (simplified)
class FakeDatabase: DatabaseProtocol {
    private var storage: [String: Any] = [:]

    func save(_ value: Any, forKey key: String) {
        storage[key] = value
    }

    func get(forKey key: String) -> Any? {
        storage[key]
    }
}
```

## TDD Workflow

### Red-Green-Refactor
```swift
// 1. RED: Write failing test
func test_calculator_add_returnsSumOfTwoNumbers() {
    let calculator = Calculator()
    let result = calculator.add(2, 3)
    XCTAssertEqual(result, 5) // Fails - Calculator doesn't exist
}

// 2. GREEN: Write minimal code to pass
struct Calculator {
    func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }
}

// 3. REFACTOR: Improve code while tests pass
// (In this case, code is already clean)
```

## Testing Checklist

### Unit Tests
- [ ] All public methods tested
- [ ] Edge cases covered
- [ ] Error cases tested
- [ ] Async behavior tested
- [ ] Mock dependencies properly

### Integration Tests
- [ ] Component interactions work
- [ ] Data flow is correct
- [ ] Error propagation works

### UI Tests
- [ ] Critical user flows covered
- [ ] Accessibility identifiers set
- [ ] Different screen sizes
- [ ] Dark mode (if applicable)

### Performance
- [ ] No memory leaks
- [ ] Acceptable response times
- [ ] Proper cleanup in tearDown

## Remember

- Test behavior, not implementation
- Keep tests independent
- Use descriptive test names
- One assertion per test (when practical)
- Mock external dependencies
- Run tests frequently
- Maintain test code quality
