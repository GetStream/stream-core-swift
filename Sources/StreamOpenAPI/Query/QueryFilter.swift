//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A protocol that defines a filter for querying data.
///
/// QueryFilters are used to specify conditions for retrieving data from Stream's API.
/// Each filter consists of a field, an operator, and a value to compare against.
///
/// - Note: QueryFilters can be combined using logical operators (AND/OR) to create complex queries.
public protocol QueryFilter: QueryFilterValue, Sendable {
    /// The associated type representing the field that this filter operates on.
    associatedtype FilterField: QueryFilterFieldRepresentable
    
    /// The field to filter on (e.g., "id", "feed", "user_id").
    var field: FilterField { get }
    
    /// The value to compare against the field.
    var value: any QueryFilterValue { get }
    
    /// The comparison operator to use (e.g., equal, greater, contains).
    var filterOperator: FilterOperator { get }
    
    /// Creates a new filter with the specified operator, field, and value.
    ///
    /// - Parameters:
    ///   - filterOperator: The comparison operator to use.
    ///   - field: The field to filter on.
    ///   - value: The value to compare against.
    init(filterOperator: FilterOperator, field: FilterField, value: any QueryFilterValue)
}

/// A protocol that defines values that can be used in filters.
///
/// This protocol is automatically conformed to by common Swift types like `String`, `Int`, `Bool`, etc.
public protocol QueryFilterValue: Sendable {}

/// A protocol that defines how filter fields are represented as strings.
///
/// This protocol allows for type-safe field names while maintaining the ability to convert to string values
/// for API communication.
public protocol QueryFilterFieldRepresentable: Sendable {
    /// The model type that this filter field operates on.
    associatedtype Model: Sendable
    
    /// A matcher that can be used for local matching operations.
    var matcher: AnyQueryFilterMatcher<Model> { get }
    
    /// The string representation of the field.
    var rawValue: String { get }
    
    /// Creates a new filter field with the specified remote identifier and local value extractor.
    ///
    /// - Parameters:
    ///   - rawValue: The string identifier used for remote API requests
    ///   - localValue: A closure that extracts the comparable value from a model instance
    init<Value>(_ rawValue: String, localValue: @escaping @Sendable (Model) -> Value?) where Value: QueryFilterValue
}

extension QueryFilterFieldRepresentable {
    /// Placeholder value for compound filters.
    ///
    /// $and and $or ignore the field itself because the operation does not compare any actual data like other operators are
    /// This placeholder allows the public API to not have optional field parameter. Note how field is ignored in ``Filter.matches(_:)`` for compound operators.
    static var compoundOperatorPlaceholderField: Self { Self("", localValue: { _ in 0 }) }
}

// MARK: - Filter Building

