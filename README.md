# Keychain

## Xcode Project

If you open `Package.swift` in Xcode and run the tests in the iOS Simulator, the tests will fail with the following error:

```
Error Domain=NSOSStatusErrorDomain Code=-34018 "(null)"
```

Error -34018 is `errSecMissingEntitlement`. You cannot add entitlements to a Swift package. The test target should be "My Mac" in order to work around this issue.
