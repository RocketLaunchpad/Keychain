//
//  AsyncKeychain.swift
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

/// Background queue to perform keychain operations
private let queue: DispatchQueue = DispatchQueue(label: "SecItem async queue")

// Call this to perform all keychain operations
private func perform<T>(on queue: DispatchQueue, operation: @escaping () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        queue.async {
            do {
                try continuation.resume(returning: operation())
            }
            catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

/// Wraps the system keychain, providing simplified access for securely storing
/// and retrieving `Data`, `String`, or `Codable` values in an asynchronous
/// (non-blocking) manner.
///
/// Instances of this type are lightweight structs. Rather than retain them,
/// you can recreate whenever needed, ensuring you always use the same service
/// name.
///
/// `AsyncKeychain` provides an asynchronous interface to a `Keychain` instance.
/// It is preferred to the `Keychain` interface as it does not block the calling
/// thread.
///
public struct AsyncKeychain {

    /// The wrapped, synchronous Keychain instance.
    private let keychain: Keychain

    /// The service name. This is used as the `kSecAttrService` attribute in
    /// each keychain item.
    public var service: String {
        keychain.service
    }

    /// Creates a new keychain instance using the specified service name.
    public init(service: String) {
        self.keychain = Keychain(service: service)
    }

    /// Returns `true` if the keychain contains an item for the given key,
    /// `false` otherwise.
    public func containsItem(for key: Key) async throws -> Bool {
        try await perform(on: queue) {
            try keychain.containsItem(for: key)
        }
    }

    /// Creates an item with data associated with the given key. If an item
    /// already exists for the given key, it is first deleted then re-added.
    public func set(
        data: Data,
        for key: Key,
        withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly
    ) async throws {
        try await perform(on: queue) {
            try keychain.set(data: data, for: key, withAccessibility: accessibility)
        }
    }

    /// Returns the data associated with the given key, or `nil` if no item
    /// is associated with the given key.
    public func data(for key: Key) async throws -> Data? {
        try await perform(on: queue) {
            try keychain.data(for: key)
        }
    }

    /// Returns a set of all keys associated with this service.
    public var allKeys: Set<Key> {
        get async throws {
            try await perform(on: queue) {
                try keychain.allKeys
            }
        }
    }

    /// Deletes the item associated with the specified key.
    public func removeItem(for key: Key) async throws {
        try await perform(on: queue) {
            try keychain.removeItem(for: key)
        }
    }

    /// Deletes all items associated with this service. Use with care.
    public func removeAllItems() async throws {
        try await perform(on: queue) {
            try keychain.removeAllItems()
        }
    }
}

// MARK: - String value accessors

public extension AsyncKeychain {

    /// Returns the string associated with the given key, or `nil` if no item
    /// is associated with the given key.
    func string(for key: Key) async throws -> String? {
        try await perform(on: queue) {
            try keychain.string(for: key)
        }
    }

    /// Creates an item with a string associated with the given key. If an item
    /// already exists for the given key, it is first deleted then re-added.
    func set(string: String, for key: Key, withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly) async throws {
        try await perform(on: queue) {
            try keychain.set(string: string, for: key, withAccessibility: accessibility)
        }
    }
}

// MARK: - Encodable/Decodable value accessors

public extension AsyncKeychain {

    /// Returns the `Decodable` value associated with the given key, or `nil` if no
    /// item is associated with the given key.
    func value<T>(for key: Key) async throws -> T? where T: Decodable {
        try await perform(on: queue) {
            try keychain.value(for: key)
        }
    }

    /// Creates an item with a `Encodable value` associated with the given key.
    /// If an item already exists for the given key, it is first deleted then
    /// re-added.
    func set<T>(value: T, for key: Key, withAccessibility accessibility: Accessibility = .whenUnlockedThisDeviceOnly) async throws where T: Encodable {
        try await perform(on: queue) {
            try keychain.set(value: value, for: key, withAccessibility: accessibility)
        }
    }
}

// MARK: - Default AsyncKeychain

public extension AsyncKeychain {

    /// Creates an `AsyncKeychain`, using `Bundle.main.bundleIdentifier` as the
    /// service. If `Bundle.main.bundleIdentifier` is `nil`, a fatal error is
    /// raised.
    ///
    static var `default`: AsyncKeychain {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("Cannot find main bundle identifier")
        }
        return AsyncKeychain(service: bundleID)
    }
}
