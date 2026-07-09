//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum APIHelper {
    public static func rejectNil(_ source: [String: Any?]) -> [String: Any]? {
        let destination = source.reduce(into: [String: Any]()) { result, item in
            if let value = item.value {
                result[item.key] = value
            }
        }

        if destination.isEmpty {
            return nil
        }
        return destination
    }

    public static func rejectNilHeaders(_ source: [String: Any?]) -> [String: String] {
        source.reduce(into: [String: String]()) { result, item in
            if let collection = item.value as? [Any?] {
                result[item.key] = collection
                    .compactMap { value in convertAnyToString(value) }
                    .joined(separator: ",")
            } else if let value: Any = item.value {
                result[item.key] = convertAnyToString(value)
            }
        }
    }

    public static func convertBoolToString(_ source: [String: Any]?) -> [String: Any]? {
        guard let source else {
            return nil
        }

        return source.reduce(into: [String: Any]()) { result, item in
            switch item.value {
            case let x as Bool:
                result[item.key] = x.description
            default:
                result[item.key] = item.value
            }
        }
    }

    public static func convertAnyToString(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let value = value as? any RawRepresentable {
            return "\(value.rawValue)"
        } else {
            return "\(value)"
        }
    }

    public static func mapValueToPathItem(_ source: Any) -> Any {
        if let collection = source as? [Any?] {
            return collection
                .compactMap { value in convertAnyToString(value) }
                .joined(separator: ",")
        }
        return source
    }

    /// Maps a value to a single path component and percent-encodes it for use in a URL path.
    /// Folds the previous two-step `mapValueToPathItem` + `addingPercentEncoding` into one call
    /// so generated endpoint paths stay compact. A `nil` value maps to an empty component.
    public static func escapedPathItem(_ value: Any?) -> String {
        guard let value else { return "" }
        let item = "\(mapValueToPathItem(value))"
        return item.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    }

    /// maps all values from source to query parameters
    ///
    /// explode attribute is respected: collection values might be either joined or split up into separate key value pairs
    public static func mapValuesToQueryItems(_ source: [String: (wrappedValue: Any?, isExplode: Bool)]) -> [URLQueryItem]? {
        let destination = source.filter { $0.value.wrappedValue != nil }.reduce(into: [URLQueryItem]()) { result, item in
            if let collection = item.value.wrappedValue as? [Any?] {
                let collectionValues: [String] = collection.compactMap { value in convertAnyToString(value) }

                if !item.value.isExplode {
                    result.append(URLQueryItem(name: item.key, value: collectionValues.joined(separator: ",")))
                } else {
                    collectionValues
                        .forEach { value in
                            result.append(URLQueryItem(name: item.key, value: value))
                        }
                }

            } else if let value = item.value.wrappedValue {
                result.append(URLQueryItem(name: item.key, value: convertAnyToString(value)))
            }
        }

        if destination.isEmpty {
            return nil
        }
        return destination
    }

    /// maps all values from source to query parameters
    ///
    /// collection values are always exploded
    public static func mapValuesToQueryItems(_ source: [String: Any?]) -> [URLQueryItem]? {
        let destination = source.filter { $0.value != nil }.reduce(into: [URLQueryItem]()) { result, item in
            if let collection = item.value as? [Any?] {
                collection
                    .compactMap { value in convertAnyToString(value) }
                    .forEach { value in
                        result.append(URLQueryItem(name: item.key, value: value))
                    }

            } else if let value = item.value {
                result.append(URLQueryItem(name: item.key, value: convertAnyToString(value)))
            }
        }

        if destination.isEmpty {
            return nil
        }
        return destination
    }

    /// Maps all values from source to a query-parameter dictionary
    ///
    /// Keys whose value is nil are omitted; collection values are comma-joined.
    public static func mapValuesToQueryDictionary(_ source: [String: Any?]) -> [String: String]? {
        let destination = source.filter { $0.value != nil }.reduce(into: [String: String]()) { result, item in
            if let collection = item.value as? [Any?] {
                result[item.key] = collection
                    .compactMap { value in convertAnyToString(value) }
                    .joined(separator: ",")
            } else if let value = item.value {
                result[item.key] = convertAnyToString(value)
            }
        }

        if destination.isEmpty {
            return nil
        }
        return destination
    }
}
