//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A filter matcher which rrases the type of the value the filter matches against.
///
/// Allows avoiding generics in individual ``Filter`` instances with the cost of manual type matching using `RawJSON`.
/// ``AnyFilterMatcher`` instances are used by ``FilterFieldRepresentable`` and allow matching values based on the field and operator.
public struct AnyFilterMatcher<Model>: Sendable where Model: Sendable {
    private let match: @Sendable (Model, any FilterValue, FilterOperator) -> Bool

    public init<Value>(localValue: @escaping @Sendable (Model) -> Value?) where Value: FilterValue {
        match = FilterMatcher(localValue: localValue).match
    }
    
    func match(_ model: Model, to value: any FilterValue, filterOperator: FilterOperator) -> Bool {
        match(model, value, filterOperator)
    }
}

extension Filter {
    /// Evaluates whether a model matches the current filter criteria.
    ///
    /// This method performs local filtering by evaluating the filter against a provided model.
    /// It handles both simple filters (using field matchers) and compound filters (using logical operators).
    ///
    /// - Parameter model: The model to evaluate against the filter criteria.
    ///   Must conform to the same type as specified in the filter's field.
    ///
    /// - Returns: `true` if the model matches the filter criteria, `false` otherwise.
    ///
    /// ## Example Usage
    /// ```swift
    /// let filter = Filter.equal("name", "John")
    /// let user = User(name: "John", age: 30)
    /// let matches = filter.matches(user) // true
    ///
    /// let compoundFilter = Filter.and([
    ///     Filter.equal("name", "John"),
    ///     Filter.greater("age", 25)
    /// ])
    /// let matches = compoundFilter.matches(user) // true
    /// ```
    public func matches<Model>(_ model: Model) -> Bool where Model == FilterField.Model {
        switch filterOperator {
        case .and:
            guard let subfilters = value as? [Self] else { return false }
            return subfilters.allSatisfy { $0.matches(model) }
        case .or:
            guard let subfilters = value as? [Self] else { return false }
            return subfilters.contains(where: { $0.matches(model) })
        default:
            return field.matcher.match(model, to: value, filterOperator: filterOperator)
        }
    }
    
    /// Checks whether this filter contains a specific field.
    ///
    /// This method recursively traverses compound filters (AND/OR) to determine if any subfilter
    /// operates on the specified field.
    ///
    /// - Parameter field: The field to search for in the filter hierarchy.
    /// - Returns: `true` if the filter contains the specified field, `false` otherwise.
    ///
    /// ## Example Usage
    /// ```swift
    /// let nameField = FilterField("name", localValue: { $0.name })
    /// let ageField = FilterField("age", localValue: { $0.age })
    ///
    /// let filter = Filter.and([
    ///     Filter.equal(nameField, "John"),
    ///     Filter.greater(ageField, 25)
    /// ])
    ///
    /// let containsName = filter.contains(nameField) // true
    /// let containsEmail = filter.contains(emailField) // false
    /// ```
    public func contains<Field>(_ field: Field) -> Bool where Field == Self.FilterField {
        switch filterOperator {
        case .and, .or:
            guard let subfilters = value as? [Self] else { return false }
            return subfilters.contains(where: { $0.contains(field) })
        default:
            return self.field.rawValue == field.rawValue
        }
    }
}

private struct FilterMatcher<Model, Value>: Sendable where Model: Sendable, Value: FilterValue {
    let localValue: @Sendable (Model) -> Value
    
    init(localValue: @escaping @Sendable (Model) -> Value) {
        self.localValue = localValue
    }
    
