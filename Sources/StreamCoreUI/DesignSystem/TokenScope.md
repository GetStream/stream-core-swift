# Token scope

The `design-system-tokens` generator emits one flat Swift file covering every
Stream product. This module carries only the part every SDK draws from; the
rest lives on the SDK that owns it. The split is applied by hand, so this note
is what makes a re-sync repeatable.

## Re-syncing

1. Take the generated palette and layout tokens.
2. Remove the product groups listed below and keep the remainder here, in
   `ColorPalette` and `DesignSystemTokens`.
3. Hand each removed group to its SDK, which layers it onto the shared set
   through its own appearance object.
4. Check the counts: 175 shared colour tokens and 66 shared layout tokens as
   of this note. A changed count means a token moved scope and the lists below
   need updating too.

## Colour tokens

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

Every product token derives from a shared one, so each SDK can define its group
against the shared palette without reaching for a raw ramp. The exception is
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

Fonts, icons and images stay on each SDK. Shared typography and iconography
are out of scope here.
