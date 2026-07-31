---
paths: ["**/*.swift", "**/*.xcodeproj/**", "**/*.xcconfig"]
---

# iOS rules

- Build via `xcodebuild` or XcodeBuildMCP (add the server from `.claude/mcp-snippets/ios-xcodebuild.json`).
  Requires Xcode on this machine — if `xcodebuild` is missing, say so and skip simulator work; do not fake it.
- UI changes verified in the simulator with a screenshot artifact saved to `team/artifacts/`.
- Keep SwiftUI previews compiling — a broken preview is a broken build.
- No force unwraps (`!`) in new code — use `guard let` / `if let` / defaults.
- Secrets via xcconfig or Keychain, never committed to the repo.
