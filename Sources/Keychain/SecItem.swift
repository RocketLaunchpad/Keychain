//
//  SecItem.swift
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

/// Internal functions to call SecItem functions asynchronously on a queue.
enum SecItem {
    static let queue: DispatchQueue = DispatchQueue(label: "SecItem async queue")

    private static func error(with status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    static func add(attributes: Attributes) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemAdd(attributes.asCFDictionary, nil)
                guard result == errSecSuccess else {
                    continuation.resume(throwing: error(with: result))
                    return
                }
                continuation.resume()
            }
        }
    }

    static func delete(query: Attributes) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemDelete(query.asCFDictionary)
                guard result == errSecSuccess || result == errSecItemNotFound else {
                    continuation.resume(throwing: error(with: result))
                    return
                }
                continuation.resume()
            }
        }
    }

    static func copyMatching<T>(query: Attributes) async throws -> T? {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T?, Error>) in
            queue.async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query.asCFDictionary, &result)

                switch status {
                case errSecSuccess:
                    continuation.resume(returning: result as? T)

                case errSecItemNotFound:
                    continuation.resume(returning: nil)

                default:
                    continuation.resume(throwing: error(with: status))
                }
            }
        }
    }
}
