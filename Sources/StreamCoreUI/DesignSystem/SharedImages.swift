//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// The icons every Stream SDK draws from.
///
/// Only icons that name a generic affordance belong here. Anything that
/// names a product concept stays on the SDK that owns it, which is why
/// there is no entry for, say, hanging up a call or sending a message.
///
/// The set is SF Symbols throughout, so it carries no asset catalog and
/// each SDK resolves an icon in whichever framework it renders with.
public final class SharedImages: @unchecked Sendable {
    /// Process-wide default, used when an SDK does not pass its own images.
    public static let shared = SharedImages()

    // MARK: - Navigation

    public lazy var back: SharedImage = .system("chevron.left")
    public lazy var chevronLeft: SharedImage = .system("chevron.left")
    public lazy var chevronRight: SharedImage = .system("chevron.right")
    public lazy var chevronUp: SharedImage = .system("chevron.up")
    public lazy var close: SharedImage = .system("xmark")
    public lazy var closeCircle: SharedImage = .system("xmark.circle")
    public lazy var closeFill: SharedImage = .system("xmark.circle.fill")

    // MARK: - Actions

    public lazy var camera: SharedImage = .system("camera")
    public lazy var download: SharedImage = .system("icloud.and.arrow.down")
    public lazy var folder: SharedImage = .system("folder")
    public lazy var lock: SharedImage = .system("lock")
    public lazy var mic: SharedImage = .system("mic")
    public lazy var more: SharedImage = .system("ellipsis")
    public lazy var search: SharedImage = .system("magnifyingglass")
    public lazy var searchClose: SharedImage = .system("multiply.circle")
    public lazy var share: SharedImage = .system("square.and.arrow.up")
    public lazy var speakerSlash: SharedImage = .system("speaker.slash")
    public lazy var trash: SharedImage = .system("trash")

    // MARK: - Playback

    public lazy var pause: SharedImage = .system("pause")
    public lazy var pauseFill: SharedImage = .system("pause.fill")
    public lazy var play: SharedImage = .system("play")
    public lazy var playFill: SharedImage = .system("play.fill")
    public lazy var stop: SharedImage = .system("stop.circle")

    // MARK: - Placeholders

    public lazy var checkmarkFilled: SharedImage = .system("checkmark.circle.fill")
    public lazy var imagePlaceholder: SharedImage = .system("photo")
    public lazy var personPlaceholder: SharedImage = .system("person.circle")

    public init() { /* Public init. */ }
}
