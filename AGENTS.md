# Repository Guidelines

Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repo hosts StreamCore, the internal Swift SDK that provides shared low-level infrastructure — WebSocket client, retry/backoff logic, logging and monitoring, dependency injection, attachment uploads, user models, and **StreamCoreUI** (shared appearance tokens) — for Stream's product SDKs (StreamFeeds, StreamChat, StreamVideo). It is not designed for direct customer use and does not follow semantic versioning.

### Tech & toolchain

- Language: Swift 6.0 (strict concurrency enabled — `swift-tools-version:6.0`)
- Primary distribution: Swift Package Manager (SPM)
- Project file: `StreamCore.xcodeproj` (used for builds and tests)
- Xcode: 16.x or newer (Apple Silicon supported)
- Platforms / deployment targets: iOS 13+ (see `Package.swift`; do not lower targets without approval)
- CI: GitHub Actions + Fastlane (see `.github/workflows/smoke-checks.yml`)
- Linting: SwiftLint (v0.59.1) — config in `.swiftlint.yml`
- Formatting: SwiftFormat (v0.58.2) — config in `.swiftformat`
- Tool versions are pinned in `Githubfile`

### Project layout (high level)

```
Sources/
  StreamCore/              # Core client: WebSocket, retry, logging, DI, models
  StreamCoreUI/            # Shared UI tokens (design system, CDN helpers)
    DesignSystem/          # DesignSystemTokens (colors, layout, fonts)
  StreamAttachments/       # Attachment upload feature module
Tests/
  StreamCoreTests/
  StreamCoreUITests/
  StreamAttachmentsTests/
fastlane/                  # Fastlane lanes for CI
Scripts/                   # Helper scripts
```

### New files & target membership

When creating new source or resource files, add them to the correct Xcode target(s). Update the project (e.g. `project.pbxproj`) so each new file is included in the appropriate target's "Compile Sources" (or "Copy Bundle Resources" for assets). Match the target(s) used by sibling files in the same directory. Omitting target membership will cause build failures or unused files.

### Local setup (SPM)

1. Open the repository in Xcode (root contains `Package.swift` and `StreamCore.xcodeproj`).
2. Resolve packages.
3. Choose an iOS Simulator (e.g., iPhone 17 Pro) and Build.

### Schemes

Available shared schemes (under `StreamCore.xcodeproj/xcshareddata/xcschemes/`):

- `StreamCore` — builds the core framework
- `StreamCoreUI` — builds the shared UI framework
- `StreamAttachments` — builds the attachments feature module

Agents must query existing schemes before invoking xcodebuild.

### Build & test commands (CLI)

Build (Debug):

```
xcodebuild \
  -project StreamCore.xcodeproj \
  -scheme StreamCoreUI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

Run tests:

```
bundle exec fastlane test
```

### Linting & formatting

SwiftFormat (strict):

```
bundle exec fastlane run_swift_format strict:true
```

Respect `.swiftlint.yml` and `.swiftformat` rules. Do not broadly disable rules; scope exceptions and justify in PRs.

## StreamCoreUI design system

Shared design tokens live on ``DesignSystemTokens``. Product SDKs pass the same instance into their appearance types so Chat and Video reskin together.

### Types and ownership

- **`DesignSystemTokens`**: `colors` (semantic + `palette`), `layout` (spacing, radii, strokes, elevations), and `fonts` (shared SwiftUI typography). Colors use UIKit `UIColor`; fonts use SwiftUI `Font`. UIKit `UIFont` faces stay on product UIKit SDKs (for example StreamChatUI), not in Core.
- **Product tokens** stay on each SDK: `VideoAppearance.colors`, `ChatAppearance.colors`. Do not add `chat*` or Video-only tokens here.
- **Icons and images** stay on each SDK until a follow-up.

Token split rules and re-sync steps: `Sources/StreamCoreUI/DesignSystem/TokenScope.md`.

```swift
let tokens = DesignSystemTokens()
tokens.colors.palette.brand500 = .red
tokens.layout.spacingMd = 16
tokens.fonts.body = .body

let videoAppearance = VideoAppearance(tokens: tokens) // Video SDK
let chatAppearance = ChatAppearance(tokens: tokens)     // Chat SDK
```

### Fonts

- Shared typography lives on `DesignSystemTokens.fonts` as SwiftUI `Font` (caption through title, bold/italic variants, emoji).
- Style names match Chat (`Appearance.FontsSwiftUI`) and Video (`Fonts`).
- Product SDKs read shared fonts from `appearance.tokens.fonts`. Video views still use legacy `Appearance.fonts` until they migrate.
- UIKit `UIFont` faces stay on product UIKit SDKs (for example StreamChatUI); do not add them to Core.
- Font tests live under `Tests/StreamCoreUITests/DesignSystem/`.

### Linking

- `StreamCoreUI` depends on `StreamCore`.
- Product SDKs depend on `StreamCoreUI` for tokens; do not duplicate-link `StreamCore` into SwiftUI-only targets when `StreamCoreUI` already pulls it in.

### Constraints

- `UIColor(light:dark:)` stays `internal`; Chat has its own public helper.
- Danger `commit_lint` fails commit subjects that end with a period.
- Do not change release versioning or customer-facing changelogs unless explicitly asked.

### Development guidelines

Code documentation

- Write doc comments (`///`) only for `public` declarations — types, methods, and properties that are part of the SDK's public API.
- Do not add doc comments to `internal`, `private`, or test code.
- Keep doc comments concise: a one-line summary; add parameter/return docs only when they are not obvious from the signature.
- Do not add inline comments narrating what the code or a change does; comment only non-obvious constraints or reasoning.

Testing policy

- Add/extend tests in the matching module's `Tests/` folder (mirrors the source directory structure).
- Name new test files with the pattern `…_Tests.swift`.
- Use `subject` as the name of the subject under test.
- Prefer instance properties that are explicitly unwrapped which you nullify on tearDown.
- Do not test private methods; test through public behavior.

### Branching & commits

- The default integration branch is `develop`. Feature branches merge into `develop`.
- Name branches with a descriptive kebab-case prefix, e.g. `fix/retry-backoff`.
- Commits: small, focused, imperative subject lines. Start with a capital letter; do not end with a period.
- Do **not** include ticket IDs in commit subjects. Link tickets from the PR instead.

### Pull Requests

- Use the GitHub CLI to create a PR and use the Linear MCP to link the relevant issue.
- Base branch is `develop`.
- Before opening a PR: build affected schemes, run tests, `bundle exec fastlane run_swift_format strict:true`.

### Security & credentials

- Never commit API keys or customer data.
- If you add scripts, ensure they fail closed on missing env vars.

### Compatibility

- Maintain compatibility with supported iOS versions listed in `Package.swift`.
- Don't introduce third-party deps without discussion.
- Validate SPM integration when changing module boundaries.
