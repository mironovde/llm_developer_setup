---
name: swift-macos
description: macOS app development with Swift and SwiftUI. Covers AppKit integration, macOS-specific APIs, menu bars, keyboard shortcuts, and desktop UX patterns. Use for any macOS-targeted development.
user-invocable: true
argument-hint: "[macOS feature or component]"
---

# macOS Development Skill

You are an expert macOS developer. Your role is to build high-quality macOS applications that feel native and follow Apple's macOS Human Interface Guidelines.

## macOS Development Principles

### Desktop-First Design
- Leverage window management
- Support keyboard navigation
- Use menu bar effectively
- Implement proper toolbar
- Support drag and drop

### macOS-Specific Considerations
- Multiple window support
- Full screen and split view
- Keyboard shortcuts
- Touch Bar (older Macs)
- Menu bar apps
- System extensions

## Architecture Patterns

### Document-Based Apps
```swift
@main
struct MyDocumentApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MyDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") {
                    // Custom new document action
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

struct MyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
```

### Menu Bar Apps
```swift
@main
struct MenuBarApp: App {
    @State private var isMenuPresented = false

    var body: some Scene {
        MenuBarExtra("My App", systemImage: "star.fill") {
            VStack {
                Text("Status: Active")
                Divider()
                Button("Open Settings") {
                    // Open settings
                }
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
```

## SwiftUI for macOS

### Window Management
```swift
struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack {
            Button("Open New Window") {
                openWindow(id: "detail")
            }
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        WindowGroup(id: "detail") {
            DetailView()
        }
        .defaultSize(width: 400, height: 300)

        Window("Inspector", id: "inspector") {
            InspectorView()
        }
        .defaultPosition(.trailing)
        .defaultSize(width: 200, height: 400)
    }
}
```

### Sidebar Navigation
```swift
struct ContentView: View {
    @State private var selection: Panel? = .library

    enum Panel: Hashable {
        case library
        case favorites
        case settings
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Library", systemImage: "books.vertical")
                    .tag(Panel.library)
                Label("Favorites", systemImage: "star")
                    .tag(Panel.favorites)
                Label("Settings", systemImage: "gear")
                    .tag(Panel.settings)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selection {
            case .library:
                LibraryView()
            case .favorites:
                FavoritesView()
            case .settings:
                SettingsView()
            case nil:
                Text("Select an item")
            }
        }
    }
}
```

### Toolbar
```swift
struct ContentView: View {
    @State private var searchText = ""

    var body: some View {
        List {
            // Content
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: addItem) {
                    Label("Add", systemImage: "plus")
                }

                Button(action: removeItem) {
                    Label("Remove", systemImage: "minus")
                }
            }

            ToolbarItem(placement: .automatic) {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
        }
        .searchable(text: $searchText)
    }
}
```

## Keyboard Shortcuts

### Custom Commands
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Custom") {
                Button("Do Something") {
                    // Action
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Divider()

                Button("Another Action") {
                    // Action
                }
                .keyboardShortcut("a", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("New from Template") {
                    // Action
                }
                .keyboardShortcut("n", modifiers: [.command, .option])
            }
        }
    }
}
```

### Focus and Navigation
```swift
struct ContentView: View {
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, email, message
    }

    var body: some View {
        Form {
            TextField("Name", text: $name)
                .focused($focusedField, equals: .name)

            TextField("Email", text: $email)
                .focused($focusedField, equals: .email)

            TextEditor(text: $message)
                .focused($focusedField, equals: .message)
        }
        .onSubmit {
            switch focusedField {
            case .name:
                focusedField = .email
            case .email:
                focusedField = .message
            case .message, nil:
                submit()
            }
        }
    }
}
```

## macOS APIs

### File System Access
```swift
func openFile() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [.plainText, .json]

    if panel.runModal() == .OK {
        guard let url = panel.url else { return }
        // Process file
    }
}

func saveFile(content: String) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue = "Untitled.txt"

    if panel.runModal() == .OK {
        guard let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
```

### System Services
```swift
// Notifications
func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
    )

    UNUserNotificationCenter.current().add(request)
}

// Clipboard
func copyToClipboard(_ string: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
}

func pasteFromClipboard() -> String? {
    NSPasteboard.general.string(forType: .string)
}
```

### Drag and Drop
```swift
struct DroppableView: View {
    @State private var isTargeted = false

    var body: some View {
        Rectangle()
            .fill(isTargeted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            .dropDestination(for: URL.self) { urls, location in
                handleDrop(urls)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
    }
}

struct DraggableItem: View {
    let item: Item

    var body: some View {
        Text(item.title)
            .draggable(item.url)
    }
}
```

## Settings/Preferences

```swift
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Form {
            Toggle("Show in Dock", isOn: $showInDock)
            Toggle("Launch at Login", isOn: $launchAtLogin)
        }
        .padding()
    }
}
```

## Project Structure

```
MyMacApp/
├── App/
│   ├── MyMacApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Main/
│   │   ├── MainView.swift
│   │   └── MainViewModel.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── MenuBar/
│       └── MenuBarView.swift
├── Core/
│   ├── Services/
│   ├── Storage/
│   └── Extensions/
├── UI/
│   ├── Components/
│   └── Styles/
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
```

## Human Interface Guidelines (macOS)

### Window Design
- Standard window chrome
- Toolbar when appropriate
- Sidebar for navigation
- Inspector for details

### Interaction
- Full keyboard support
- Right-click context menus
- Drag and drop
- Undo/redo support

### Typography
- System fonts
- Proper hierarchy
- Readable sizes

## Remember

- Support keyboard navigation
- Implement standard menus
- Handle multiple windows
- Support full screen
- Use native controls
- Test on different macOS versions
