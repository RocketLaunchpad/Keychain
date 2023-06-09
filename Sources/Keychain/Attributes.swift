//
//  Attributes.swift
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

/// Internal data structure to building and converting attribute dictionaries.
struct Attributes: ExpressibleByDictionaryLiteral {
    var dictionary: [CFString: Any]

    init(dictionaryLiteral elements: (CFString, Any)...) {
        var dictionary = [CFString: Any]()
        for (key, value) in elements {
            dictionary[key] = value
        }
        self.dictionary = dictionary
    }

    /// Adds the specified attributes, overwriting any existing keys.
    mutating func add(_ other: Attributes) {
        dictionary.merge(other.dictionary, uniquingKeysWith: { $1 })
    }

    /// Adds the specified attributes, overwriting any existing keys.
    func adding(_ other: Attributes) -> Attributes {
        var copy = self
        copy.add(other)
        return copy
    }

    /// Adds (and overwrites) the `value` for the `key`.
    mutating func add(key: CFString, value: Any) {
        dictionary[key] = value
    }

    /// Adds (and overwrites) the `value` for the `key`.
    func adding(key: CFString, value: Any) -> Attributes {
        var copy = self
        copy.add(key: key, value: value)
        return copy
    }

    /// Adds (and overwrites) the `boolValue` for the `key`.
    mutating func add(key: CFString, boolValue value: Bool) {
        dictionary[key] = (value ? kCFBooleanTrue : kCFBooleanFalse) as Any
    }

    /// Adds (and overwrites) the `boolValue` for the `key`.
    func adding(key: CFString, boolValue value: Bool) -> Attributes {
        var copy = self
        copy.add(key: key, boolValue: value)
        return copy
    }

    var asCFDictionary: CFDictionary {
        dictionary as CFDictionary
    }
}
