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

/// Wraps the system keychain, providing simplified access for securely storing
/// and retrieving `Data`, `String`, or `Codable` values.
///
/// Instances of this type are lightweight structs. Rather than retain them,
/// you can recreate whenever needed, ensuring you always use the same service
/// name.
///
public struct Keychain {

    /// The service name. This is used as the `kSecAttrService` attribute in
    /// each keychain item.
    public let service: String

    /// Simplifying assumption: all items are generic passwords
    private let itemClass = kSecClassGenericPassword

    /// Creates a new keychain instance using the specified service name.
    public init(service: String) {
        self.service = service
    }

    /// Creates an `NSError` for the specified `OSStatus` value.
    private func error(with status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    /// Base query attributes to return all items associated with this service
    /// and item class.
    private var queryForAll: Attributes {
        [
            kSecAttrService: service,
            kSecClass: itemClass,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
        ]
    }

    /// Base query for a given key.
    private func query(for key: Key) -> Attributes {
        queryForAll
            .adding(key.attributes)
    }

    /// Returns `true` if the keychain contains an item for the given key,
    /// `false` otherwise.
    public func containsItem(for key: Key) async throws -> Bool {
        try await data(for: key) != nil
    }

    /// Creates an item with data associated with the given key. If an item
    /// already exists for the given key, it is first deleted then re-added.
    public func set(
        data: Data,
        for key: Key,
        withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly
    ) async throws {
        // Rather than add and then update if add fails with errSecDuplicateItem,
        // we just delete then add.

        let delete = query(for: key)
        try await SecItem.delete(query: delete)

        let create = query(for: key)
            .adding(accessibility.attributes)
            .adding(key: kSecValueData, value: data)
            .adding(key: kSecUseDataProtectionKeychain, boolValue: true)

        try await SecItem.add(attributes: create)
    }

    /// Returns the data associated with the given key, or `nil` if no item
    /// is associated with the given key.
    public func data(for key: Key) async throws -> Data? {
        let query = query(for: key)
            .adding(key: kSecMatchLimit, value: kSecMatchLimitOne)
            .adding(key: kSecReturnData, boolValue: true)

        return try await SecItem.copyMatching(query: query)
    }

    /// Returns a set of all keys associated with this service.
    public var allKeys: Set<Key> {
        get async throws {
            let query = queryForAll
                .adding(key: kSecMatchLimit, value: kSecMatchLimitAll)
                .adding(key: kSecReturnAttributes, boolValue: true)

            guard let results: [[AnyHashable: Any]] = try await SecItem.copyMatching(query: query) else {
                return []
            }

            var keys = Set<Key>()
            for attributes in results {
                if let account = attributes[kSecAttrAccount] as? String {
                    keys.insert(Key(rawValue: account))
                }
            }
            return keys
        }
    }

    /// Deletes the item associated with the specified key.
    public func removeItem(for key: Key) async throws {
        let query = query(for: key)
        try await SecItem.delete(query: query)
    }

    /// Deletes all items associated with this service. Use with care.
    public func removeAllItems() async throws {
        let query = queryForAll
        try await SecItem.delete(query: query)
    }
}

// MARK: - String value accessors

public extension Keychain {

    /// Returns the string associated with the given key, or `nil` if no item
    /// is associated with the given key.
    func string(for key: Key) async throws -> String? {
        try await data(for: key).map {
            String(decoding: $0, as: UTF8.self)
        }
    }

    /// Creates an item with a string associated with the given key. If an item
    /// already exists for the given key, it is first deleted then re-added.
    func set(string: String, for key: Key, withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly) async throws {
        try await set(data: Data(string.utf8), for: key, withAccessibility: accessibility)
    }
}

// MARK: - Encodable/Decodable value accessors

public extension Keychain {

    /// Returns the `Decodable` value associated with the given key, or `nil` if no
    /// item is associated with the given key.
    func value<T>(for key: Key) async throws -> T? where T: Decodable {
        try await data(for: key).map {
            try JSONDecoder().decode(T.self, from: $0)
        }
    }

    /// Creates an item with a `Encodable value` associated with the given key.
    /// If an item already exists for the given key, it is first deleted then
    /// re-added.
    func set<T>(value: T, for key: Key, withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly) async throws where T: Encodable {
        try await set(data: try JSONEncoder().encode(value), for: key, withAccessibility: accessibility)
    }
}
