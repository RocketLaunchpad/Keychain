# Keychain

This library provides a simple wrapper around the iOS and macOS Keychain.

## Usage

There are two keychain wrappers provided: `Keychain` and `AsyncKeychain`. Both are lightweight structs, so you don't need to retain them. You can create instances whenever needed.

The underlying APIs (`SecItemAdd`, `SecItemCopyMatching`, and `SecItemDelete`) all block the calling thread. A `Keychain` instance provides a synchronous, blocking interface to the keychain. An `AsyncKeychain` provides an equivalent asynchronous, non-blocking interface to the keychain.

Generally speaking, you should use `AsyncKeychain`, especially when accessing with the keychain from the main thread. You should only use `Keychain` from a background thread, or when you absolutely need to access the keychain synchronously.

The examples provided here use `AsyncKeychain` but will all work with `Keychain` if you remove the `await` keyword.

Keychain items are associated with a `Key` which identifies the data. You can extend `Key` in your app to define the keys you will use:

```swift
extension Key {
    static let aSecretMessage: Key = "aSecretMessage"
    static let aSecretValue: Key = "aSecretValue"
}
```

Next, create an instance of `Keychain` or `AsyncKeychain`. Use that instance to set, get, and delete values associated with a `Key`.

```swift
let keychain = AsyncKeychain(service: "your-service-name")

// Write to the keychain
try await keychain.set(string: "Be sure to drink your Ovaltine", for: .aSecretMessage)

// Read from the keychain
let secretMessage = try await keychain.string(for: .aSecretMessage)

// Delete from the keychain
try await keychain.removeItem(for: .aSecretMessage)
```

You can also associate `Codable` values with a `Key`:

```swift
struct UserDetails: Codable {
    var username: String
    var password: String
}

let user = UserDetails(username: "ralphie", password: "RedRyder123")

// Write to the keychain
try await keychain.set(value: user, for: .aSecretValue)

// Read from the keychain
let returningUser: UserDetails? = try await keychain.value(for: .aSecretValue)

// Delete from the keychain
try await keychain.removeItem(for: .aSecretValue)
```

## Error Codes

The underlying APIs all return `OSStatus` values. When the library encounters an `OSStatus` value that indicates an error, it throws a `KeychainError` with the status and an error description obtained from `SecCopyErrorMessageString`.

If you encounter a `KeychainError` with status -34018 (`errSecMissingEntitlement`, "A required entitlement isn't present.") your use of the keychain requires the _Keychain Sharing_ entitlement. In Xcode, select your project, then select your target. Under Signing & Capabilities, click the **+ Capability** button and select _Keychain Sharing_.

## Project Structure and Entitlements

If you open `Package.swift` in Xcode and run the tests (iOS Simulator or Mac), the tests will fail with the entitlement error listed above. You cannot add entitlements to a Swift package.

For development in the library itself, you will need to open `Keychain.xcodeproj` instead of `Package.swift`. The xcodeproj provides a simple test host app, `KeychainTestsHost`, to run the unit tests in. That test host has the required _Keychain Sharing_ entitlement.

