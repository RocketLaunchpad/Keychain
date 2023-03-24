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
        trace("SecItem.add attributes: \(attributes)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemAdd(attributes.cfDictionary, nil)
                guard result == errSecSuccess else {
                    trace("SecItem.add failed: \(result)")
                    continuation.resume(throwing: error(with: result))
                    return
                }

                trace("SecItem.add succeeded")
                continuation.resume()
            }
        }
    }

    static func delete(query: Attributes) async throws {
        trace("SecItem.delete query: \(query)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemDelete(query.cfDictionary)
                guard result == errSecSuccess || result == errSecItemNotFound else {
                    trace("SecItem.delete failed: \(result)")
                    continuation.resume(throwing: error(with: result))
                    return
                }
                trace("SecItem.delete succeeded: \(result)")
                continuation.resume()
            }
        }
    }

    static func copyMatching<T>(query: Attributes) async throws -> T? {
        trace("SecItem.copyMatching query: \(query)")
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T?, Error>) in
            queue.async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query.cfDictionary, &result)

                switch status {
                case errSecSuccess:
                    trace("SecItem.copyMatching succeeded")
                    continuation.resume(returning: result as? T)

                case errSecItemNotFound:
                    trace("SecItem.copyMatching not found")
                    continuation.resume(returning: nil)

                default:
                    trace("SecItem.copyMatching failed: \(status)")
                    continuation.resume(throwing: error(with: status))
                }
            }
        }
    }
}
