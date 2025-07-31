//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines a filter for querying data.
///
/// Filters are used to specify conditions for retrieving data from Stream's API.
/// Each filter consists of a field, an operator, and a value to compare against.
///
/// - Note: Filters can be combined using logical operators (AND/OR) to create complex queries.
public protocol Filter: FilterValue, Sendable {
    /// The associated type representing the field that this filter operates on.
    associatedtype FilterField: FilterFieldRepresentable
    
    /// The field to filter on (e.g., "id", "fid", "user_id").
    var field: FilterField { get }
    
    /// The value to compare against the field.
    var value: any FilterValue { get }
    
    /// The comparison operator to use (e.g., equal, greater, contains).
    var filterOperator: FilterOperator { get }
    
    /// Creates a new filter with the specified operator, field, and value.
    ///
    /// - Parameters:
    ///   - filterOperator: The comparison operator to use.
    ///   - field: The field to filter on.
    ///   - value: The value to compare against.
    init(filterOperator: FilterOperator, field: FilterField, value: any FilterValue)
}

/// A protocol that defines values that can be used in filters.
///
/// This protocol is automatically conformed to by common Swift types like `String`, `Int`, `Bool`, etc.
public protocol FilterValue: Sendable {}

/// A protocol that defines how filter fields are represented as strings.
///
/// This protocol allows for type-safe field names while maintaining the ability to convert to string values
/// for API communication.
public protocol FilterFieldRepresentable: Sendable {
    /// The string representation of the field.
    var value: String { get }
    
    /// Creates a field representation from a string value.
    ///
    /// - Parameter value: The string value representing the field.
    init(value: String)
}

extension FilterFieldRepresentable {
    /// Logical AND operator for combining multiple filters.
    static var and: Self { Self(value: "$and") }
    
    /// Logical OR operator for combining multiple filters.
    static var or: Self { Self(value: "$or") }
}

// MARK: - Filter Building

