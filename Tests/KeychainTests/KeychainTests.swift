@testable import Keychain
import XCTest

final class KeychainTests: XCTestCase {
    private var keychain: Keychain!

    override func setUpWithError() throws {
        super.setUp()

        let service = UUID().uuidString
        keychain = Keychain(service: service)
    }

    override func tearDownWithError() throws {
        try keychain.removeAllItems()

        super.tearDown()
    }

    func testAddThenGet() throws {
        let key: Keychain.Key = "addThenGet"

        // Add an item
        try keychain.set(value: "value", for: key)

        // Get the item
        XCTAssertEqual("value", try keychain.value(for: key))
    }

    func testAddThenDelete() throws {
        let key: Keychain.Key = "addThenDelete"

        try keychain.set(value: "value", for: key)
        XCTAssertTrue(try keychain.containsItem(for: key))

        try keychain.removeItem(for: key)
        XCTAssertFalse(try keychain.containsItem(for: key))
    }

    func testAllKeys() throws {
        let key1: Keychain.Key = "key1"
        let key2: Keychain.Key = "key2"

        try keychain.set(value: "value1", for: key1)
        try keychain.set(value: "value2", for: key2)

        XCTAssertEqual([key1, key2], try keychain.allKeys)
    }

    func testAllKeysAfterDelete() throws {
        let key1: Keychain.Key = "key1"
        let key2: Keychain.Key = "key2"

        try keychain.set(value: "value1", for: key1)
        try keychain.set(value: "value2", for: key2)

        XCTAssertEqual([key1, key2], try keychain.allKeys)

        try keychain.removeItem(for: key1)

        XCTAssertEqual([key2], try keychain.allKeys)
    }

    func testUpdate() throws {
        let key1: Keychain.Key = "key1"
        let key2: Keychain.Key = "key2"

        try keychain.set(value: "value1", for: key1)
        try keychain.set(value: "value2", for: key2)

        XCTAssertEqual("value1", try keychain.value(for: key1))
        XCTAssertEqual("value2", try keychain.value(for: key2))

        try keychain.set(value: "value3", for: key1)
        try keychain.set(value: "value4", for: key2)

        XCTAssertEqual("value3", try keychain.value(for: key1))
        XCTAssertEqual("value4", try keychain.value(for: key2))
    }

    func testFetchAfterDelete() throws {
        let key: Keychain.Key = "updateAfterDelete"

        try keychain.set(value: "value1", for: key)
        XCTAssertEqual("value1", try keychain.value(for: key))

        try keychain.removeItem(for: key)
        XCTAssertNil(try keychain.value(for: key) as String?)
    }

    func testDeleteAll() throws {
        let key1: Keychain.Key = "key1"
        let key2: Keychain.Key = "key2"
        let key3: Keychain.Key = "key3"

        try keychain.set(value: "value1", for: key1)
        try keychain.set(value: "value2", for: key2)
        try keychain.set(value: "value3", for: key3)

        try keychain.removeAllItems()

        XCTAssertEqual([], try keychain.allKeys)
    }
}
