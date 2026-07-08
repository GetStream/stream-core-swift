//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

open class StreamImageCDN: ImageCDN, @unchecked Sendable {
    public nonisolated(unsafe) static var streamCDNURL = "stream-io-cdn.com"

    public init() {}

    open func urlRequest(forImageUrl url: URL, resize: ImageResize?) -> URLRequest {
        // In case it is not an image from Stream's CDN, don't do nothing.
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(StreamImageCDN.streamCDNURL) else {
            return URLRequest(url: url)
        }

        // If there is not resize, not need to add query parameters to the URL.
        guard let resize else {
            return URLRequest(url: url)
        }

        let scale = Screen.scale
        var queryItems: [String: String] = [
            "w": resize.width == 0 ? "*" : String(format: "%.0f", resize.width * scale),
            "h": resize.height == 0 ? "*" : String(format: "%.0f", resize.height * scale),
            "resize": resize.mode.value,
            "ro": "0" // Required parameter.
        ]
        if let cropValue = resize.mode.cropValue {
            queryItems["crop"] = cropValue
        }

        var items = components.queryItems ?? []

        for (key, value) in queryItems {
            if let index = items.firstIndex(where: { $0.name == key }) {
                items[index].value = value
            } else {
                let item = URLQueryItem(name: key, value: value)
                items += [item]
            }
        }

        components.queryItems = items
        return URLRequest(url: components.url ?? url)
    }

    open func cachingKey(forImageUrl url: URL) -> String {
        let key = url.absoluteString

        // In case it is not an image from Stream's CDN, don't do nothing.
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(StreamImageCDN.streamCDNURL) else {
            return key
        }

        let persistedParameters = ["w", "h", "resize", "crop"]

        let newParameters = components.queryItems?.filter { persistedParameters.contains($0.name) } ?? []
        components.queryItems = newParameters.isEmpty ? nil : newParameters
        return components.string ?? key
    }
    
    @MainActor open func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL {
        guard
            var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: true),
            let host = components.host,
            host.contains(StreamImageCDN.streamCDNURL)
        else { return originalURL }

        let scale = UIScreen.main.scale
        components.queryItems = components.queryItems ?? []
        components.queryItems?.append(contentsOf: [
            URLQueryItem(name: "w", value: String(format: "%.0f", preferredSize.width * scale)),
            URLQueryItem(name: "h", value: String(format: "%.0f", preferredSize.height * scale)),
            URLQueryItem(name: "crop", value: "center"),
            URLQueryItem(name: "resize", value: "fill"),
            URLQueryItem(name: "ro", value: "0") // Required parameter.
        ])
        return components.url ?? originalURL
    }
}

enum Screen {
    #if os(iOS) || os(tvOS)
    /// Returns the current screen scale.
    static let scale: CGFloat = UITraitCollection.current.displayScale
    #elseif os(watchOS)
    /// Returns the current screen scale.
    static let scale: CGFloat = WKInterfaceDevice.current().screenScale
    #else
    /// Always returns 1.
    static let scale: CGFloat = 1
    #endif
}
