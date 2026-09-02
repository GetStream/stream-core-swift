# Token scope

The `design-system-tokens` generator emits one flat Swift file covering every
Stream product. This module carries only the part every SDK draws from, on
``DesignSystemTokens`` (`colors` and `layout`; fonts will be a later group).
Product-specific colors and layout live on each SDK's appearance
(`VideoAppearance.colors`, `ChatAppearance.colors`). The split is applied
by hand, so this note is what makes a re-sync repeatable.

## Re-syncing

1. Take the generated palette and layout tokens.
2. Remove the product groups listed below and keep the remainder here, in
   `DesignSystemTokens.Colors` (semantic tokens plus `palette`) and
   `DesignSystemTokens.Layout`.
3. Hand each removed group to its SDK's appearance colors (or layout),
   derived from the shared `DesignSystemTokens` instance the appearance is
   constructed with.
4. Check the counts: 175 shared color tokens and 66 shared layout tokens as
   of this note. A changed count means a token moved scope and the lists below
   need updating too.

## Color tokens

**Messaging (37), owned by the Chat SDK.** Every `chat*` token:
`chatBackgroundAttachmentIncoming`, `chatBackgroundAttachmentOutgoing`,
`chatBackgroundIncoming`, `chatBackgroundMention`,
`chatBackgroundMentionBroadcast`, `chatBackgroundMentionGroup`,
`chatBackgroundMentionRole`, `chatBackgroundMentionUser`,
`chatBackgroundOutgoing`, `chatBorderIncoming`, `chatBorderOnChatIncoming`,
`chatBorderOnChatOutgoing`, `chatBorderOutgoing`,
`chatPollProgressFillIncoming`, `chatPollProgressFillOutgoing`,
`chatPollProgressTrackIncoming`, `chatPollProgressTrackOutgoing`,
`chatReplyIndicatorIncoming`, `chatReplyIndicatorOutgoing`, `chatTextIncoming`,
`chatTextLink`, `chatTextMention`, `chatTextMentionBroadcast`,
`chatTextMentionGroup`, `chatTextMentionRole`, `chatTextMentionUser`,
`chatTextOutgoing`, `chatTextReaction`, `chatTextRead`, `chatTextSystem`,
`chatTextTimestamp`, `chatTextTypingIndicator`, `chatTextUsername`,
`chatThreadConnectorIncoming`, `chatThreadConnectorOutgoing`,
`chatWaveformBar`, `chatWaveformBarPlaying`.

**Video (14).** The `Indicator` group
(`indicatorFair`, `indicatorGreat`, `indicatorPoor`, `indicatorSpeaking`), the
`Label` group (`labelBackgroundNeutral`, `labelBackgroundPrimary`,
`labelTextNeutral`, `labelTextPrimary`), `controlAcceptCallBackground`,
`controlAcceptCallText`, `controlVideoBackgroundControlBackground`,
`controlVideoBackgroundControlBackgroundSelected`,
`controlVideoBackgroundControlText`,
`controlVideoBackgroundControlTextSelected`.

Every product token derives from a shared one, so each SDK can define its
group against the `DesignSystemTokens` instance it was given. The exception is
`chatBackgroundMention`, which resolves to the raw `.baseTransparent0`; the
ramps are internal here, so Chat needs either a public primitive or a shared
semantic token for transparent before it can adopt.

## Layout tokens

**Composer (2) and Message (6), owned by the Chat SDK.**
`composerRadiusFixed`, `composerRadiusFloating`,
`messageBubbleRadiusAttachment`, `messageBubbleRadiusAttachmentInline`,
`messageBubbleRadiusGroupBottom`, `messageBubbleRadiusGroupMiddle`,
`messageBubbleRadiusGroupTop`, `messageBubbleRadiusTail`.

The Video SDK contributes no layout tokens today.

## Product appearances

Shared tokens are configured on `DesignSystemTokens` and passed into each SDK:

```swift
let tokens = DesignSystemTokens()
tokens.colors.accentPrimary = .red
let videoAppearance = VideoAppearance(tokens: tokens)
let chatAppearance = ChatAppearance(tokens: tokens)
```

Video-only colors are `videoAppearance.colors`. Chat-only colors are
`chatAppearance.colors`. When Chat adopts, keep its existing token names as
deprecated computed properties on the old appearance type so existing call
sites keep compiling.

Fonts, icons and images stay on each SDK. Shared typography and iconography
are out of scope here.
