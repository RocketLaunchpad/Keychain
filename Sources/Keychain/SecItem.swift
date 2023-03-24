import Foundation

enum SecItem {
    static let queue: DispatchQueue = DispatchQueue(label: "SecItem async queue")

    private static func error(with status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    static func add(attributes: Attributes) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemAdd(attributes.cfDictionary, nil)
                guard result == errSecSuccess else {
                    continuation.resume(throwing: error(with: result))
                    return
                }

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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let result = SecItemDelete(query.cfDictionary)
                guard result == errSecSuccess || result == errSecItemNotFound else {
                    continuation.resume(throwing: error(with: result))
                    return
                }
                continuation.resume()
            }
        }
    }

    static func copyMatching<T>(query: Attributes) async throws -> T? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T?, Error>) in
            queue.async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query.cfDictionary, &result)

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
