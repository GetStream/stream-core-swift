# Token scope

The `design-system-tokens` repository owns token classification and emits
separate Swift artifacts for Core, Chat, and Video.

- `tokens/core` contains shared foundations, primitives, semantics, and
  components.
- `tokens/chat` contains Chat-specific semantics and components.
- `tokens/video` contains Video-specific semantics and components.

StreamCoreUI consumes only the generated files under `build/ios/core`.
Product tokens live on their SDK appearance types and derive values from the
same `DesignSystemTokens` instance.

## Re-syncing

From a sibling `design-system-tokens` checkout, run:

```sh
IOS_CORE_OUTPUT_DIR=../stream-core-swift/Sources/StreamCoreUI/DesignSystem \
  npm run build:ios
```

This updates:

- `DesignSystemTokens+Colors+Palette.swift`
- `DesignSystemTokens+Colors.swift`
- `DesignSystemTokens+Layout.swift`
- `UIColor+Primitives.swift`

Run SwiftFormat after syncing. Typography remains hand-authored in
`DesignSystemTokens+Fonts.swift` because Core exposes SwiftUI `Font` values
rather than generated UIKit fonts.

## Product appearances

Shared tokens are configured on `DesignSystemTokens` and passed into each SDK:

```swift
let tokens = DesignSystemTokens()
tokens.colors.accentPrimary = .red
let videoAppearance = VideoAppearance(tokens: tokens)
let chatAppearance = ChatAppearance(tokens: tokens)
```

Video-only and Chat-only tokens are available through their respective
appearance types. UIKit font faces remain in product UIKit SDKs.
