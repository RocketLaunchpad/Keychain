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
/// and retrieving `Data`, `String`, or `Codable` values in a synchronous
/// (blocking) manner.
///
/// Instances of this type are lightweight structs. Rather than retain them,
/// you can recreate whenever needed, ensuring you always use the same service
/// name.
///
/// You should use `Keychain` only when you need synchronous access to the
/// keychain. This should generally occur on a background queue, as the
/// underlying API calls (`SecItemAdd`, `SecItemCopyMatching`, and
/// `SecItemDelete`) all block the calling thread.
///
/// All other times, you should consider using `AsyncKeychain` which provides
/// an equivalent asynchronous API.
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
    public func containsItem(for key: Key) throws -> Bool {
        try data(for: key) != nil
    }

    /// Creates an item with data associated with the given key. If an item
    /// already exists for the given key, it is first deleted then re-added.
    public func set(
        data: Data,
        for key: Key,
        withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly
    ) throws {
        // Rather than add and then update if add fails with errSecDuplicateItem,
        // we just delete then add.

        let delete = query(for: key)
        try SecItem.delete(query: delete)

        let create = query(for: key)
            .adding(accessibility.attributes)
            .adding(key: kSecValueData, value: data)
            .adding(key: kSecUseDataProtectionKeychain, boolValue: true)

        try SecItem.add(attributes: create)
    }

    /// Returns the data associated with the given key, or `nil` if no item
    /// is associated with the given key.
    public func data(for key: Key) throws -> Data? {
        let query = query(for: key)
            .adding(key: kSecMatchLimit, value: kSecMatchLimitOne)
            .adding(key: kSecReturnData, boolValue: true)

        return try SecItem.copyMatching(query: query)
    }

    /// Returns a set of all keys associated with this service.
    public var allKeys: Set<Key> {
        get throws {
            let query = queryForAll
                .adding(key: kSecMatchLimit, value: kSecMatchLimitAll)
                .adding(key: kSecReturnAttributes, boolValue: true)

            guard let results: [[AnyHashable: Any]] = try SecItem.copyMatching(query: query) else {
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
    public func removeItem(for key: Key) throws {
        let query = query(for: key)
        try SecItem.delete(query: query)
    }

    /// Deletes all items associated with this service. Use with care.
    public func removeAllItems() throws {
        let query = queryForAll
        try SecItem.delete(query: query)
    }
}

// MARK: - String value accessors

public extension Keychain {

    /// Returns the string associated with the given key, or `nil` if no item
    /// is associated with the given key.
    func string(for key: Key) throws -> String? {
        try data(for: key).map {
            String(decoding: $0, as: UTF8.self)
        }
    }

    /// Creates an item with a string associated with the given key. If an item
    /// already exists for the given key, it is first deleted then re-added.
    func set(string: String, for key: Key, withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly) throws {
        try set(data: Data(string.utf8), for: key, withAccessibility: accessibility)
    }
}

// MARK: - Encodable/Decodable value accessors

public extension Keychain {

    /// Returns the `Decodable` value associated with the given key, or `nil` if no
    /// item is associated with the given key.
    func value<T>(for key: Key) throws -> T? where T: Decodable {
        try data(for: key).map {
            try JSONDecoder().decode(T.self, from: $0)
        }
    }

    /// Creates an item with a `Encodable value` associated with the given key.
    /// If an item already exists for the given key, it is first deleted then
    /// re-added.
    func set<T>(value: T, for key: Key, withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly) throws where T: Encodable {
        try set(data: try JSONEncoder().encode(value), for: key, withAccessibility: accessibility)
    }
}

// MARK: - Default Keychain

public extension Keychain {

    /// Creates a `Keychain`, using `Bundle.main.bundleIdentifier` as the
    /// service. If `Bundle.main.bundleIdentifier` is `nil`, a fatal error is
    /// raised.
    ///
    static var `default`: Keychain {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("Cannot find main bundle identifier")
        }
        return Keychain(service: bundleID)
    }
}
