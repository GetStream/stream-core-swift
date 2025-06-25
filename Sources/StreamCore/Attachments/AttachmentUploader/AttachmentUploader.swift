//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component responsible to upload files.
public protocol AttachmentUploader {
    /// Uploads a type-erased attachment, and returns the attachment with the remote information.
    /// - Parameters:
    ///   - attachment: A type-erased attachment.
    ///   - progress: The progress of the upload.
    ///   - completion: The callback with the uploaded attachment.
    func upload(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @Sendable @escaping (Result<UploadedAttachment, Error>) -> Void
    )
    
    func upload(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> UploadedAttachment
}

extension AttachmentUploader {
    public func upload(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> UploadedAttachment {
        try await withCheckedThrowingContinuation { continuation in
            upload(attachment, progress: progress) { result in
                continuation.resume(with: result)
            }
        }
    }
}

public class StreamAttachmentUploader: AttachmentUploader, @unchecked Sendable {
    let cdnClient: CDNClient

    public init(cdnClient: CDNClient) {
        self.cdnClient = cdnClient
    }

    public func upload(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @Sendable @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        cdnClient.uploadAttachment(attachment, progress: progress) { (result: Result<UploadedFile, Error>) in
            completion(result.map { file in
                let uploadedAttachment = UploadedAttachment(
                    attachment: attachment,
                    remoteURL: file.fileURL,
                    thumbnailURL: file.thumbnailURL
                )
                return uploadedAttachment
            })
        }
    }
}
