---
name: ios-simulator
description: Controls iOS Simulator for automated UI testing, screenshots, accessibility inspection, and app interaction. Enables AI-driven mobile app testing without manual intervention.
user-invocable: true
argument-hint: "[action: screenshot|tap|swipe|type|inspect|launch]"
---

# iOS Simulator Automation

You are the iOS Simulator Controller. Your role is to automate iOS app testing by controlling simulators, capturing screenshots, inspecting UI elements, and simulating user interactions.

## Prerequisites

Ensure these are installed:
- macOS with Xcode
- iOS Simulator (via Xcode)
- Node.js (for MCP server)

### MCP Server Setup

Add to `.mcp.json`:
```json
{
  "mcpServers": {
    "ios-simulator": {
      "type": "stdio",
      "command": "npx",
      "args": ["ios-simulator-mcp"]
    }
  }
}
```

Install: `npm install -g ios-simulator-mcp`

## Available Actions

### 1. List Simulators
```bash
xcrun simctl list devices
```

### 2. Boot Simulator
```bash
xcrun simctl boot "iPhone 16"
```

### 3. Take Screenshot
```bash
xcrun simctl io booted screenshot /path/to/screenshot.png
```

### 4. Launch App
```bash
xcrun simctl launch booted com.example.app
```

### 5. Install App
```bash
xcrun simctl install booted /path/to/App.app
```

### 6. Terminate App
```bash
xcrun simctl terminate booted com.example.app
```

## MCP Tools (after setup)

When MCP server is running, these tools become available:

| Tool | Description |
|------|-------------|
| `ios_simulator_list` | List available simulators |
| `ios_simulator_screenshot` | Capture current screen |
| `ios_simulator_tap` | Tap at coordinates (x, y) |
| `ios_simulator_swipe` | Swipe from (x1,y1) to (x2,y2) |
| `ios_simulator_type` | Type text into focused field |
| `ios_simulator_ui_tree` | Get accessibility tree |
| `ios_simulator_launch_app` | Launch app by bundle ID |

## Testing Workflow

### 1. Setup
```
1. Boot simulator
2. Install app
3. Launch app
4. Wait for app ready
```

### 2. Test Execution
```
1. Take baseline screenshot
2. Perform action (tap/swipe/type)
3. Wait for UI update
4. Take result screenshot
5. Inspect accessibility tree
6. Verify expected state
```

### 3. Cleanup
```
1. Terminate app
2. (Optional) Shutdown simulator
```

## UI Inspection

### Get Accessibility Tree
Use `ios_simulator_ui_tree` to get structured UI information:

```json
{
  "elements": [
    {
      "type": "Button",
      "label": "Submit",
      "frame": {"x": 100, "y": 200, "width": 80, "height": 44},
      "enabled": true
    }
  ]
}
```

### Find Element by Text
1. Get accessibility tree
2. Search for element with matching label
3. Extract coordinates from frame
4. Use for tap/interaction

## Interaction Patterns

### Tap Button by Label
```
1. Get UI tree
2. Find element with label "Button Text"
3. Calculate center: x = frame.x + width/2, y = frame.y + height/2
4. Tap at (x, y)
```

### Enter Text in Field
```
1. Tap on text field to focus
2. Use type action with text
3. (Optional) Tap "Done" or "Return"
```

### Scroll to Element
```
1. Get UI tree
2. If element not visible, swipe up/down
3. Repeat until element appears
4. Interact with element
```

## Swift Integration

### XCUITest vs Simulator Control

| Aspect | XCUITest | Simulator MCP |
|--------|----------|---------------|
| Setup | Test target in Xcode | MCP server |
| Speed | Fast (in-process) | Medium (IPC) |
| Flexibility | Code-based | AI-driven |
| Use case | CI/CD pipelines | Exploratory testing |

### Combining Both
```swift
// Use XCUITest for stable flows
func testLoginFlow() {
    let app = XCUIApplication()
    app.launch()
    app.textFields["email"].tap()
    // ...
}

// Use Simulator MCP for:
// - Visual regression testing
// - Accessibility audits
// - Ad-hoc testing via AI
```

## Common Commands Reference

```bash
# Simulator lifecycle
xcrun simctl boot "iPhone 16"
xcrun simctl shutdown booted
xcrun simctl erase booted

# App management
xcrun simctl install booted ./App.app
xcrun simctl launch booted com.bundle.id
xcrun simctl terminate booted com.bundle.id
xcrun simctl uninstall booted com.bundle.id

# Screenshot & video
xcrun simctl io booted screenshot output.png
xcrun simctl io booted recordVideo output.mp4

# UI appearance
xcrun simctl ui booted appearance dark
xcrun simctl ui booted appearance light

# Open URL (deep linking)
xcrun simctl openurl booted "myapp://path/to/screen"

# Push notification
xcrun simctl push booted com.bundle.id payload.json

# Privacy permissions
xcrun simctl privacy booted grant photos com.bundle.id
xcrun simctl privacy booted revoke camera com.bundle.id

# Location simulation
xcrun simctl location booted set 37.7749,-122.4194
```

## Test Report Format

```markdown
## iOS UI Test Report: [Test Name]

### Environment
- Simulator: iPhone 16
- iOS Version: 18.0
- App: com.example.app v1.0

### Test Steps

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Launch app | Home screen | Home screen | ✅ |
| 2 | Tap "Login" | Login form | Login form | ✅ |
| 3 | Enter email | Field filled | Field filled | ✅ |
| 4 | Tap "Submit" | Success msg | Error msg | ❌ |

### Screenshots
- [baseline.png] - Initial state
- [step2.png] - After login tap
- [final.png] - End state

### Accessibility Audit
- Missing labels: 2 buttons
- Small touch targets: 1 element
- VoiceOver compatible: Yes

### Verdict
- [ ] **PASSED** - All tests green
- [x] **FAILED** - Issues found
```

## Troubleshooting

### Simulator Won't Boot
```bash
xcrun simctl shutdown all
xcrun simctl erase all
# Then try booting again
```

### App Won't Install
- Verify .app is built for simulator (not device)
- Check bundle ID matches
- Try `xcrun simctl erase booted` first

### Tap Not Working
- Verify coordinates are within screen bounds
- Add delay after tap for UI to update
- Check if element is enabled/interactive

## Integration with Swift Testing Workflow

1. Build app: `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' build`
2. Boot simulator and install
3. Run automated UI checks via MCP
4. Capture screenshots for visual regression
5. Generate accessibility report
6. Clean up simulator state
