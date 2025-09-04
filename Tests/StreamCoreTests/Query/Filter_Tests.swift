//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct Filter_Tests {
    // MARK: - Test Filter Field
    
    struct TestFilterField: FilterFieldRepresentable {
        typealias Model = TestUser
        let matcher: AnyFilterMatcher<TestUser>
        let remote: String
        
        init<Value>(_ remote: String, localValue: @escaping @Sendable (TestUser) -> Value?) where Value: FilterValue {
            self.remote = remote
            self.matcher = AnyFilterMatcher(localValue: localValue)
        }
        
        static let name = Self("name", localValue: \.name)
        static let age = Self("age", localValue: \.age)
        static let height = Self("height", localValue: \.height)
        static let email = Self("email", localValue: \.email)
        static let homepage = Self("homepage", localValue: \.homepage)
        static let tags = Self("tags", localValue: \.tags)
        static let createdAt = Self("created_at", localValue: \.createdAt)
        static let isActive = Self("is_active", localValue: \.isActive)
        static let searchData = Self("search_data", localValue: \.searchData)
    }
    
    struct TestFilter: Filter {
        typealias FilterField = TestFilterField
        
        init(filterOperator: FilterOperator, field: TestFilterField, value: any FilterValue) {
            self.filterOperator = filterOperator
            self.field = field
            self.value = value
        }
        
        let field: TestFilterField
        let value: any FilterValue
        let filterOperator: FilterOperator
    }
    
    // MARK: - Filtered Model
    
    struct TestUser {
        var name: String = "John"
        var age: Int = 20
        var height: Double = 180.1
        var email: String = "john@getstream.io"
        var homepage: URL? = URL(string: "https://getstream.io")
        var tags: [String] = ["orange", "yellow"]
        var createdAt: Date = Date(timeIntervalSinceNow: 1756728556)
        var isActive: Bool = true
        var searchData: [String: RawJSON] = [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam"),
                "street": .string("Kleine-Gartmanplantsoen 21-6")
            ])
        ]
    }
    
    // MARK: - Basic Filter Tests
    
    @Test("Equal filter with string value")
    func equalFilterWithString() {
        let filter = TestFilter.equal(.name, "John")
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "name": .dictionary(["$eq": .string("John")])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Equal filter with integer value")
    func equalFilterWithInteger() {
        let filter = TestFilter.equal(.age, 25)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "age": .dictionary(["$eq": .number(25.0)])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Equal filter with boolean value")
    func equalFilterWithBoolean() {
        let filter = TestFilter.equal(.isActive, true)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "is_active": .dictionary(["$eq": .bool(true)])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Equal filter with date value")
    func equalFilterWithDate() {
        let date = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
        let filter = TestFilter.equal(.createdAt, date)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "created_at": .dictionary(["$eq": .string("2022-01-01T00:00:00.000Z")])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Comparison Filter Tests
    
    @Test("Greater than filter")
    func greaterThanFilter() {
        let filter = TestFilter.greater(.age, 18)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "age": .dictionary(["$gt": .number(18.0)])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Greater than or equal filter")
    func greaterThanOrEqualFilter() {
        let filter = TestFilter.greaterOrEqual(.age, 21)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "age": .dictionary(["$gte": .number(21.0)])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Less than filter")
    func lessThanFilter() {
        let filter = TestFilter.less(.age, 65)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "age": .dictionary(["$lt": .number(65.0)])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Less than or equal filter")
    func lessThanOrEqualFilter() {
        let filter = TestFilter.lessOrEqual(.age, 30)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "age": .dictionary(["$lte": .number(30.0)])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Array and Collection Filter Tests
    
    @Test("In filter with array of strings")
    func inFilterWithStringArray() {
        let filter = TestFilter.in(.name, ["John", "Jane", "Bob"])
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "name": .dictionary(["$in": .array([.string("John"), .string("Jane"), .string("Bob")])])
        ]
        
        #expect(json == expected)
    }
    
    @Test("In filter with array of integers")
    func inFilterWithIntegerArray() {
        let filter = TestFilter.in(.age, [18, 21, 25, 30])
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "age": .dictionary(["$in": .array([.number(18.0), .number(21.0), .number(25.0), .number(30.0)])])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Contains filter")
    func containsFilter() {
        let filter = TestFilter.contains(.tags, "swift")
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "tags": .dictionary(["$contains": .string("swift")])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Text Search Filter Tests
    
    @Test("Query filter")
    func queryFilter() {
        let filter = TestFilter.query(.name, "john")
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "name": .dictionary(["$q": .string("john")])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Autocomplete filter")
    func autocompleteFilter() {
        let filter = TestFilter.autocomplete(.name, "jo")
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "name": .dictionary(["$autocomplete": .string("jo")])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Existence Filter Tests
    
    @Test("Exists filter")
    func existsFilter() {
        let filter = TestFilter.exists(.email, true)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "email": .dictionary(["$exists": .bool(true)])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Path exists filter")
    func pathExistsFilter() {
        let filter = TestFilter.pathExists(.tags, "custom.field")
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "tags": .dictionary(["$path_exists": .string("custom.field")])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Complex Filter Tests
    
    @Test("And filter with multiple conditions")
    func testAndFilter() {
        let ageFilter = TestFilter.greater(.age, 18)
        let nameFilter = TestFilter.equal(.name, "John")
        let activeFilter = TestFilter.equal(.isActive, true)
        
        let andFilter = TestFilter.and([ageFilter, nameFilter, activeFilter])
        let json = andFilter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "$and": .array([
                .dictionary(["age": .dictionary(["$gt": .number(18.0)])]),
                .dictionary(["name": .dictionary(["$eq": .string("John")])]),
                .dictionary(["is_active": .dictionary(["$eq": .bool(true)])])
            ])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Or filter with multiple conditions")
    func testOrFilter() {
        let nameFilter1 = TestFilter.equal(.name, "John")
        let nameFilter2 = TestFilter.equal(.name, "Jane")
        
        let orFilter = TestFilter.or([nameFilter1, nameFilter2])
        let json = orFilter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "$or": .array([
                .dictionary(["name": .dictionary(["$eq": .string("John")])]),
                .dictionary(["name": .dictionary(["$eq": .string("Jane")])])
            ])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Nested and/or filters")
    func nestedAndOrFilters() {
        let ageFilter = TestFilter.greater(.age, 18)
        let nameFilter1 = TestFilter.equal(.name, "John")
        let nameFilter2 = TestFilter.equal(.name, "Jane")
        
        let orFilter = TestFilter.or([nameFilter1, nameFilter2])
        let andFilter = TestFilter.and([ageFilter, orFilter])
        
        let json = andFilter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "$and": .array([
                .dictionary(["age": .dictionary(["$gt": .number(18.0)])]),
                .dictionary([
                    "$or": .array([
                        .dictionary(["name": .dictionary(["$eq": .string("John")])]),
                        .dictionary(["name": .dictionary(["$eq": .string("Jane")])])
                    ])
                ])
            ])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - URL Filter Tests
    
    @Test("URL filter value")
    func uRLFilterValue() {
        let url = URL(string: "https://example.com")!
        let filter = TestFilter.equal(.email, url)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "email": .dictionary(["$eq": .string("https://example.com")])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Dictionary Filter Tests
    
    @Test("Dictionary filter value")
    func dictionaryFilterValue() {
        let customData: [String: RawJSON] = [
            "key1": .string("value1"),
            "key2": .number(42.0)
        ]
        let filter = TestFilter.equal(.tags, customData)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "tags": .dictionary(["$eq": .dictionary(customData)])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Array Filter Tests
    
    @Test("Array filter value")
    func arrayFilterValue() {
        let arrayValue = ["item1", "item2"]
        let filter = TestFilter.equal(.tags, arrayValue)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "tags": .dictionary(["$eq": .array([.string("item1"), .string("item2")])])
        ]
        
        #expect(json == expected)
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty array in filter")
    func emptyArrayInFilter() {
        let arrayValue: [String] = []
        let filter = TestFilter.in(.tags, arrayValue)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "tags": .dictionary(["$in": .array([])])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Empty and filter")
    func emptyAndFilter() {
        let subFilters: [TestFilter] = []
        let filter = TestFilter.and(subFilters)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "$and": .array([])
        ]
        
        #expect(json == expected)
    }
    
    @Test("Empty or filter")
    func emptyOrFilter() {
        let subFilters: [TestFilter] = []
        let filter = TestFilter.or(subFilters)
        let json = filter.toRawJSON()
        
        let expected: [String: RawJSON] = [
            "$or": .array([])
        ]
        
        #expect(json == expected)
    }
    
     // MARK: - Local Filter Matching
    
    @Test func filterMatchingEqual() {
        let ageFilter = TestFilter.equal(.age, 25)
        #expect(ageFilter.matches(TestUser(age: 25)))
        #expect(!ageFilter.matches(TestUser(age: 20)))
        
        let nameFilter = TestFilter.equal(.name, "John")
        #expect(nameFilter.matches(TestUser(name: "John")))
        #expect(!nameFilter.matches(TestUser(name: "Jane")))
        
        // Test diacritic string comparison
        let diacriticNameFilter = TestFilter.equal(.name, "José")
        #expect(diacriticNameFilter.matches(TestUser(name: "José")))
        #expect(!diacriticNameFilter.matches(TestUser(name: "Jose")))
        #expect(!diacriticNameFilter.matches(TestUser(name: "Jose")))
        
        let emailFilter = TestFilter.equal(.email, "john@getstream.io")
        #expect(emailFilter.matches(TestUser(email: "john@getstream.io")))
        #expect(!emailFilter.matches(TestUser(email: "jane@getstream.io")))
        
        let tagsFilter = TestFilter.equal(.tags, ["orange", "yellow"])
        #expect(tagsFilter.matches(TestUser(tags: ["orange", "yellow"])))
        #expect(!tagsFilter.matches(TestUser(tags: ["red", "blue"])))
        
        let isActiveFilter = TestFilter.equal(.isActive, true)
        #expect(isActiveFilter.matches(TestUser(isActive: true)))
        #expect(!isActiveFilter.matches(TestUser(isActive: false)))
        
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
        let createdAtFilter = TestFilter.equal(.createdAt, testDate)
        #expect(createdAtFilter.matches(TestUser(createdAt: testDate)))
        #expect(!createdAtFilter.matches(TestUser(createdAt: Date(timeIntervalSince1970: 1_640_995_201))))
        
        let heightFilter = TestFilter.equal(.height, 180.1)
        #expect(heightFilter.matches(TestUser(height: 180.1)))
        #expect(!heightFilter.matches(TestUser(height: 175.0)))
        
        let testURL = URL(string: "https://getstream.io")!
        let homepageFilter = TestFilter.equal(.homepage, testURL)
        #expect(homepageFilter.matches(TestUser(homepage: testURL)))
        #expect(!homepageFilter.matches(TestUser(homepage: URL(string: "https://example.com")!)))
        
        let testSearchData: [String: RawJSON] = [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam")
            ])
        ]
        let searchDataFilter = TestFilter.equal(.searchData, testSearchData)
        #expect(searchDataFilter.matches(TestUser(searchData: testSearchData)))
        #expect(!searchDataFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("US"),
                "city": .string("New York")
            ])
        ])))
    }
    
    @Test func filterMatchingIsGreater() {
        // Test Int property (age)
        let ageFilter = TestFilter.greater(.age, 25)
        #expect(ageFilter.matches(TestUser(age: 30)))  // 30 > 25
        #expect(ageFilter.matches(TestUser(age: 26)))  // 26 > 25
        #expect(!ageFilter.matches(TestUser(age: 25))) // 25 == 25 (not greater)
        #expect(!ageFilter.matches(TestUser(age: 20))) // 20 < 25
        
        // Test Double property (height)
        let heightFilter = TestFilter.greater(.height, 175.0)
        #expect(heightFilter.matches(TestUser(height: 180.1))) // 180.1 > 175.0
        #expect(heightFilter.matches(TestUser(height: 176.0))) // 176.0 > 175.0
        #expect(!heightFilter.matches(TestUser(height: 175.0))) // 175.0 == 175.0 (not greater)
        #expect(!heightFilter.matches(TestUser(height: 170.0))) // 170.0 < 175.0
        
        // Test Date property (createdAt)
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
        let laterDate = Date(timeIntervalSince1970: 1_640_995_201) // 2022-01-01 00:00:01 UTC
        let evenLaterDate = Date(timeIntervalSince1970: 1_640_995_300) // 2022-01-01 00:01:40 UTC
        let earlierDate = Date(timeIntervalSince1970: 1_640_995_199) // 2021-12-31 23:59:59 UTC
        
        let createdAtFilter = TestFilter.greater(.createdAt, testDate)
        #expect(createdAtFilter.matches(TestUser(createdAt: laterDate)))      // laterDate > testDate
        #expect(createdAtFilter.matches(TestUser(createdAt: evenLaterDate))) // evenLaterDate > testDate
        #expect(!createdAtFilter.matches(TestUser(createdAt: testDate)))     // testDate == testDate (not greater)
        #expect(!createdAtFilter.matches(TestUser(createdAt: earlierDate))) // earlierDate < testDate
        
        // Test diacritic string comparison
        let diacriticNameFilter = TestFilter.greater(.name, "José")
        #expect(diacriticNameFilter.matches(TestUser(name: "Joséa")))     // "Joséa" is greater than "José"
        #expect(diacriticNameFilter.matches(TestUser(name: "joséa")))     // "joséa" is greater than "José"
        #expect(!diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(!diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(!diacriticNameFilter.matches(TestUser(name: "Jose")))     // "Jose" is less than "José" (no accent)
        #expect(!diacriticNameFilter.matches(TestUser(name: "jose")))     // "jose" is less than "José" (no accent)
    }
    
    @Test func filterMatchingIsGreaterOrEqual() {
        // Test Int property (age)
        let ageFilter = TestFilter.greaterOrEqual(.age, 25)
        #expect(ageFilter.matches(TestUser(age: 30)))  // 30 >= 25
        #expect(ageFilter.matches(TestUser(age: 26)))  // 26 >= 25
        #expect(ageFilter.matches(TestUser(age: 25)))  // 25 >= 25
        #expect(!ageFilter.matches(TestUser(age: 20))) // 20 < 25
        
        // Test Double property (height)
        let heightFilter = TestFilter.greaterOrEqual(.height, 175.0)
        #expect(heightFilter.matches(TestUser(height: 180.1))) // 180.1 >= 175.0
        #expect(heightFilter.matches(TestUser(height: 176.0))) // 176.0 >= 175.0
        #expect(heightFilter.matches(TestUser(height: 175.0))) // 175.0 >= 175.0
        #expect(!heightFilter.matches(TestUser(height: 170.0))) // 170.0 < 175.0
        
        // Test Date property (createdAt)
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
        let laterDate = Date(timeIntervalSince1970: 1_640_995_201) // 2022-01-01 00:00:01 UTC
        let evenLaterDate = Date(timeIntervalSince1970: 1_640_995_300) // 2022-01-01 00:01:40 UTC
        let earlierDate = Date(timeIntervalSince1970: 1_640_995_199) // 2021-12-31 23:59:59 UTC
        
        let createdAtFilter = TestFilter.greaterOrEqual(.createdAt, testDate)
        #expect(createdAtFilter.matches(TestUser(createdAt: laterDate)))      // laterDate >= testDate
        #expect(createdAtFilter.matches(TestUser(createdAt: evenLaterDate))) // evenLaterDate >= testDate
        #expect(createdAtFilter.matches(TestUser(createdAt: testDate)))      // testDate >= testDate
        #expect(!createdAtFilter.matches(TestUser(createdAt: earlierDate))) // earlierDate < testDate
        
        // Test diacritic string comparison
        let diacriticNameFilter = TestFilter.greaterOrEqual(.name, "José")
        #expect(diacriticNameFilter.matches(TestUser(name: "Joséa")))     // "Joséa" is greater than "José"
        #expect(diacriticNameFilter.matches(TestUser(name: "joséa")))     // "joséa" is greater than "José"
        #expect(diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(!diacriticNameFilter.matches(TestUser(name: "Jose")))     // "Jose" is less than "José" (no accent)
        #expect(!diacriticNameFilter.matches(TestUser(name: "jose")))     // "jose" is less than "José" (no accent)
    }
    
    @Test func filterMatchingIsLess() {
        // Test Int property (age)
        let ageFilter = TestFilter.less(.age, 25)
        #expect(ageFilter.matches(TestUser(age: 20)))  // 20 < 25
        #expect(ageFilter.matches(TestUser(age: 24)))  // 24 < 25
        #expect(!ageFilter.matches(TestUser(age: 25))) // 25 == 25 (not less)
        #expect(!ageFilter.matches(TestUser(age: 30))) // 30 > 25
        
        // Test Double property (height)
        let heightFilter = TestFilter.less(.height, 175.0)
        #expect(heightFilter.matches(TestUser(height: 170.0))) // 170.0 < 175.0
        #expect(heightFilter.matches(TestUser(height: 174.9))) // 174.9 < 175.0
        #expect(!heightFilter.matches(TestUser(height: 175.0))) // 175.0 == 175.0 (not less)
        #expect(!heightFilter.matches(TestUser(height: 180.1))) // 180.1 > 175.0
        
        // Test Date property (createdAt)
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
        let laterDate = Date(timeIntervalSince1970: 1_640_995_201) // 2022-01-01 00:00:01 UTC
        let evenLaterDate = Date(timeIntervalSince1970: 1_640_995_300) // 2022-01-01 00:01:40 UTC
        let earlierDate = Date(timeIntervalSince1970: 1_640_995_199) // 2021-12-31 23:59:59 UTC
        
        let createdAtFilter = TestFilter.less(.createdAt, testDate)
        #expect(createdAtFilter.matches(TestUser(createdAt: earlierDate)))     // earlierDate < testDate
        #expect(!createdAtFilter.matches(TestUser(createdAt: testDate)))      // testDate == testDate (not less)
        #expect(!createdAtFilter.matches(TestUser(createdAt: laterDate)))     // laterDate > testDate
        #expect(!createdAtFilter.matches(TestUser(createdAt: evenLaterDate))) // evenLaterDate > testDate
        
        // Test diacritic string comparison
        let diacriticNameFilter = TestFilter.less(.name, "José")
        #expect(!diacriticNameFilter.matches(TestUser(name: "Joséa")))     // "Joséa" is greater than "José"
        #expect(!diacriticNameFilter.matches(TestUser(name: "joséa")))     // "joséa" is greater than "José"
        #expect(!diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(!diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(diacriticNameFilter.matches(TestUser(name: "Jose")))     // "Jose" is less than "José" (no accent)
        #expect(diacriticNameFilter.matches(TestUser(name: "jose")))     // "jose" is less than "José" (no accent)
    }
    
    @Test func filterMatchingIsLessOrEqual() {
        // Test Int property (age)
        let ageFilter = TestFilter.lessOrEqual(.age, 25)
        #expect(ageFilter.matches(TestUser(age: 20)))  // 20 <= 25
        #expect(ageFilter.matches(TestUser(age: 24)))  // 24 <= 25
        #expect(ageFilter.matches(TestUser(age: 25)))  // 25 <= 25
        #expect(!ageFilter.matches(TestUser(age: 30))) // 30 > 25
        
        // Test Double property (height)
        let heightFilter = TestFilter.lessOrEqual(.height, 175.0)
        #expect(heightFilter.matches(TestUser(height: 170.0))) // 170.0 <= 175.0
        #expect(heightFilter.matches(TestUser(height: 174.9))) // 174.9 <= 175.0
        #expect(heightFilter.matches(TestUser(height: 175.0))) // 175.0 <= 175.0
        #expect(!heightFilter.matches(TestUser(height: 180.1))) // 180.1 > 175.0
        
        // Test Date property (createdAt)
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
        let laterDate = Date(timeIntervalSince1970: 1_640_995_201) // 2022-01-01 00:00:01 UTC
        let evenLaterDate = Date(timeIntervalSince1970: 1_640_995_300) // 2022-01-01 00:01:40 UTC
        let earlierDate = Date(timeIntervalSince1970: 1_640_995_199) // 2021-12-31 23:59:59 UTC
        
        let createdAtFilter = TestFilter.lessOrEqual(.createdAt, testDate)
        #expect(createdAtFilter.matches(TestUser(createdAt: earlierDate)))     // earlierDate <= testDate
        #expect(createdAtFilter.matches(TestUser(createdAt: testDate)))      // testDate <= testDate
        #expect(!createdAtFilter.matches(TestUser(createdAt: laterDate)))     // laterDate > testDate
        #expect(!createdAtFilter.matches(TestUser(createdAt: evenLaterDate))) // evenLaterDate > testDate
        
        // Test diacritic string comparison
        let diacriticNameFilter = TestFilter.lessOrEqual(.name, "José")
        #expect(!diacriticNameFilter.matches(TestUser(name: "Joséa")))     // "Joséa" is greater than "José"
        #expect(!diacriticNameFilter.matches(TestUser(name: "joséa")))     // "joséa" is greater than "José"
        #expect(diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is equal
        #expect(diacriticNameFilter.matches(TestUser(name: "Jose")))     // "Jose" is less than "José" (no accent)
        #expect(diacriticNameFilter.matches(TestUser(name: "jose")))     // "jose" is less than "José" (no accent)
    }
    
    @Test func filterMatchingIn() {
        // Test Int property (age) with array of integers
        let ageFilter = TestFilter.in(.age, [18, 21, 25, 30])
        #expect(ageFilter.matches(TestUser(age: 18)))  // 18 is in [18, 21, 25, 30]
        #expect(ageFilter.matches(TestUser(age: 21)))  // 21 is in [18, 21, 25, 30]
        #expect(ageFilter.matches(TestUser(age: 25)))  // 25 is in [18, 21, 25, 30]
        #expect(ageFilter.matches(TestUser(age: 30)))  // 30 is in [18, 21, 25, 30]
        #expect(!ageFilter.matches(TestUser(age: 20))) // 20 is not in [18, 21, 25, 30]
        #expect(!ageFilter.matches(TestUser(age: 35))) // 35 is not in [18, 21, 25, 30]
        
        // Test Double property (height) with array of doubles
        let heightFilter = TestFilter.in(.height, [170.0, 175.0, 180.1, 185.0])
        #expect(heightFilter.matches(TestUser(height: 170.0))) // 170.0 is in [170.0, 175.0, 180.1, 185.0]
        #expect(heightFilter.matches(TestUser(height: 175.0))) // 175.0 is in [170.0, 175.0, 180.1, 185.0]
        #expect(heightFilter.matches(TestUser(height: 180.1))) // 180.1 is in [170.0, 175.0, 180.1, 185.0]
        #expect(heightFilter.matches(TestUser(height: 185.0))) // 185.0 is in [170.0, 175.0, 180.1, 185.0]
        #expect(!heightFilter.matches(TestUser(height: 172.5))) // 172.5 is not in [170.0, 175.0, 180.1, 185.0]
        #expect(!heightFilter.matches(TestUser(height: 190.0))) // 190.0 is not in [170.0, 175.0, 180.1, 185.0]
        
        // Test String property (name) with array of strings
        let nameFilter = TestFilter.in(.name, ["John", "Jane", "Bob", "Alice"])
        #expect(nameFilter.matches(TestUser(name: "John")))  // "John" is in ["John", "Jane", "Bob", "Alice"]
        #expect(nameFilter.matches(TestUser(name: "Jane")))  // "Jane" is in ["John", "Jane", "Bob", "Alice"]
        #expect(nameFilter.matches(TestUser(name: "Bob")))   // "Bob" is in ["John", "Jane", "Bob", "Alice"]
        #expect(nameFilter.matches(TestUser(name: "Alice"))) // "Alice" is in ["John", "Jane", "Bob", "Alice"]
        #expect(!nameFilter.matches(TestUser(name: "Mike"))) // "Mike" is not in ["John", "Jane", "Bob", "Alice"]
        #expect(!nameFilter.matches(TestUser(name: "Sarah"))) // "Sarah" is not in ["John", "Jane", "Bob", "Alice"]
        
        // Test diacritic string comparison
        let diacriticNameFilter = TestFilter.in(.name, ["José", "François", "Müller"])
        #expect(diacriticNameFilter.matches(TestUser(name: "José")))      // "José" is in ["José", "François", "Müller"]
        #expect(diacriticNameFilter.matches(TestUser(name: "François")))  // "François" is in ["José", "François", "Müller"]
        #expect(diacriticNameFilter.matches(TestUser(name: "Müller")))    // "Müller" is in ["José", "François", "Müller"]
        #expect(!diacriticNameFilter.matches(TestUser(name: "Jose")))     // "Jose" (no accent) is not in the array
        #expect(!diacriticNameFilter.matches(TestUser(name: "Francois"))) // "Francois" (no accent) is not in the array
        
        // Test Bool property (isActive) with array of booleans
        let isActiveFilter = TestFilter.in(.isActive, [true, false])
        #expect(isActiveFilter.matches(TestUser(isActive: true)))  // true is in [true, false]
        #expect(isActiveFilter.matches(TestUser(isActive: false))) // false is in [true, false]
        
        // Test Array property (tags) with array of string arrays
        let tagsFilter = TestFilter.in(.tags, [["orange", "yellow"], ["red", "blue"], ["green", "purple"]])
        #expect(tagsFilter.matches(TestUser(tags: ["orange", "yellow"]))) // ["orange", "yellow"] is in the array
        #expect(tagsFilter.matches(TestUser(tags: ["red", "blue"])))     // ["red", "blue"] is in the array
        #expect(tagsFilter.matches(TestUser(tags: ["green", "purple"]))) // ["green", "purple"] is in the array
        #expect(!tagsFilter.matches(TestUser(tags: ["black", "white"]))) // ["black", "white"] is not in the array
        #expect(!tagsFilter.matches(TestUser(tags: ["orange"])))         // ["orange"] is not in the array (partial match)
    }
    
    @Test func filterMatchingExists() {
        // Test exists: true - checking if properties exist
        let nameExistsFilter = TestFilter.exists(.name, true)
        #expect(nameExistsFilter.matches(TestUser(name: "John")))     // name property exists
        #expect(nameExistsFilter.matches(TestUser(name: "Jane")))     // name property exists
        #expect(nameExistsFilter.matches(TestUser(name: "")))         // name property exists even if empty string
        
        let ageExistsFilter = TestFilter.exists(.age, true)
        #expect(ageExistsFilter.matches(TestUser(age: 25)))          // age property exists
        #expect(ageExistsFilter.matches(TestUser(age: 0)))           // age property exists even if 0
        
        let heightExistsFilter = TestFilter.exists(.height, true)
        #expect(heightExistsFilter.matches(TestUser(height: 180.1))) // height property exists
        #expect(heightExistsFilter.matches(TestUser(height: 0.0)))   // height property exists even if 0.0
        
        let tagsExistsFilter = TestFilter.exists(.tags, true)
        #expect(tagsExistsFilter.matches(TestUser(tags: ["orange", "yellow"]))) // tags property exists
        #expect(tagsExistsFilter.matches(TestUser(tags: [])))                   // tags property exists even if empty array
        
        let isActiveExistsFilter = TestFilter.exists(.isActive, true)
        #expect(isActiveExistsFilter.matches(TestUser(isActive: true)))  // isActive property exists
        #expect(isActiveExistsFilter.matches(TestUser(isActive: false))) // isActive property exists even if false
        
        // Test exists: false - checking if properties don't exist
        // Note: Since TestUser always has these properties, we can't easily test exists: false
        // In a real scenario, this would be used with optional properties or properties that might be nil
        let nameNotExistsFilter = TestFilter.exists(.name, false)
        #expect(!nameNotExistsFilter.matches(TestUser(name: "John"))) // name property exists, so exists: false should not match
        
        let ageNotExistsFilter = TestFilter.exists(.age, false)
        #expect(!ageNotExistsFilter.matches(TestUser(age: 25)))      // age property exists, so exists: false should not match
        
        let heightNotExistsFilter = TestFilter.exists(.height, false)
        #expect(!heightNotExistsFilter.matches(TestUser(height: 180.1))) // height property exists, so exists: false should not match
        
        let tagsNotExistsFilter = TestFilter.exists(.tags, false)
        #expect(!tagsNotExistsFilter.matches(TestUser(tags: ["orange", "yellow"]))) // tags property exists, so exists: false should not match
        
        let isActiveNotExistsFilter = TestFilter.exists(.isActive, false)
        #expect(!isActiveNotExistsFilter.matches(TestUser(isActive: true)))  // isActive property exists, so exists: false should not match
        #expect(!isActiveNotExistsFilter.matches(TestUser(isActive: false))) // isActive property exists, so exists: false should not match
    }
    
    @Test func filterMatchingQuery() {
        // Test case-insensitive full text search with name property
        // $q should match substrings anywhere in the text (not just from beginning)
        let nameQueryFilter = TestFilter.query(.name, "john")
        #expect(nameQueryFilter.matches(TestUser(name: "John")))      // "John" contains "john" (case-insensitive)
        #expect(nameQueryFilter.matches(TestUser(name: "JOHN")))      // "JOHN" contains "john" (case-insensitive)
        #expect(nameQueryFilter.matches(TestUser(name: "john")))      // "john" contains "john" (exact match)
        #expect(nameQueryFilter.matches(TestUser(name: "Johnny")))    // "Johnny" contains "john" (case-insensitive)
        #expect(nameQueryFilter.matches(TestUser(name: "JOHNNY")))    // "JOHNNY" contains "john" (case-insensitive)
        #expect(!nameQueryFilter.matches(TestUser(name: "Jane")))     // "Jane" does not contain "john"
        #expect(!nameQueryFilter.matches(TestUser(name: "Bob")))      // "Bob" does not contain "john"
        
        // Test diacritic string comparison
        let diacriticQueryFilter = TestFilter.query(.name, "josé")
        #expect(diacriticQueryFilter.matches(TestUser(name: "José")))      // "José" contains "josé" (case-insensitive)
        #expect(diacriticQueryFilter.matches(TestUser(name: "JOSÉ")))      // "JOSÉ" contains "josé" (case-insensitive)
        #expect(diacriticQueryFilter.matches(TestUser(name: "josé")))      // "josé" contains "josé" (exact match)
        #expect(!diacriticQueryFilter.matches(TestUser(name: "Jose")))     // "Jose" (no accent) does not contain "josé"
        #expect(!diacriticQueryFilter.matches(TestUser(name: "jose")))     // "jose" (no accent) does not contain "josé"
        
        // Test case-insensitive full text search with email property
        let emailQueryFilter = TestFilter.query(.email, "GETSTREAM")
        #expect(emailQueryFilter.matches(TestUser(email: "john@getstream.io"))) // "john@getstream.io" contains "GETSTREAM" (case-insensitive)
        #expect(emailQueryFilter.matches(TestUser(email: "jane@GETSTREAM.io"))) // "jane@GETSTREAM.io" contains "GETSTREAM" (case-insensitive)
        #expect(emailQueryFilter.matches(TestUser(email: "admin@GetStream.com"))) // "admin@GetStream.com" contains "GETSTREAM" (case-insensitive)
        #expect(!emailQueryFilter.matches(TestUser(email: "john@example.com"))) // "john@example.com" does not contain "GETSTREAM"
        #expect(!emailQueryFilter.matches(TestUser(email: "user@other.io"))) // "user@other.io" does not contain "GETSTREAM"
        
        // Test full text search with middle substring matching
        // $q should find substrings anywhere in the text, not just at the beginning
        let middleQueryFilter = TestFilter.query(.name, "hn")
        #expect(middleQueryFilter.matches(TestUser(name: "John")))      // "John" contains "hn" in the middle
        #expect(middleQueryFilter.matches(TestUser(name: "JOHN")))      // "JOHN" contains "hn" in the middle
        #expect(middleQueryFilter.matches(TestUser(name: "john")))      // "john" contains "hn" in the middle
        #expect(!middleQueryFilter.matches(TestUser(name: "Jane")))     // "Jane" does not contain "hn"
        #expect(!middleQueryFilter.matches(TestUser(name: "Bob")))      // "Bob" does not contain "hn"
        
        // Test full text search with end substring matching
        let endQueryFilter = TestFilter.query(.name, "ny")
        #expect(endQueryFilter.matches(TestUser(name: "Johnny")))      // "Johnny" contains "ny" at the end
        #expect(endQueryFilter.matches(TestUser(name: "JOHNNY")))      // "JOHNNY" contains "ny" at the end
        #expect(!endQueryFilter.matches(TestUser(name: "John")))       // "John" does not contain "ny"
        #expect(!endQueryFilter.matches(TestUser(name: "Jane")))       // "Jane" does not contain "ny"
        
        // Test full text search with partial word matching
        let partialQueryFilter = TestFilter.query(.name, "jo")
        #expect(partialQueryFilter.matches(TestUser(name: "John")))     // "John" contains "jo" at the beginning
        #expect(partialQueryFilter.matches(TestUser(name: "JOHN")))     // "JOHN" contains "jo" at the beginning
        #expect(partialQueryFilter.matches(TestUser(name: "john")))     // "john" contains "jo" at the beginning
        #expect(partialQueryFilter.matches(TestUser(name: "Johnny")))   // "Johnny" contains "jo" at the beginning
        #expect(!partialQueryFilter.matches(TestUser(name: "Jane")))    // "Jane" does not contain "jo"
        #expect(!partialQueryFilter.matches(TestUser(name: "Bob")))     // "Bob" does not contain "jo"
    }
    
    @Test func filterMatchingAutocomplete() {
        // Test case-insensitive autocomplete with name property
        // $autocomplete should match from the beginning of the field value (anchored search)
        let nameAutocompleteFilter = TestFilter.autocomplete(.name, "jo")
        #expect(nameAutocompleteFilter.matches(TestUser(name: "John")))      // "John" starts with "jo" (case-insensitive)
        #expect(nameAutocompleteFilter.matches(TestUser(name: "JOHN")))      // "JOHN" starts with "jo" (case-insensitive)
        #expect(nameAutocompleteFilter.matches(TestUser(name: "john")))      // "john" starts with "jo" (case-insensitive)
        #expect(nameAutocompleteFilter.matches(TestUser(name: "Johnny")))    // "Johnny" starts with "jo" (case-insensitive)
        #expect(nameAutocompleteFilter.matches(TestUser(name: "JOHNNY")))    // "JOHNNY" starts with "jo" (case-insensitive)
        #expect(!nameAutocompleteFilter.matches(TestUser(name: "Jane")))     // "Jane" does not start with "jo"
        #expect(!nameAutocompleteFilter.matches(TestUser(name: "Bob")))      // "Bob" does not start with "jo"
        
        // Test diacritic string comparison
        let diacriticAutocompleteFilter = TestFilter.autocomplete(.name, "jos")
        #expect(diacriticAutocompleteFilter.matches(TestUser(name: "José")))      // "José" starts with "jos" (case-insensitive)
        #expect(diacriticAutocompleteFilter.matches(TestUser(name: "JOSÉ")))      // "JOSÉ" starts with "jos" (case-insensitive)
        #expect(diacriticAutocompleteFilter.matches(TestUser(name: "josé")))      // "josé" starts with "jos" (case-insensitive)
        
        // Test case-insensitive autocomplete with email property
        let emailAutocompleteFilter = TestFilter.autocomplete(.email, "JOHN")
        #expect(emailAutocompleteFilter.matches(TestUser(email: "john@getstream.io"))) // "john@getstream.io" starts with "JOHN" (case-insensitive)
        #expect(emailAutocompleteFilter.matches(TestUser(email: "JOHN@getstream.io"))) // "JOHN@getstream.io" starts with "JOHN" (case-insensitive)
        #expect(emailAutocompleteFilter.matches(TestUser(email: "john@example.com"))) // "john@example.com" starts with "JOHN" (case-insensitive)
        #expect(!emailAutocompleteFilter.matches(TestUser(email: "jane@getstream.io"))) // "jane@getstream.io" does not start with "JOHN"
        #expect(!emailAutocompleteFilter.matches(TestUser(email: "admin@getstream.io"))) // "admin@getstream.io" does not start with "JOHN"
        
        // Test autocomplete with single character
        let singleCharFilter = TestFilter.autocomplete(.name, "j")
        #expect(singleCharFilter.matches(TestUser(name: "John")))      // "John" starts with "j" (case-insensitive)
        #expect(singleCharFilter.matches(TestUser(name: "JOHN")))      // "JOHN" starts with "j" (case-insensitive)
        #expect(singleCharFilter.matches(TestUser(name: "john")))      // "john" starts with "j" (case-insensitive)
        #expect(singleCharFilter.matches(TestUser(name: "Johnny")))    // "Johnny" starts with "j" (case-insensitive)
        #expect(singleCharFilter.matches(TestUser(name: "Jane")))     // "Jane" starts with "j"
        #expect(!singleCharFilter.matches(TestUser(name: "Bob")))      // "Bob" does not start with "j"
        
        // Test autocomplete with longer prefix
        let longPrefixFilter = TestFilter.autocomplete(.name, "john")
        #expect(longPrefixFilter.matches(TestUser(name: "John")))      // "John" starts with "john" (case-insensitive)
        #expect(longPrefixFilter.matches(TestUser(name: "JOHN")))      // "JOHN" starts with "john" (case-insensitive)
        #expect(longPrefixFilter.matches(TestUser(name: "john")))      // "john" starts with "john" (case-insensitive)
        #expect(longPrefixFilter.matches(TestUser(name: "Johnny")))    // "Johnny" starts with "john" (case-insensitive)
        #expect(!longPrefixFilter.matches(TestUser(name: "Jane")))     // "Jane" does not start with "john"
        #expect(!longPrefixFilter.matches(TestUser(name: "Bob")))      // "Bob" does not start with "john"
        
        // Test autocomplete with middle substring (should NOT match)
        // $autocomplete is anchored to the beginning, so middle substrings should not match
        let middleSubstringFilter = TestFilter.autocomplete(.name, "hn")
        #expect(!middleSubstringFilter.matches(TestUser(name: "John")))      // "John" does not start with "hn"
        #expect(!middleSubstringFilter.matches(TestUser(name: "JOHN")))      // "JOHN" does not start with "hn"
        #expect(!middleSubstringFilter.matches(TestUser(name: "john")))      // "john" does not start with "hn"
        
        // Test autocomplete with end substring (should NOT match)
        let endSubstringFilter = TestFilter.autocomplete(.name, "ny")
        #expect(!endSubstringFilter.matches(TestUser(name: "Johnny")))      // "Johnny" does not start with "ny"
        #expect(!endSubstringFilter.matches(TestUser(name: "JOHNNY")))      // "JOHNNY" does not start with "ny"
    }
    
    @Test func filterMatchingContains() {
        // Test contains filter with array property (tags)
        let tagsContainsFilter = TestFilter.contains(.tags, "orange")
        #expect(tagsContainsFilter.matches(TestUser(tags: ["orange", "yellow"]))) // ["orange", "yellow"] contains "orange"
        #expect(tagsContainsFilter.matches(TestUser(tags: ["orange"])))         // ["orange"] contains "orange"
        #expect(tagsContainsFilter.matches(TestUser(tags: ["red", "orange", "blue"]))) // ["red", "orange", "blue"] contains "orange"
        #expect(!tagsContainsFilter.matches(TestUser(tags: ["red", "blue"])))  // ["red", "blue"] does not contain "orange"
        #expect(!tagsContainsFilter.matches(TestUser(tags: [])))              // [] does not contain "orange"
        
        // Test contains filter with dictionary property (searchData)
        let searchDataContainsFilter = TestFilter.contains(.searchData, [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam")
            ])
        ])
        #expect(searchDataContainsFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam")
            ])
        ]))) // searchData exact match
        
        #expect(searchDataContainsFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam"),
                "street": .string("Kleine-Gartmanplantsoen 21-6")
            ])
        ]))) // searchData contains the specified address dictionary
        
        #expect(searchDataContainsFilter.matches(TestUser(searchData: [
            "Address": .dictionary([
                "Country": .string("NL"),
                "City": .string("Amsterdam")
            ])
        ]))) // searchData caseinsesitive match
        
        #expect(!searchDataContainsFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("US"),
                "city": .string("New York")
            ])
        ]))) // searchData does not contain the specified address dictionary
        
        #expect(!searchDataContainsFilter.matches(TestUser(searchData: [
            "other_field": .string("value")
        ]))) // searchData does not contain the address field at all
        
        // Test contains filter with nested dictionary
        let nestedDictContainsFilter = TestFilter.contains(.searchData, [
            "address": .dictionary([
                "country": .string("NL")
            ])
        ])
        #expect(nestedDictContainsFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam")
            ])
        ]))) // searchData contains the nested country field
        
        #expect(!nestedDictContainsFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("US")
            ])
        ]))) // searchData does not contain the specified country value
        
        // Test contains filter with empty dictionary (edge case)
        let emptyDictContainsFilter = TestFilter.contains(.searchData, [:])
        #expect(emptyDictContainsFilter.matches(TestUser(searchData: [:])))    // [:] contains [:]
        #expect(!emptyDictContainsFilter.matches(TestUser(searchData: [
            "field": .string("value")
        ]))) // ["field": "value"] does not contain [:]
    }
    
    @Test func filterMatchingPathExists() {
        // Test pathExists filter with simple nested path
        let simplePathFilter = TestFilter.pathExists(.searchData, "address")
        #expect(simplePathFilter.matches(TestUser(searchData: [
            "Address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam")
            ])
        ]))) // searchData contains "address" field
        
        #expect(simplePathFilter.matches(TestUser(searchData: [
            "address": .dictionary([:]),
            "other_field": .string("value")
        ]))) // searchData contains "address" field even if empty
        
        #expect(!simplePathFilter.matches(TestUser(searchData: [
            "other_field": .string("value")
        ]))) // searchData does not contain "address" field
        
        // Test pathExists filter with deep nested path
        let deepPathFilter = TestFilter.pathExists(.searchData, "address.country")
        #expect(deepPathFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("NL"),
                "city": .string("Amsterdam")
            ])
        ]))) // searchData contains "address.country" path
        
        #expect(deepPathFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .string("US"),
                "state": .string("California")
            ])
        ]))) // searchData contains "address.country" path with different value
        
        #expect(!deepPathFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "city": .string("Amsterdam")
            ])
        ]))) // searchData does not contain "address.country" path
        
        #expect(!deepPathFilter.matches(TestUser(searchData: [
            "other_field": .string("value")
        ]))) // searchData does not contain "address" field at all
        
        // Test pathExists filter with very deep nested path
        let veryDeepPathFilter = TestFilter.pathExists(.searchData, "address.country.city.district")
        #expect(veryDeepPathFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .dictionary([
                    "city": .dictionary([
                        "district": .string("Centrum")
                    ])
                ])
            ])
        ]))) // searchData contains "address.country.city.district" path
        
        #expect(!veryDeepPathFilter.matches(TestUser(searchData: [
            "address": .dictionary([
                "country": .dictionary([
                    "city": .dictionary([
                        "neighborhood": .string("Centrum")
                    ])
                ])
            ])
        ]))) // searchData does not contain "address.country.city.district" path
        
        // Test pathExists filter with empty path (edge case)
        let emptyPathFilter = TestFilter.pathExists(.searchData, "")
        #expect(!emptyPathFilter.matches(TestUser(searchData: [
            "field": .string("value")
        ]))) // Empty path should not match anything
        
        // Test pathExists filter with single dot path (edge case)
        let singleDotPathFilter = TestFilter.pathExists(.searchData, ".")
        #expect(!singleDotPathFilter.matches(TestUser(searchData: [
            "field": .string("value")
        ]))) // Single dot path should not match anything
        
        // Test pathExists filter with non-dictionary root (should fail gracefully)
        let nonDictRootFilter = TestFilter.pathExists(.name, "subfield")
        #expect(!nonDictRootFilter.matches(TestUser(name: "John"))) // name is a string, not a dictionary
        
        // Test diacritic string comparison in path
        let diacriticPathFilter = TestFilter.pathExists(.searchData, "user.nom")
        #expect(diacriticPathFilter.matches(TestUser(searchData: [
            "user": .dictionary([
                "nom": .string("José")
            ])
        ]))) // searchData contains "user.nom" path with diacritic value
        
        #expect(!diacriticPathFilter.matches(TestUser(searchData: [
            "user": .dictionary([
                "name": .string("Jose")
            ])
        ]))) // searchData does not contain "user.nom" path (different field name)
    }
}
