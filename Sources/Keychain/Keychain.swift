//
//  Keychain.swift
//  Keychain
//
//  Copyright (c) 2023 DEPT Digital Products, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public struct Keychain {

    public let service: String

    /// Simplifying assumption: all items are generic passwords
    private let itemClass = kSecClassGenericPassword

    /// Creates a new keychain instance using the specified service name.
    public init(service: String) {
        self.service = service
    }

    private func error(with status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    private var commonAttributes: Attributes {
        [
            String(kSecAttrService): service,
            String(kSecClass): itemClass,
            String(kSecAttrSynchronizable): kSecAttrSynchronizableAny,
        ]
    }

    public func containsItem(for key: Key) async throws -> Bool {
        try await data(for: key) != nil
    }

    public func set(
        data: Data,
        for key: Key,
        withAccessibility accessibility: Accessibility? = nil,
        isSynchronizable synchronizable: Bool = false
    ) async throws {
        // Initial implementation did:
        //
        // if try await containsItem(for: key) {
        //     try await SecItem.update(query:attributesToUpdate:)
        // }
        // else {
        //     try await SecItem.add(attributes:)
        // }
        //
        // This works on iOS but fails on macOS.
        //
        // Changing the implementation to delete (succeeds even if the query
        // finds no items) then add, which works on iOS and macOS.

        let query = commonAttributes
            .merging(with: key.attributes)

        try await SecItem.delete(query: query)

        let create = commonAttributes
            .merging(with: key.attributes)
            .merging(with: accessibility?.attributes)
            .adding(key: kSecAttrSynchronizable, boolValue: synchronizable)
            .adding(key: kSecValueData, value: data)
            .adding(key: kSecUseDataProtectionKeychain, boolValue: true)

        try await SecItem.add(attributes: create)
    }

    public func data(for key: Key) async throws -> Data? {
        let query = commonAttributes
            .merging(with: key.attributes)
            .adding(key: kSecMatchLimit, value: kSecMatchLimitOne)
            .adding(key: kSecReturnData, boolValue: true)

        return try await SecItem.copyMatching(query: query)
    }

    public var allKeys: Set<Key> {
        get async throws {
            let query = commonAttributes
                .adding(key: kSecMatchLimit, value: kSecMatchLimitAll)
                .adding(key: kSecReturnAttributes, boolValue: true)

            guard let results: [[AnyHashable: Any]] = try await SecItem.copyMatching(query: query) else {
                return []
            }

            var keys = Set<Key>()
            for attributes in results {
                if let account = attributes[kSecAttrAccount] as? String {
                    keys.insert(Key(account))
                }
            }
            return keys
        }
    }

    public func removeItem(for key: Key) async throws {
        let query = commonAttributes
            .merging(with: key.attributes)

        try await SecItem.delete(query: query)
    }

    public func removeAllItems() async throws {
        let query = commonAttributes
        try await SecItem.delete(query: query)
    }
}

// MARK: - String value accessors

public extension Keychain {
    func string(for key: Key) async throws -> String? {
        try await data(for: key).map {
            String(decoding: $0, as: UTF8.self)
        }
    }

    func set(
        string: String,
        for key: Key,
        withAccessibility accessibility: Accessibility? = nil,
        isSynchronizable synchronizable: Bool = false
    ) async throws {
        try await set(
            data: Data(string.utf8),
            for: key,
            withAccessibility: accessibility,
            isSynchronizable: synchronizable
        )
    }
}

// MARK: - Encodable/Decodable value accessors

public extension Keychain {
    func value<T>(for key: Key) async throws -> T?
    where T: Decodable {
        try await data(for: key).map {
            try JSONDecoder().decode(T.self, from: $0)
        }
    }

    func set<T>(
        value: T,
        for key: Key,
        withAccessibility accessibility: Accessibility? = nil,
        isSynchronizable synchronizable: Bool = false
    ) async throws
    where T: Encodable {
        try await set(
            data: try JSONEncoder().encode(value),
            for: key,
            withAccessibility: accessibility,
            isSynchronizable: synchronizable
        )
    }
}
