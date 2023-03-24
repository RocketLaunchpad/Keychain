//
//  Accessibility.swift
//  KeychainTests
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

@testable import Keychain
import XCTest

final class KeychainTests: XCTestCase {
    private var keychain: Keychain!

    override func setUpWithError() throws {
        super.setUp()

        let service = UUID().uuidString
        keychain = Keychain(service: service)
    }

    override func tearDown() async throws {
        try await keychain.removeAllItems()
        try await super.tearDown()
    }

    func testAddThenGet() async throws {
        let key: Key = "addThenGet"

        // Add an item
        try await keychain.set(string: "value", for: key)

        // Get the item
        let value = try await keychain.string(for: key)
        XCTAssertEqual("value", value)
    }

    func testAddThenDelete() async throws {
        let key: Key = "addThenDelete"

        try await keychain.set(string: "value", for: key)
        let containsAfterSet = try await keychain.containsItem(for: key)
        XCTAssertTrue(containsAfterSet)

        try await keychain.removeItem(for: key)
        let containsAfterRemove = try await keychain.containsItem(for: key)
        XCTAssertFalse(containsAfterRemove)

        print("done")
    }

    func testAllKeys() async throws {
        let key1: Key = "key1"
        let key2: Key = "key2"

        try await keychain.set(string: "value1", for: key1)
        try await keychain.set(string: "value2", for: key2)

        let allKeys = try await keychain.allKeys
        XCTAssertEqual([key1, key2], allKeys)
    }

    func testAllKeysAfterRemove() async throws {
        let key1: Key = "key1"
        let key2: Key = "key2"

        try await keychain.set(string: "value1", for: key1)
        try await keychain.set(string: "value2", for: key2)

        let allKeysBeforeRemove = try await keychain.allKeys
        XCTAssertEqual([key1, key2], allKeysBeforeRemove)

        try await keychain.removeItem(for: key1)

        let allKeysAfterRemove = try await keychain.allKeys
        XCTAssertEqual([key2], allKeysAfterRemove)
    }

    func testUpdate() async throws {
        let key: Key = "key"

        NSLog("set value=value1 for key")
        try await keychain.set(string: "value1", for: key)
        NSLog("get value for key")
        let v1 = try await keychain.string(for: key)
        XCTAssertEqual("value1", v1)

        NSLog("set value=value2 for key")
        try await keychain.set(string: "value2", for: key)
        NSLog("get value for key")
        let v2 = try await keychain.string(for: key)
        XCTAssertEqual("value2", v2)
    }

    func testUpdateTwo() async throws {
        let key1: Key = "key1"
        let key2: Key = "key2"

        try await keychain.set(string: "value1", for: key1)
        try await keychain.set(string: "value2", for: key2)

        let v1 = try await keychain.string(for: key1)
        XCTAssertEqual("value1", v1)
        let v2 = try await keychain.string(for: key2)
        XCTAssertEqual("value2", v2)

        try await keychain.set(string: "value3", for: key1)
        try await keychain.set(string: "value4", for: key2)

        let v3 = try await keychain.string(for: key1)
        XCTAssertEqual("value3", v3)
        let v4 = try await keychain.string(for: key2)
        XCTAssertEqual("value4", v4)
    }

    func testFetchAfterDelete() async throws {
        let key: Key = "updateAfterDelete"

        try await keychain.set(string: "value1", for: key)
        let v1 = try await keychain.string(for: key)
        XCTAssertEqual("value1", v1)

        try await keychain.removeItem(for: key)
        let v2 = try await keychain.string(for: key)
        XCTAssertNil(v2)
    }

    func testDeleteAll() async throws {
        let key1: Key = "key1"
        let key2: Key = "key2"
        let key3: Key = "key3"

        try await keychain.set(string: "value1", for: key1)
        try await keychain.set(string: "value2", for: key2)
        try await keychain.set(string: "value3", for: key3)

        try await keychain.removeAllItems()
        let allKeys = try await keychain.allKeys
        XCTAssertEqual([], allKeys)

        print("done")
    }

    func testAccessibilityWhenPasscodeSetThisDeviceOnly() async throws {
        let key: Key = "key"
        try await keychain.set(string: "value", for: key, withAccessibility: .whenPasscodeSetThisDeviceOnly)

        let rawItem = try XCTUnwrap(fetchRawItem(service: keychain.service, account: "key"))
        XCTAssertEqual(rawItem[String(kSecAttrAccessible)] as? String, String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly))
    }

    private func fetchRawItem(service: String, account: String) -> [AnyHashable: Any]? {
        let query: [String: Any] = [
            String(kSecAttrService): service,
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrSynchronizable): kSecAttrSynchronizableAny,
            String(kSecReturnAttributes): kCFBooleanTrue as Any,
            String(kSecMatchLimit): kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? [AnyHashable: Any]
    }
}

// MARK: - README sample code

extension Key {
    static let aSecretMessage: Key = "aSecretMessage"
    static let aSecretValue: Key = "aSecretValue"
}

extension KeychainTests {

    func testReadmeDemo1() async throws {
        // Write to the keychain
        try await keychain.set(string: "Be sure to drink your Ovaltine", for: .aSecretMessage)

        // Read from the keychain
        let secretMessage = try await keychain.string(for: .aSecretMessage)
        XCTAssertEqual(secretMessage, "Be sure to drink your Ovaltine")

        // Delete from the keychain
        try await keychain.removeItem(for: .aSecretMessage)
    }

    struct UserDetails: Codable, Equatable {
        var username: String
        var password: String
    }

    func testReadmeDemo2() async throws {
        let user = UserDetails(username: "ralphie", password: "RedRyder123")

        // Write to the keychain
        try await keychain.set(value: user, for: .aSecretValue)

        // Read from the keychain
        let returningUser: UserDetails? = try await keychain.value(for: .aSecretValue)
        XCTAssertEqual(user, returningUser)

        // Delete from the keychain
        try await keychain.removeItem(for: .aSecretValue)
    }
}
