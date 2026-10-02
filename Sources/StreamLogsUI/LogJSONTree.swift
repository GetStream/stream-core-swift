//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The nodes of one or more JSON documents, stored in depth-first order, so that a node's descendants follow it.
struct LogJSONTree: Sendable {
    enum Key: Equatable, Sendable {
        case title(String)
        case name(String)
        case index(Int)

        var text: String {
            switch self {
            case let .title(title): title
            case let .name(name): name
            case let .index(index): "[\(index)]"
            }
        }
    }

    enum Value: Equatable, Sendable {
        case object(count: Int)
        case array(count: Int)
        case string(String)
        case number(String)
        case bool(Bool)
        case null

        var isContainer: Bool {
            switch self {
            case .object, .array: true
            case .string, .number, .bool, .null: false
            }
        }

        var text: String {
            switch self {
            case let .object(count): "{…} \(count) \(count == 1 ? "key" : "keys")"
            case let .array(count): "[…] \(count) \(count == 1 ? "item" : "items")"
            case let .string(string): string
            case let .number(number): number
            case let .bool(bool): bool ? "true" : "false"
            case .null: "null"
            }
        }
    }

    struct Node: Identifiable, Sendable {
        let id: Int
        let parent: Int?
        let depth: Int
        let key: Key
        let value: Value
        fileprivate(set) var children: [Int] = []
    }

    private(set) var nodes: [Node] = []
    private(set) var roots: [Int] = []

    // Documents that are not valid JSON are skipped.
    init(documents: [(title: String, text: String)] = []) {
        for document in documents {
            guard let object = try? JSONSerialization.jsonObject(with: Data(document.text.utf8), options: .fragmentsAllowed) else {
                continue
            }
            roots.append(append(object, key: .title(document.title), parent: nil, depth: 0))
        }
    }

    var isEmpty: Bool { roots.isEmpty }

    var containerIDs: Set<Int> {
        Set(nodes.lazy.filter(\.value.isContainer).map(\.id))
    }

    func visibleIDs(expanded: Set<Int>) -> [Int] {
        var result: [Int] = []
        var stack = Array(roots.reversed())
        while let id = stack.popLast() {
            result.append(id)
            if expanded.contains(id) {
                stack.append(contentsOf: nodes[id].children.reversed())
            }
        }
        return result
    }

    // Root titles are not matched, as they are not part of the JSON.
    func matches(for query: String) -> [Int] {
        guard !query.isEmpty else { return [] }
        let contains = { (text: String) in text.range(of: query, options: .caseInsensitive) != nil }
        return nodes.compactMap { node in
            if case let .name(name) = node.key, contains(name) {
                return node.id
            }
            return !node.value.isContainer && contains(node.value.text) ? node.id : nil
        }
    }

    func ancestors(of id: Int) -> [Int] {
        var result: [Int] = []
        var parent = nodes[id].parent
        while let id = parent {
            result.append(id)
            parent = nodes[id].parent
        }
        return result
    }

    // Scalars are returned as is, without the quotes of strings.
    func jsonText(for id: Int) -> String {
        let node = nodes[id]
        guard node.value.isContainer else { return node.value.text }
        guard let data = try? JSONSerialization.data(
            withJSONObject: jsonObject(for: id),
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
        ) else {
            return node.value.text
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func jsonObject(for id: Int) -> Any {
        let node = nodes[id]
        switch node.value {
        case .object:
            return Dictionary(uniqueKeysWithValues: node.children.map { (nodes[$0].key.text, jsonObject(for: $0)) })
        case .array:
            return node.children.map { jsonObject(for: $0) }
        case let .string(string):
            return string
        case let .number(number):
            return NSDecimalNumber(string: number)
        case let .bool(bool):
            return bool
        case .null:
            return NSNull()
        }
    }

    private mutating func append(_ object: Any, key: Key, parent: Int?, depth: Int) -> Int {
        let id = nodes.count
        switch object {
        case let dictionary as [String: Any]:
            nodes.append(Node(id: id, parent: parent, depth: depth, key: key, value: .object(count: dictionary.count)))
            let children = dictionary.keys.sorted().map { name in
                append(dictionary[name] as Any, key: .name(name), parent: id, depth: depth + 1)
            }
            nodes[id].children = children
        case let array as [Any]:
            nodes.append(Node(id: id, parent: parent, depth: depth, key: key, value: .array(count: array.count)))
            let children = array.enumerated().map { index, element in
                append(element, key: .index(index), parent: id, depth: depth + 1)
            }
            nodes[id].children = children
        case let string as String:
            nodes.append(Node(id: id, parent: parent, depth: depth, key: key, value: .string(string)))
        case let number as NSNumber:
            let value: Value = CFGetTypeID(number) == CFBooleanGetTypeID() ? .bool(number.boolValue) : .number(number.stringValue)
            nodes.append(Node(id: id, parent: parent, depth: depth, key: key, value: value))
        default:
            nodes.append(Node(id: id, parent: parent, depth: depth, key: key, value: .null))
        }
        return id
    }
}
