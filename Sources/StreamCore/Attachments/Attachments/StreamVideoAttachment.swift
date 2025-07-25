//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `VideoAttachmentPayload` payload type.
///
/// The `StreamVideoAttachment` attachment will be added to the content automatically
/// if the content was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.video` attachment type.
public typealias StreamVideoAttachment = StreamAttachment<VideoAttachmentPayload>

/// Represents a payload for attachments with `.media` type.
public struct VideoAttachmentPayload: AttachmentPayload {
    /// An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.video`.
    public static let type: AttachmentType = .video

    /// A title, usually the name of the video.
    public var title: String?
    /// A link to the video.
    public var videoURL: URL
    /// A link to the video thumbnail.
    public var thumbnailURL: URL?
    /// The video itself.
    public var file: AttachmentFile
    /// An extra data.
    public var extraData: [String: RawJSON]?

    /// Decodes extra data as an instance of the given type.
    /// - Parameter ofType: The type an extra data should be decoded as.
    /// - Returns: Extra data of the given type or `nil` if decoding fails.
    public func extraData<T: Decodable>(ofType: T.Type = T.self) -> T? {
        extraData
            .flatMap { try? JSONEncoder.default.encode($0) }
            .flatMap { try? JSONDecoder.default.decode(T.self, from: $0) }
    }

    /// Creates `VideoAttachmentPayload` instance.
    ///
    /// Use this initializer if the attachment is already uploaded and you have the remote URLs.
    public init(title: String?, videoRemoteURL: URL, thumbnailURL: URL? = nil, file: AttachmentFile, extraData: [String: RawJSON]?) {
        self.title = title
        videoURL = videoRemoteURL
        self.thumbnailURL = thumbnailURL
        self.file = file
        self.extraData = extraData
    }
}

extension VideoAttachmentPayload: Hashable {}

// MARK: - Local Downloads

extension VideoAttachmentPayload: AttachmentPayloadDownloading {
    public var localStorageFileName: String {
        title ?? file.defaultLocalStorageFileName(for: Self.type)
    }
    
    public var remoteURL: URL {
        videoURL
    }
}

// MARK: - Encodable

extension VideoAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.assetURL.rawValue] = .string(videoURL.absoluteString)
        thumbnailURL.map {
            values[AttachmentCodingKeys.thumbURL.rawValue] = .string($0.absoluteString)
        }
        values[AttachmentFile.CodingKeys.size.rawValue] = .number(Double(Int(file.size)))
        values[AttachmentFile.CodingKeys.mimeType.rawValue] = file.mimeType.map { .string($0) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension VideoAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            videoRemoteURL: try container.decode(URL.self, forKey: .assetURL),
            thumbnailURL: try container.decodeIfPresent(URL.self, forKey: .thumbURL),
            file: try AttachmentFile(from: decoder),
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
