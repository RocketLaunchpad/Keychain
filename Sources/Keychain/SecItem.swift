import Foundation

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

    static func update(query: Attributes, attributesToUpdate: Attributes) async throws {
        trace("SecItem.update query: \(query) attributesToUpdate: \(attributesToUpdate)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let status = SecItemUpdate(query.cfDictionary, attributesToUpdate.cfDictionary)
                guard status == errSecSuccess else {
                    trace("SecItem.update failed: \(status)")
                    continuation.resume(throwing: error(with: status))
                    return
                }

                trace("SecItem.update succeeded")
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
