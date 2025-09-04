//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct AnyFilterMatcher<Model>: Sendable, Equatable where Model: Sendable {
    private let match: @Sendable (Model, any FilterValue, FilterOperator) -> Bool

    public init<Value>(localValue: @escaping @Sendable (Model) -> Value?) where Value: FilterValue {
        match = FilterMatcher(localValue: localValue).match
    }
    
    func match(_ model: Model, to value: any FilterValue, filterOperator: FilterOperator) -> Bool {
        match(model, value, filterOperator)
    }
    
    public static func == (lhs: AnyFilterMatcher<Model>, rhs: AnyFilterMatcher<Model>) -> Bool {
        return true
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
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.localizedCaseInsensitiveCompare(rhsValue) == .orderedSame
        default: localRawJSONValue == filterRawJSONValue
        }
    }
    
    static func isGreater(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue > rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.localizedCaseInsensitiveCompare(rhsValue) == .orderedDescending
        default: false
        }
    }
    
    static func isGreaterOrEqual(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue >= rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.localizedCaseInsensitiveCompare(rhsValue) != .orderedAscending
        default: false
        }
    }
    
    static func isLess(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue < rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.localizedCaseInsensitiveCompare(rhsValue) == .orderedAscending
        default: false
        }
    }
    
    static func isLessOrEqual(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.number(let lhsValue), .number(let rhsValue)): lhsValue <= rhsValue
        case (.string(let lhsValue), .string(let rhsValue)): lhsValue.localizedCaseInsensitiveCompare(rhsValue) != .orderedDescending
        default: false
        }
    }
    
    static func autocomplete(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.string(let localStringValue), .string(let filterStringValue)):
            return localStringValue.range(of: filterStringValue, options: [.anchored, .caseInsensitive], locale: .autoupdatingCurrent) != nil
        default:
            return false
        }
    }
    
    static func query(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.string(let localStringValue), .string(let filterStringValue)):
            return localStringValue.localizedCaseInsensitiveContains(filterStringValue)
        default:
            return false
        }
    }
    
    static func contains(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.array(let localArrayValue), _):
            return localArrayValue.containsLocalizedCaseInsensitive(filterRawJSONValue)
        case (.dictionary(let localDictionaryValue), .dictionary(let filterDictionaryValue)):
            if filterDictionaryValue.isEmpty {
                return localDictionaryValue.isEmpty
            }
            // Partial matching
            return filterDictionaryValue.allSatisfy { (filterKey, filterValue) in
                guard let localValue = localDictionaryValue.valueForLocalizedCaseInsensitive(filterKey) else { return false }
                if contains(localValue, filterValue) {
                    return true
                }
                // Match single values since dictionary values should be compared
                return isEqual(localValue, filterValue)
            }
        default:
            return false
        }
    }
    
    static func isIn(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch filterRawJSONValue {
        case .array(let rawJSONArrayValue):
            return rawJSONArrayValue.containsLocalizedCaseInsensitive(localRawJSONValue)
        default:
            return false
        }
    }
    
    static func pathExists(_ localRawJSONValue: RawJSON, _ filterRawJSONValue: RawJSON) -> Bool {
        switch (localRawJSONValue, filterRawJSONValue) {
        case (.dictionary(let dictionaryValue), .string(let path)):
            let components = path.components(separatedBy: ".")
            guard !components.isEmpty else { return false }

            var next: [String: RawJSON]? = dictionaryValue
            for component in components {
                if let nextValue = next?.valueForLocalizedCaseInsensitive(component) {
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
}

private extension Array where Element == RawJSON {
    func containsLocalizedCaseInsensitive(_ searchElement: Element) -> Bool {
        switch searchElement {
        case .string(let stringValue):
            self.contains(where: { $0.stringValue?.localizedCaseInsensitiveCompare(stringValue) == .orderedSame })
        default:
            self.contains(searchElement)
        }
    }
}

private extension Dictionary where Key: StringProtocol {
    func valueForLocalizedCaseInsensitive(_ searchKey: Key) -> Value? {
        if let value = self[searchKey] {
            return value
        }
        if let matchingKey = keys.first(where: { $0.localizedCaseInsensitiveCompare(searchKey) == .orderedSame }) {
            return self[matchingKey]
        }
        return nil
    }
}
