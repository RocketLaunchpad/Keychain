# Keychain

This library provides a simple wrapper around the iOS and macOS Keychain.

## Usage

First, define a key to use:

```swift
extension Key {
    static let aSecretMessage: Key = "aSecretMessage"
    static let aSecretValue: Key = "aSecretValue"
}
```

Next, create an instance of `Keychain`. This is a lightweight struct, so you don't need to retain this. You can create another instance whenever needed.

Use that instance of `Keychain` to set, get, and delete values associated with a `Key`.

```swift
let keychain = Keychain(service: "your-service-name")

// Write to the keychain
try await keychain.set(string: "Be sure to drink your Ovaltine", for: .aSecretMessage)

// Read from the keychain
let secretMessage = try await keychain.string(for: .aSecretMessage)

// Delete from the keychain
try await keychain.removeItem(for: .aSecretMessage)
```

`Keychain` also supports associating `Codable` values with a `Key`:

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

## Why async?

The underlying API calls wrapped by this library (`SecItemAdd`, `SecItemCopyMatching`, and `SecItemDelete`) all block the calling thread. The library uses a dispatch queue to perform the work asynchronously and uses continuations with async and await to signal the work is complete.

## Entitlements

The library requires your target include the _Keychain Sharing_ entitlement. Select your project, then select your target. Under Signing & Capabilities, click the **+ Capability** button and select _Keychain Sharing_.

If you do not include this entitlement, you will see errors like this:

```
Error Domain=NSOSStatusErrorDomain Code=-34018 "(null)"
```

Error -34018 is `errSecMissingEntitlement`.

## Project Structure and Entitlements

If you open `Package.swift` in Xcode and run the tests (iOS Simulator or Mac), the tests will fail with the entitlement error listed above. You cannot add entitlements to a Swift package.

The entitlement is required to run on iOS regardless. It is required to run on Mac because we specify `kSecUseDataProtectionKeychain` when creating/updating keychain items.

As such, you need to open `Keychain.xcodeproj` instead of `Package.swift` during development.

Since entitlements cannot be added to a Swift package (regardless of whether you're loading it via Package.swift or an Xcode Project), we need to use a test host application to run the tests. The host application, KeychainTestsHost, includes the necessary entitlements.
