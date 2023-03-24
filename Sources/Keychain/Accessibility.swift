//
//  Accessibility.swift
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

///
/// Specifies when the keychain item is accessible and whether it is
/// synchronizable.
///
/// The cases of this enum correspond to values of the `kSecAttrAccessible`
/// attribute. The `synchronizable` option (`kSecAttrSynchronizable`) is only
/// provided for accessibility options where it makes sense (i.e., options that
/// do not specify "this device only"). This is consistent with the
/// documentation for `kSecAttrSynchronizable`, which states:
///
/// > Items stored or obtained using the `kSecAttrSynchronizable` key may not
/// also specify a `kSecAttrAccessible` value that is incompatible with syncing
/// (namely, those whose names end with ThisDeviceOnly).
///
public enum Accessibility {

    /// See `kSecAttrWhenPasscodeSetThisDeviceOnly` for details.
    case whenPasscodeSetThisDeviceOnly

    /// See `kSecAttrWhenUnlockedThisDeviceOnly` for details.
    case whenUnlockedThisDeviceOnly

    /// See `kSecAttrAfterFirstUnlockThisDeviceOnly` for details.
    case afterFirstUnlockThisDeviceOnly

    /// See `kSecAttrWhenUnlocked` for details. The `isSynchronizable` value is
    /// used for the `kSecAttrSynchronizable` attribute value.
    case whenUnlocked(isSynchronizable: Bool)

    /// See `kSecAttrAfterFirstUnlock` for details. The `isSynchronizable` value
    /// is used for the `kSecAttrSynchronizable` attribute value.
    case afterFirstUnlock(isSynchronizable: Bool)

    var attributes: Attributes {
        let attributes: Attributes = [kSecAttrAccessible: kSecAttrAccessibleAttributeValue]

        if let isSynchronizable {
            return attributes
                .adding(key: kSecAttrSynchronizable, boolValue: isSynchronizable)
        }
        else {
            return attributes
        }
    }

    var isSynchronizable: Bool? {
        switch self {
        case let .whenUnlocked(isSynchronizable), let .afterFirstUnlock(isSynchronizable):
            return isSynchronizable

        default:
            return nil
        }
    }

    var kSecAttrAccessibleAttributeValue: CFString {
        switch self {
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly

        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked

        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        }
    }
}
