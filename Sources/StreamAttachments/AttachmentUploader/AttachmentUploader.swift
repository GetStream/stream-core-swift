//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component responsible to upload files.
public protocol AttachmentUploader: Sendable {
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
    
    /// Uploads a type-erased attachment, and returns the attachment with the remote information.
    /// - Parameters:
    ///   - attachment: A type-erased attachment.
    ///   - progress: The progress of the upload.
    /// - Returns: An attachment with the remote information.
    func upload(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> UploadedAttachment
    
    /// Uploads a type-erased attachments, and returns attachments with the remote information.
    /// - Parameters:
    ///   - attachments: A type-erased attachments.
    ///   - progress: The progress of the upload.
    /// - Returns: An array of attachments with the remote information.
    func upload(
        _ attachments: [AnyStreamAttachment],
        progress: (@Sendable (AnyStreamAttachment, Double) -> Void)?
    ) async throws -> [UploadedAttachment]
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
    
    public func upload(
        _ attachments: [AnyStreamAttachment],
        progress: (@Sendable (AnyStreamAttachment, Double) -> Void)?
    ) async throws -> [UploadedAttachment] {
        try await withThrowingTaskGroup(of: UploadedAttachment.self, returning: [UploadedAttachment].self) { group in
            for attachment in attachments {
                group.addTask {
                    try await upload(attachment, progress: { progressValue in
                        progress?(attachment, progressValue)
                    })
                }
            }
            var uploadedAttachments = [UploadedAttachment]()
            for try await attachment in group {
                uploadedAttachments.append(attachment)
            }
            return uploadedAttachments
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