extension QueryFilter {
    /// Creates a filter that checks if a field equals a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to check equality against.
    /// - Returns: A filter that matches when the field equals the specified value.
    public static func equal(_ field: FilterField, _ value: any QueryFilterValue) -> Self {
        Self(filterOperator: .equal, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is greater than a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is greater than the specified value.
    public static func greater(_ field: FilterField, _ value: any QueryFilterValue) -> Self {
        Self(filterOperator: .greater, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is greater than or equal to a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is greater than or equal to the specified value.
    public static func greaterOrEqual(_ field: FilterField, _ value: any QueryFilterValue) -> Self {
        Self(filterOperator: .greaterOrEqual, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is less than a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is less than the specified value.
    public static func less(_ field: FilterField, _ value: any QueryFilterValue) -> Self {
        Self(filterOperator: .less, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field is less than or equal to a specific value.
    ///
    /// - Parameters:
    ///   - field: The field to compare.
    ///   - value: The value to compare against.
    /// - Returns: A filter that matches when the field is less than or equal to the specified value.
    public static func lessOrEqual(_ field: FilterField, _ value: any QueryFilterValue) -> Self {
        Self(filterOperator: .lessOrEqual, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field's value is in a specific array of values.
    ///
    /// - Parameters:
    ///   - field: The field to check.
    ///   - values: An array of values to check against.
    /// - Returns: A filter that matches when the field's value is in the specified array.
    public static func `in`<Value>(_ field: FilterField, _ values: [Value]) -> Self where Value: QueryFilterValue {
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
    ///   - value: The value to search for.
    /// - Returns: A filter that matches when the field contains the specified value.
    public static func contains<Value>(_ field: FilterField, _ value: Value) -> Self where Value: QueryFilterValue {
        Self(filterOperator: .contains, field: field, value: value)
    }
    
    /// Creates a filter that checks if a field contains specific key-value pairs.
    ///
    /// - Parameters:
    ///   - field: The field to search in.
    ///   - value: An array of values to search for.
    /// - Returns: A filter that matches when the field contains the specified key-value pairs.
    public static func contains<Value>(_ field: FilterField, _ values: [Value]) -> Self where Value: QueryFilterValue {
        Self(filterOperator: .contains, field: field, value: values)
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
    public static func and<F>(_ filters: [F]) -> F where F: QueryFilter, F.FilterField == FilterField {
        F(filterOperator: .and, field: .compoundOperatorPlaceholderField, value: filters)
    }
    
    /// Creates a filter that combines multiple filters with a logical OR operation.
    ///
    /// - Parameter filters: An array of filters to combine.
    /// - Returns: A filter that matches when any of the specified filters match.
    public static func or<F>(_ filters: [F]) -> F where F: QueryFilter, F.FilterField == FilterField {
        F(filterOperator: .or, field: .compoundOperatorPlaceholderField, value: filters)
    }
}

// MARK: - Supported Filter Values

/// Extends `Bool` to conform to `QueryFilterValue` for use in filters.
extension Bool: QueryFilterValue {}

/// Extends `Date` to conform to `QueryFilterValue` for use in filters.
/// Dates are automatically converted to RFC3339 format when serialized.
extension Date: QueryFilterValue {}

/// Extends `Double` to conform to `QueryFilterValue` for use in filters.
extension Double: QueryFilterValue {}

/// Extends `Float` to conform to `QueryFilterValue` for use in filters.
extension Float: QueryFilterValue {}

/// Extends `Int` to conform to `QueryFilterValue` for use in filters.
extension Int: QueryFilterValue {}

/// Extends `String` to conform to `QueryFilterValue` for use in filters.
extension String: QueryFilterValue {}

/// Extends `URL` to conform to `QueryFilterValue` for use in filters.
/// URLs are automatically converted to their absolute string representation when serialized.
extension URL: QueryFilterValue {}

/// Extends `Array` to conform to `QueryFilterValue` when its elements also conform to `QueryFilterValue`.
/// This allows arrays of filter values to be used in filters (e.g., for the `in` operator).
extension Array: QueryFilterValue where Element: QueryFilterValue {}

/// Extends `Dictionary` to conform to `QueryFilterValue` when the key is `String` and value is `RawJSON`.
/// This allows dictionaries to be used in filters for complex object matching.
extension Dictionary: QueryFilterValue where Key == String, Value == RawJSON {}

extension Optional: QueryFilterValue where Wrapped: QueryFilterValue {}

// MARK: - Filter to RawJSON Conversion

extension QueryFilter {
    /// Converts the filter to a `RawJSON` representation for API communication.
    ///
    /// This method handles both regular filters and group filters (AND/OR combinations).
    ///
    /// - Returns: A dictionary representation of the filter in `RawJSON` format.
    public func toRawJSON() -> [String: RawJSON] {
        if filterOperator.isGroup {
            // Filters with group operators are encoded in the following form:
            //  { $<operator>: [ <filter 1>, <filter 2> ] }
            guard let filters = value as? [any QueryFilter] else {
                log.error("Unknown filter value used with \(filterOperator)")
                return [:]
            }
            let rawJSONFilters = filters.map { $0.toRawJSON() }.map { RawJSON.dictionary($0) }
            return [filterOperator.rawValue: .array(rawJSONFilters)]
        } else {
            // Normal filters are encoded in the following form:
            //  { field: { $<operator>: <value> } }
            return [field.rawValue: .dictionary([filterOperator.rawValue: value.rawJSON])]
        }
    }
}

extension QueryFilterValue {
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
        case let arrayValue as [any QueryFilterValue]:
            .array(arrayValue.map(\.rawJSON))
        case let dictionaryValue as [String: RawJSON]:
            .dictionary(dictionaryValue)
        default:
            .nil
        }
    }
}