extension Filter {
    /// Creates a filter that checks if a field equals a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to check equality against.
    /// - Returns: A filter that matches when the field equals the specified value.
    public static func equal(_ field: FilterField, _ value: any FilterValue) -> Self {
        Self(filterOperator: .equal, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is greater than a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is greater than the specified value.
    public static func greater(_ field: FilterField, _ value: any FilterValue) -> Self {
        Self(filterOperator: .greater, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is greater than or equal to a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is greater than or equal to the specified value.
    public static func greaterOrEqual(_ field: FilterField, _ value: any FilterValue) -> Self {
        Self(filterOperator: .greaterOrEqual, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is less than a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is less than the specified value.
    public static func less(_ field: FilterField, _ value: any FilterValue) -> Self {
        Self(filterOperator: .less, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is less than or equal to a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is less than or equal to the specified value.
    public static func lessOrEqual(_ field: FilterField, _ value: any FilterValue) -> Self {
        Self(filterOperator: .lessOrEqual, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field's value is in a specific array of values.
    ///
    /// - Parameters:
    ///   - field: The field to check.
    ///   - values: An array of values to check against.
    /// - Returns: A filter that matches when the field's value is in the specified array.
    public static func `in`<Value>(_ field: FilterField, _ values: [Value]) -> Self where Value: FilterValue {
        Self(filterOperator: .in, field: field, value: values)
    }
    
    /// Creates a filter that checks if a field exists or doesn't exist.
    ///
    /// - Parameters:
    ///   - field: The field to check for existence.
    ///   - value: `true` to check if the field exists, `false` to check if it doesn't exist.
    /// - Returns: A filter that matches based on the field's existence.
    public static func exists(_ field: FilterField, _ value: Bool) -> Self {
        Self(filterOperator: .exists, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field contains a specific string value.
    ///
    /// - Parameters:
    ///   - field: The field to search in.
    ///   - value: The string to search for.
    /// - Returns: A filter that matches when the field contains the specified string.
    public static func contains(_ field: FilterField, _ value: String) -> Self {
        Self(filterOperator: .contains, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field contains specific key-value pairs.
    ///
    /// - Parameters:
    ///   - field: The field to search in.
    ///   - value: A dictionary of key-value pairs to search for.
    /// - Returns: A filter that matches when the field contains the specified key-value pairs.
    public static func contains(_ field: FilterField, _ value: [String: RawJSON]) -> Self {
        Self(filterOperator: .contains, field: field, value: value)
    }
    
    /// Creates a filter that checks if a specific path exists within a field.
    ///
    /// - Parameters:
    ///   - field: The field to check.
    ///   - value: The path to check for existence.
    /// - Returns: A filter that matches when the specified path exists in the field.
    public static func pathExists(_ field: FilterField, _ value: String) -> Self {
        Self(filterOperator: .pathExists, field: field, value: value)
    }
    
    /// Creates a filter that performs autocomplete matching on a field.
    ///
    /// - Parameters:
    ///   - field: The field to perform autocomplete on.
    ///   - value: The string to autocomplete against.
    /// - Returns: A filter that matches based on autocomplete functionality.
    public static func autocomplete(_ field: FilterField, _ value: String) -> Self {
        Self(filterOperator: .autocomplete, field: field, value: value)
    }

    /// Creates a filter that performs a full-text query on a field.
    ///
    /// - Parameters:
    ///   - field: The field to query.
    ///   - value: The query string to search for.
    /// - Returns: A filter that matches based on the full-text query.
    public static func query(_ field: FilterField, _ value: String) -> Self {
        Self(filterOperator: .query, field: field, value: value)
    }
    
    /// Creates a filter that combines multiple filters with a logical AND operation.
    ///
    /// - Parameter filters: An array of filters to combine.
    /// - Returns: A filter that matches when all the specified filters match.
    public static func and<F>(_ filters: [F]) -> F where F: Filter, F.FilterField == FilterField {
        F(filterOperator: .and, field: .and, value: filters)
    }
    
    /// Creates a filter that combines multiple filters with a logical OR operation.
    ///
    /// - Parameter filters: An array of filters to combine.
    /// - Returns: A filter that matches when any of the specified filters match.
    public static func or<F>(_ filters: [F]) -> F where F: Filter, F.FilterField == FilterField {
        F(filterOperator: .or, field: .and, value: filters)
    }
}

// MARK: - Supported Filter Values

/// Extends `Bool` to conform to `FilterValue` for use in filters.
extension Bool: FilterValue {}

/// Extends `Date` to conform to `FilterValue` for use in filters.
/// Dates are automatically converted to RFC3339 format when serialized.
extension Date: FilterValue {}

/// Extends `Double` to conform to `FilterValue` for use in filters.
extension Double: FilterValue {}

/// Extends `Float` to conform to `FilterValue` for use in filters.
extension Float: FilterValue {}

/// Extends `Int` to conform to `FilterValue` for use in filters.
extension Int: FilterValue {}

/// Extends `String` to conform to `FilterValue` for use in filters.
extension String: FilterValue {}

/// Extends `URL` to conform to `FilterValue` for use in filters.
/// URLs are automatically converted to their absolute string representation when serialized.
extension URL: FilterValue {}

/// Extends `Array` to conform to `FilterValue` when its elements also conform to `FilterValue`.
/// This allows arrays of filter values to be used in filters (e.g., for the `in` operator).
extension Array: FilterValue where Element: FilterValue {}

/// Extends `Dictionary` to conform to `FilterValue` when the key is `String` and value is `RawJSON`.
/// This allows dictionaries to be used in filters for complex object matching.
extension Dictionary: FilterValue where Key == String, Value == RawJSON {}

// MARK: - Filter to RawJSON Conversion

extension Filter {
    /// Converts the filter to a `RawJSON` representation for API communication.
    ///
    /// This method handles both regular filters and group filters (AND/OR combinations).
    ///
    /// - Returns: A dictionary representation of the filter in `RawJSON` format.
    public func toRawJSON() -> [String: RawJSON] {
        if filterOperator.isGroup {
            // Filters with group operators are encoded in the following form:
            //  { $<operator>: [ <filter 1>, <filter 2> ] }
            guard let filters = value as? [any Filter] else {
                log.error("Unknown filter value used with \(filterOperator)")
                return [:]
            }
            let rawJSONFilters = filters.map { $0.toRawJSON() }.map { RawJSON.dictionary($0) }
            return [filterOperator.rawValue: .array(rawJSONFilters)]
        } else {
            // Normal filters are encoded in the following form:
            //  { field: { $<operator>: <value> } }
            return [field.value: .dictionary([filterOperator.rawValue: value.rawJSON])]
        }
    }
}

extension FilterValue {
    /// Converts the filter value to its `RawJSON` representation.
    ///
    /// This property handles the conversion of various Swift types to their appropriate JSON representation
    /// for API communication.
    var rawJSON: RawJSON {
        switch self {
        case let boolValue as Bool:
            .bool(boolValue)
        case let dateValue as Date:
            .string(RFC3339DateFormatter.string(from: dateValue))
        case let doubleValue as Double:
            .number(doubleValue)
        case let intValue as Int:
            .number(Double(intValue))
        case let stringValue as String:
            .string(stringValue)
        case let urlValue as URL:
            .string(urlValue.absoluteString)
        case let arrayValue as [any FilterValue]:
            .array(arrayValue.map(\.rawJSON))
        case let dictionaryValue as [String: RawJSON]:
            .dictionary(dictionaryValue)
        default:
            fatalError("Unimplemented type: \(self)")
        }
    }
}
