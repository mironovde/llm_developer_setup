---
name: swift-ui-design
description: SwiftUI design patterns and modern UI/UX best practices. Covers component design, animations, accessibility, design tokens, and visual hierarchy. Use for any SwiftUI interface design.
user-invocable: true
argument-hint: "[UI component or design task]"
---

# SwiftUI Design Skill

You are an expert SwiftUI designer. Your role is to create beautiful, accessible, and user-friendly interfaces following Apple's Human Interface Guidelines and modern design principles.

## Design Principles

### User-Centered Design
- Understand user needs first
- Design for the common case
- Make interactions intuitive
- Provide clear feedback

### Visual Hierarchy
- Guide user attention
- Use size, color, spacing
- Group related elements
- Create clear focal points

### Consistency
- Reuse components
- Maintain patterns
- Follow platform conventions
- Use design tokens

## Design Token System

### Color Tokens
```swift
extension Color {
    // Brand colors
    static let brandPrimary = Color("BrandPrimary")
    static let brandSecondary = Color("BrandSecondary")

    // Semantic colors
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let border = Color("Border")

    // Status colors
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let info = Color("Info")
}

// Assets.xcassets structure:
// Colors/
// ├── BrandPrimary.colorset (with Any/Dark appearances)
// ├── TextPrimary.colorset
// └── ...
```

### Typography Tokens
```swift
extension Font {
    // Headlines
    static let displayLarge = Font.system(size: 34, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let displaySmall = Font.system(size: 22, weight: .bold)

    // Titles
    static let titleLarge = Font.system(size: 20, weight: .semibold)
    static let titleMedium = Font.system(size: 17, weight: .semibold)
    static let titleSmall = Font.system(size: 15, weight: .semibold)

    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // Labels
    static let labelLarge = Font.system(size: 15, weight: .medium)
    static let labelMedium = Font.system(size: 13, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
}
```

### Spacing Tokens
```swift
enum Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}
```

### Corner Radius Tokens
```swift
enum CornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let full: CGFloat = 9999
}
```

## Component Design

### Button Component
```swift
struct AppButton: View {
    enum Style {
        case primary, secondary, ghost, destructive
    }

    enum Size {
        case small, medium, large

        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }

        var font: Font {
            switch self {
            case .small: return .labelMedium
            case .medium: return .labelLarge
            case .large: return .titleSmall
            }
        }
    }

    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }
                Text(title)
                    .font(size.font)
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay {
                if style == .secondary || style == .ghost {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(borderColor, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .brandPrimary
        case .secondary: return .clear
        case .ghost: return .clear
        case .destructive: return .error
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .brandPrimary
        case .ghost: return .textPrimary
        case .destructive: return .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .destructive: return .clear
        case .secondary: return .brandPrimary
        case .ghost: return .border
        }
    }
}
```

### Card Component
```swift
struct AppCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(
        padding: CGFloat = Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
```

### Input Field Component
```swift
struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let error: String?
    let isSecure: Bool

    @FocusState private var isFocused: Bool

    init(
        _ label: String,
        placeholder: String = "",
        text: Binding<String>,
        error: String? = nil,
        isSecure: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.error = error
        self.isSecure = isSecure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.labelMedium)
                .foregroundStyle(Color.textSecondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.bodyLarge)
            .padding(.horizontal, Spacing.md)
            .frame(height: 48)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .focused($isFocused)

            if let error {
                Text(error)
                    .font(.labelSmall)
                    .foregroundStyle(Color.error)
            }
        }
    }

    private var borderColor: Color {
        if error != nil {
            return .error
        }
        return isFocused ? .brandPrimary : .border
    }
}
```

## Animations

### Micro-interactions
```swift
struct AnimatedButton: View {
    @State private var isPressed = false

    var body: some View {
        Button(action: {}) {
            Text("Tap Me")
                .padding()
                .background(Color.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

### Loading States
```swift
struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1.0 : 0.3)

            Text("Loading...")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                isAnimating = true
            }
        }
    }
}
```

### Transitions
```swift
struct ContentView: View {
    @State private var showDetail = false

    var body: some View {
        VStack {
            if showDetail {
                DetailView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.3), value: showDetail)
    }
}
```

## Accessibility

### VoiceOver Support
```swift
struct AccessibleCard: View {
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.titleMedium)
                Text(description)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Dynamic Type
```swift
struct ScalableText: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack {
            Text("Headline")
                .font(.headline)

            Text("Body text that scales with user preference")
                .font(.body)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
        }
    }
}
```

### Color Contrast
```swift
// Ensure WCAG 2.1 AA compliance (4.5:1 for text, 3:1 for large text)
extension Color {
    static let accessibleTextOnPrimary = Color.white // Tested for contrast
    static let accessibleTextOnBackground = Color("AccessibleText")
}
```

## Responsive Design

### Adaptive Layouts
```swift
struct AdaptiveLayout: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            VStack {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }

    var content: some View {
        Group {
            ItemView()
            ItemView()
            ItemView()
        }
    }
}
```

### Safe Area Handling
```swift
struct SafeAreaView: View {
    var body: some View {
        VStack {
            // Content
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom bar that respects safe area
            BottomBar()
                .padding()
                .background(.ultraThinMaterial)
        }
    }
}
```

## Dark Mode

```swift
struct ThemedView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Adapts to theme")
                .foregroundStyle(Color.textPrimary) // Uses semantic color

            // For special cases
            Image(colorScheme == .dark ? "logoDark" : "logoLight")
        }
        .background(Color.background)
    }
}
```

## Design Checklist

Before shipping UI:

### Visual
- [ ] Consistent spacing (use tokens)
- [ ] Proper typography hierarchy
- [ ] Color contrast meets WCAG AA
- [ ] Dark mode tested
- [ ] Loading states designed
- [ ] Empty states designed
- [ ] Error states designed

### Interaction
- [ ] Touch targets ≥ 44pt
- [ ] Feedback on interactions
- [ ] Smooth animations
- [ ] No jarring transitions
- [ ] Keyboard navigation (macOS)

### Accessibility
- [ ] VoiceOver tested
- [ ] Dynamic Type tested
- [ ] Color not only indicator
- [ ] Proper labels
- [ ] Semantic structure

### Platform
- [ ] Safe area respected
- [ ] Different device sizes
- [ ] Orientation changes
- [ ] Platform conventions

## Remember

- Design tokens create consistency
- Accessibility is not optional
- Animation enhances UX
- Test on real devices
- Follow platform conventions
- Simple > complex
