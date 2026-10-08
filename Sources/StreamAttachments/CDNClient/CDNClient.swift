//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// An uploaded file.
public struct UploadedFile: Decodable {
    public let fileURL: URL
    public let thumbnailURL: URL?

    public init(fileURL: URL, thumbnailURL: URL? = nil) {
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
    }
}

/// The CDN client is responsible to upload files to a CDN.
public protocol CDNClient: Sendable {
    static var maxAttachmentSize: Int64 { get }

    /// Uploads attachment as a multipart/form-data and returns only the uploaded remote file.
    /// - Parameters:
    ///   - attachment: An attachment to upload.
    ///   - progress: A closure that broadcasts upload progress.
    ///   - completion: Returns the uploaded file's information.
    func uploadAttachment(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @Sendable @escaping (Result<URL, Error>) -> Void
    )

    /// Uploads attachment as a multipart/form-data and returns the uploaded remote file and its thumbnail.
    /// - Parameters:
    ///   - attachment: An attachment to upload.
    ///   - progress: A closure that broadcasts upload progress.
    ///   - completion: Returns the uploaded file's information.
    func uploadAttachment(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @Sendable @escaping (Result<UploadedFile, Error>) -> Void
    )
}

public extension CDNClient {
    func uploadAttachment(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @Sendable @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        uploadAttachment(attachment, progress: progress, completion: { (result: Result<URL, Error>) in
            switch result {
            case let .success(url):
                completion(.success(UploadedFile(fileURL: url, thumbnailURL: nil)))
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }
}

/// Default implementation of CDNClient that uses Stream CDN
public class StreamCDNClient: CDNClient, @unchecked Sendable {
    public static var maxAttachmentSize: Int64 { 100 * 1024 * 1024 }

    private let decoder: RequestDecoder
    private let encoder: RequestEncoder
    private let session: URLSession
    /// Keeps track of uploading tasks progress
    @Atomic private var taskProgressObservers: [Int: NSKeyValueObservation] = [:]

    public init(
        encoder: RequestEncoder,
        decoder: RequestDecoder,
        sessionConfiguration: URLSessionConfiguration
    ) {
        self.encoder = encoder
        session = URLSession(configuration: sessionConfiguration)
        self.decoder = decoder
    }

    public func uploadAttachment(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)? = nil,
        completion: @Sendable @escaping (Result<URL, Error>) -> Void
    ) {
        uploadAttachment(attachment, progress: progress, completion: { (result: Result<UploadedFile, Error>) in
            switch result {
            case let .success(file):
                completion(.success(file.fileURL))
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }

    public func uploadAttachment(
        _ attachment: AnyStreamAttachment,
        progress: (@Sendable (Double) -> Void)? = nil,
        completion: @Sendable @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        guard
            let uploadingState = attachment.uploadingState,
            let fileData = try? Data(contentsOf: uploadingState.localFileURL) else {
            return completion(.failure(ClientError.AttachmentUploading(id: attachment.id)))
        }
        // Encode locally stored attachment into multipart form data
        let multipartFormData = MultipartFormData(
            fileData,
            fileName: uploadingState.localFileURL.lastPathComponent,
            mimeType: uploadingState.file.type.mimeType
        )
        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(type: attachment.type)

        encoder.encodeRequest(for: endpoint) { [weak self] (requestResult) in
            var urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error, subsystems: .httpRequests)
                completion(.failure(error))
                return
            }

            let data = multipartFormData.encode()
            urlRequest.addValue("multipart/form-data; boundary=\(multipartFormData.boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("stream-feeds-swift-v0.0.1", forHTTPHeaderField: "X-Stream-Client") // TODO: fix this.
            urlRequest.httpBody = data

            guard let self else {
                log.warning("Callback called while self is nil", subsystems: .httpRequests)
                return
            }
            
            let task = session.dataTask(with: urlRequest) { [decoder = self.decoder, session] (data, response, error) in
                do {
                    let payload: FileUploadPayload = try decoder.decodeRequestResponse(
                        data: data,
                        response: response,
                        error: error
                    )
                    Self.logUpload(request: urlRequest, response: response, responseBody: data, error: nil, session: session)
                    completion(.success(UploadedFile(fileURL: payload.fileURL, thumbnailURL: payload.thumbURL)))
                } catch {
                    Self.logUpload(request: urlRequest, response: response, responseBody: data, error: error, session: session)
                    completion(.failure(error))
                }
            }

            if let progressListener = progress {
                let taskID = task.taskIdentifier
                _taskProgressObservers.mutate { observers in
                    var updatedObservers = observers
                    updatedObservers[taskID] = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                        progressListener(progress.fractionCompleted)
                        if progress.isFinished || progress.isCancelled {
                            self?._taskProgressObservers.mutate { observers in
                                var updated = observers
                                updated[taskID]?.invalidate()
                                updated[taskID] = nil
                                return updated
                            }
                        }
                    }
                    return updatedObservers
                }
            }

            task.resume()
        }
    }

    private static func logUpload(
        request: URLRequest,
        response: URLResponse?,
        responseBody: Data?,
        error: Error?,
        session: URLSession
    ) {
        // The body is the uploaded file, which is too large to be logged.
        var loggedRequest = request
        loggedRequest.httpBody = nil
        let status = (response as? HTTPURLResponse).map { "\($0.statusCode)" } ?? "FAILED"
        log.log(
            logLevel(for: error),
            message: "\(status) \(request.httpMethod ?? "POST") \(request.url?.path ?? "")",
            subsystems: .httpRequests,
            error: nil,
            attachment: HTTPLogAttachment(
                request: loggedRequest,
                response: response,
                responseBody: responseBody,
                error: error,
                session: session
            )
        )
    }

    private static func logLevel(for error: Error?) -> LogLevel {
        guard let error else { return .debug }
        if error is ClientError.ExpiredToken {
            return .info
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, [NSURLErrorCancelled, NSURLErrorNetworkConnectionLost].contains(nsError.code) {
            return .info
        }
        return .error
    }
}

/// A file upload response.
struct FileUploadPayload: Decodable {
    let fileURL: URL
    let thumbURL: URL?

    enum CodingKeys: String, CodingKey {
        case fileURL = "file"
        case thumbURL = "thumb_url"
    }
}