    func match(_ model: Model, to value: any FilterValue, filterOperator: FilterOperator) -> Bool {
        let localRawJSONValue = localValue(model).rawJSON
        let filterRawJSONValue = value.rawJSON
        
        switch filterOperator {
        case .exists:
            return Self.exists(localRawJSONValue, filterRawJSONValue)
        case .equal:
            return Self.isEqual(localRawJSONValue, filterRawJSONValue)
        case .greater:
            return Self.isGreater(localRawJSONValue, filterRawJSONValue)
        case .greaterOrEqual:
            return Self.isGreaterOrEqual(localRawJSONValue, filterRawJSONValue)
        case .less:
            return Self.isLess(localRawJSONValue, filterRawJSONValue)
        case .lessOrEqual:
            return Self.isLessOrEqual(localRawJSONValue, filterRawJSONValue)
        case .autocomplete:
            return Self.autocomplete(localRawJSONValue, filterRawJSONValue)
        case .query:
            return Self.query(localRawJSONValue, filterRawJSONValue)
        case .contains:
            return Self.contains(localRawJSONValue, filterRawJSONValue)
        case .in:
            return Self.isIn(localRawJSONValue, filterRawJSONValue)
        case .pathExists:
            return Self.pathExists(localRawJSONValue, filterRawJSONValue)
        case .and, .or:
            log.debug("Should never try to match compound operators")
            return false
        }
    }
    
    static func exists(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch filterRawJSONValue {
        case .bool(let exists): exists ? !localRawJSONValue.isNil : localRawJSONValue.isNil
        default: false
        }
    }

    static func isEqual(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        localRawJSONValue == filterRawJSONValue
    }
    
    static func isGreater(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue > rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): rhsValue.lexicographicallyPrecedes(lhsValue)
        default: false
        }
    }
    
    static func isGreaterOrEqual(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue >= rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): rhsValue.lexicographicallyPrecedes(lhsValue) || rhsValue == lhsValue
        default: false
        }
    }
    
    static func isLess(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue < rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.lexicographicallyPrecedes(rhsValue)
        default: false
        }
    }
    
    static func isLessOrEqual(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue <= rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.lexicographicallyPrecedes(rhsValue) || lhsValue == rhsValue
        default: false
        }
    }
    
    static func autocomplete(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.string(let localStringValue), .string(let filterStringValue)):
            Self.postgreSQLFullTextSearch(anchored: true, text: localStringValue, query: filterStringValue)
        default:
            false
        }
    }
    
    static func query(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.string(let localStringValue), .string(let filterStringValue)):
            Self.postgreSQLFullTextSearch(anchored: false, text: localStringValue, query: filterStringValue)
        default:
            false
        }
    }
    
    static func contains(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.array(let localArrayValue), .array(let filterArrayValue)):
            return filterArrayValue.allSatisfy { localArrayValue.contains($0) }
        case (.array(let localArrayValue), _): // string, number etc
            return localArrayValue.contains(filterRawJSONValue)
        case (.dictionary(let localDictionaryValue), .dictionary(let filterDictionaryValue)):
            if filterDictionaryValue.isEmpty {
                return localDictionaryValue.isEmpty
            }
            // Partial matching
            return filterDictionaryValue.allSatisfy { (filterKey, filterValue) in
                guard let localValue = localDictionaryValue[filterKey] else { return false }
                if contains(localValue, filterValue) { // array & dictionary
                    return true
                }
                // Match single values: strings, numbers
                return isEqual(localValue, filterValue)
            }
        default:
            return false
        }
    }
    
    static func isIn(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch filterRawJSONValue {
        case .array(let rawJSONArrayValue):
            rawJSONArrayValue.contains(localRawJSONValue)
        default:
            false
        }
    }
    
    static func pathExists(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.dictionary(let dictionaryValue), .string(let path)):
            let components = path.components(separatedBy: ".")
            guard !components.isEmpty else { return false }

            var next: [String: RawJSON]? = dictionaryValue
            for component in components {
                if let nextValue = next?[component] {
                    next = nextValue.dictionaryValue
                } else {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
    
    // MARK: -
    
    /// PostgreSQL-style full-text search for tokenized text and word boundary matching
    ///
    /// - Important: This is a simplified implementation.
    private static func postgreSQLFullTextSearch(anchored: Bool, text: String, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        let options: String.CompareOptions = anchored ? [.anchored, .caseInsensitive] : [.caseInsensitive]
        // Entire text starts with the query (single or phrase)
        if text.range(of: query, options: options) != nil {
            return true
        }
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return words.contains(where: { $0.range(of: query, options: options) != nil })
    }
}
