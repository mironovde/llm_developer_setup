---
name: swift-vapor
description: Server-side Swift development with Vapor framework. Covers API design, Fluent ORM, authentication, middleware, deployment, and backend best practices. Use for any Vapor backend development.
user-invocable: true
argument-hint: "[API or backend feature]"
---

# Vapor Backend Development Skill

You are an expert Vapor developer. Your role is to build high-quality server-side Swift applications with clean APIs, proper authentication, and robust data handling.

## Vapor Development Principles

### API-First Design
- RESTful conventions
- Clear endpoint naming
- Proper HTTP methods
- Consistent responses

### Security
- Input validation
- Authentication/Authorization
- Rate limiting
- SQL injection prevention

### Performance
- Efficient queries
- Proper caching
- Connection pooling
- Async everywhere

## Project Setup

### Package.swift
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyAPI",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT", package: "jwt"),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        ),
    ]
)
```

### Configuration
```swift
// configure.swift
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    // Database
    app.databases.use(
        .postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor",
            password: Environment.get("DATABASE_PASSWORD") ?? "password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        ),
        as: .psql
    )

    // Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())

    // Middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // Routes
    try routes(app)
}
```

## Models and Fluent

### Model Definition
```swift
import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "name")
    var name: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$user)
    var tokens: [Token]

    @Children(for: \.$author)
    var posts: [Post]

    init() {}

    init(id: UUID? = nil, email: String, passwordHash: String, name: String) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
    }
}

extension User {
    struct Public: Content {
        let id: UUID
        let email: String
        let name: String
        let createdAt: Date?
    }

    var asPublic: Public {
        Public(id: id!, email: email, name: name, createdAt: createdAt)
    }
}
```

### Migration
```swift
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("name", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

## Authentication

### JWT Authentication
```swift
import JWT
import Vapor

struct UserPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var userId: UUID

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

struct JWTAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload = try request.jwt.verify(bearer.token, as: UserPayload.self)

        guard let user = try await User.find(payload.userId, on: request.db) else {
            return
        }

        request.auth.login(user)
    }
}

// Usage in routes
func protectedRoutes(_ app: Application) throws {
    let protected = app.grouped(JWTAuthenticator())
        .grouped(User.guardMiddleware())

    protected.get("me") { req -> User.Public in
        let user = try req.auth.require(User.self)
        return user.asPublic
    }
}
```

### Password Hashing
```swift
import Vapor

extension User {
    static func create(
        email: String,
        password: String,
        name: String,
        on db: Database
    ) async throws -> User {
        let passwordHash = try Bcrypt.hash(password)
        let user = User(email: email, passwordHash: passwordHash, name: name)
        try await user.save(on: db)
        return user
    }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

## Controllers and Routes

### RESTful Controller
```swift
import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        // Public routes
        users.post("register", use: register)
        users.post("login", use: login)

        // Protected routes
        let protected = users.grouped(JWTAuthenticator())
            .grouped(User.guardMiddleware())

        protected.get("me", use: me)
        protected.put("me", use: update)
        protected.delete("me", use: delete)
    }

    // MARK: - Handlers

    func register(req: Request) async throws -> User.Public {
        try RegisterRequest.validate(content: req)
        let input = try req.content.decode(RegisterRequest.self)

        // Check for existing user
        guard try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() == nil else {
            throw Abort(.conflict, reason: "Email already registered")
        }

        let user = try await User.create(
            email: input.email,
            password: input.password,
            name: input.name,
            on: req.db
        )

        return user.asPublic
    }

    func login(req: Request) async throws -> TokenResponse {
        try LoginRequest.validate(content: req)
        let input = try req.content.decode(LoginRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard try user.verify(password: input.password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        let token = try generateToken(for: user, on: req)
        return TokenResponse(token: token)
    }

    func me(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return user.asPublic
    }

    func update(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(UpdateUserRequest.self)

        if let name = input.name {
            user.name = name
        }

        try await user.save(on: req.db)
        return user.asPublic
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        try await user.delete(on: req.db)
        return .noContent
    }
}
```

### DTOs and Validation
```swift
import Vapor

struct RegisterRequest: Content, Validatable {
    let email: String
    let password: String
    let name: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("name", as: String.self, is: !.empty)
    }
}

