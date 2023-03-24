# Keychain

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
