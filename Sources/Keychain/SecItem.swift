import Foundation

enum SecItem {
    static let queue: DispatchQueue = DispatchQueue(label: "SecItem async queue")

    private static func error(with status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    static func add(attributes: Attributes) async throws {
        print("SecItem.add attributes: \(attributes)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemAdd(attributes.cfDictionary, nil)
                guard result == errSecSuccess else {
                    print("SecItem.add failed: \(result)")
                    continuation.resume(throwing: error(with: result))
                    return
                }

                print("SecItem.add succeeded")
                continuation.resume()
            }
        }
    }

    static func update(query: Attributes, attributesToUpdate: Attributes) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let status = SecItemUpdate(query.cfDictionary, attributesToUpdate.cfDictionary)
                guard status == errSecSuccess else {
                    continuation.resume(throwing: error(with: status))
                    return
                }

                continuation.resume()
            }
        }
    }

    static func delete(query: Attributes) async throws {
        print("SecItem.delete query: \(query)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemDelete(query.cfDictionary)
                guard result == errSecSuccess || result == errSecItemNotFound else {
                    print("SecItem.delete failed: \(result)")
                    continuation.resume(throwing: error(with: result))
                    return
                }
                print("SecItem.delete succeeded: \(result)")
                continuation.resume()
            }
        }
    }

    static func copyMatching<T>(query: Attributes) async throws -> T? {
        print("SecItem.copyMatching query: \(query)")
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T?, Error>) in
            queue.async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query.cfDictionary, &result)

                switch status {
                case errSecSuccess:
                    print("SecItem.copyMatching succeeded")
                    continuation.resume(returning: result as? T)

                case errSecItemNotFound:
                    print("SecItem.copyMatching not found")
                    continuation.resume(returning: nil)

                default:
                    print("SecItem.copyMatching failed: \(status)")
                    continuation.resume(throwing: error(with: status))
                }
            }
        }
    }
}