struct LoginRequest: Content, Validatable {
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}

struct TokenResponse: Content {
    let token: String
}
```

## Error Handling

```swift
enum AppError: AbortError {
    case userNotFound
    case invalidCredentials
    case emailTaken
    case validationFailed(String)

    var status: HTTPResponseStatus {
        switch self {
        case .userNotFound: return .notFound
        case .invalidCredentials: return .unauthorized
        case .emailTaken: return .conflict
        case .validationFailed: return .badRequest
        }
    }

    var reason: String {
        switch self {
        case .userNotFound: return "User not found"
        case .invalidCredentials: return "Invalid credentials"
        case .emailTaken: return "Email already taken"
        case .validationFailed(let message): return message
        }
    }
}

struct ErrorResponse: Content {
    let error: Bool
    let reason: String
}

struct CustomErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let abort as AbortError {
            let response = ErrorResponse(error: true, reason: abort.reason)
            return try await response.encodeResponse(status: abort.status, for: request)
        }
    }
}
```

## Testing

```swift
@testable import App
import XCTVapor

final class UserTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }

    override func tearDown() async throws {
        try await app.autoRevert()
        app.shutdown()
    }

    func testRegister() async throws {
        let input = RegisterRequest(
            email: "test@example.com",
            password: "password123",
            name: "Test User"
        )

        try app.test(.POST, "users/register", beforeRequest: { req in
            try req.content.encode(input)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let user = try res.content.decode(User.Public.self)
            XCTAssertEqual(user.email, input.email)
            XCTAssertEqual(user.name, input.name)
        })
    }

    func testLogin() async throws {
        // First register
        let user = try await User.create(
            email: "test@example.com",
            password: "password123",
            name: "Test",
            on: app.db
        )

        let input = LoginRequest(email: user.email, password: "password123")

        try app.test(.POST, "users/login", beforeRequest: { req in
            try req.content.encode(input)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let response = try res.content.decode(TokenResponse.self)
            XCTAssertFalse(response.token.isEmpty)
        })
    }
}
```

## Project Structure

```
MyAPI/
├── Sources/
│   └── App/
│       ├── configure.swift
│       ├── routes.swift
│       ├── Controllers/
│       │   ├── UserController.swift
│       │   └── PostController.swift
│       ├── Models/
│       │   ├── User.swift
│       │   ├── Post.swift
│       │   └── Token.swift
│       ├── Migrations/
│       │   ├── CreateUser.swift
│       │   └── CreatePost.swift
│       ├── DTOs/
│       │   ├── UserDTOs.swift
│       │   └── PostDTOs.swift
│       ├── Middleware/
│       │   └── ErrorMiddleware.swift
│       └── Services/
│           └── TokenService.swift
├── Tests/
│   └── AppTests/
│       └── UserTests.swift
├── Package.swift
├── Dockerfile
└── docker-compose.yml
```

## Deployment

### Dockerfile
```dockerfile
FROM swift:5.9-jammy as builder
WORKDIR /app
COPY . .
RUN swift build -c release

FROM swift:5.9-jammy-slim
WORKDIR /app
COPY --from=builder /app/.build/release/App .
COPY --from=builder /app/Public ./Public
EXPOSE 8080
CMD ["./App", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
```

### docker-compose.yml
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_HOST=db
      - DATABASE_NAME=vapor
      - DATABASE_USERNAME=vapor
      - DATABASE_PASSWORD=password
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=vapor
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=vapor
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Remember

- Validate all inputs
- Use proper authentication
- Handle errors gracefully
- Write comprehensive tests
- Use async/await everywhere
- Follow RESTful conventions
