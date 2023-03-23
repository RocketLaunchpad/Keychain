import Foundation

public struct Keychain {

    public let service: String

    /// Simplifying assumption: all items are generic passwords
    private let itemClass = kSecClassGenericPassword

    /// Creates a new keychain instance using the specified service name.
    public init(service: String) {
        self.service = service
    }

    private func error(with status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    private var baseQuery: Query {
        [
            String(kSecAttrService): service,
            String(kSecClass): itemClass,
            String(kSecAttrSynchronizable): kSecAttrSynchronizableAny,
        ]
    }

    private func cfBoolean(_ value: Bool) -> Any {
        (value ? kCFBooleanTrue : kCFBooleanFalse) as Any
    }

    private func subquery(withAccessibility accessibility: Accessibility?) -> Query {
        accessibility?.query ?? [:]
    }

    private func subquery(isSynchronizable synchronizable: Bool) -> Query {
        [
            String(kSecAttrSynchronizable): cfBoolean(synchronizable),
        ]
    }

    private func subquery(withData data: Data) -> Query {
        [
            String(kSecValueData): data
        ]
    }

    public func containsItem(for key: Key) throws -> Bool {
        let query = baseQuery
            .merging(with: key.query)

        var result: AnyObject?
        let status = SecItemCopyMatching(query.cfDictionary, &result)

        switch status {
        case errSecSuccess:
            return true

        case errSecItemNotFound:
            return false

        default:
            throw error(with: status)
        }
    }

    public func set(data: Data, for key: Key, withAccessibility accessibility: Accessibility? = nil, isSynchronizable synchronizable: Bool = false) throws {
        if try containsItem(for: key) {
            let query = baseQuery
                .merging(with: key.query)

            let update = subquery(withAccessibility: accessibility)
                .merging(with: subquery(isSynchronizable: synchronizable))
                .merging(with: subquery(withData: data))

            let status = SecItemUpdate(query.cfDictionary, update.cfDictionary)
            guard status == errSecSuccess else {
                throw error(with: status)
            }
        }
        else {
            let create = baseQuery
                .merging(with: key.query)
                .merging(with: subquery(withAccessibility: accessibility))
                .merging(with: subquery(isSynchronizable: synchronizable))
                .merging(with: subquery(withData: data))

            let status = SecItemAdd(create.cfDictionary, nil)
            guard status == errSecSuccess else {
                throw error(with: status)
            }
        }
    }

    public func data(for key: Key) throws -> Data? {
        let query = baseQuery
            .merging(with: key.query)
            .merging(with: [
                String(kSecMatchLimit): kSecMatchLimitOne,
                String(kSecReturnData): kCFBooleanTrue as Any,
            ])

        var result: AnyObject?
        let status = SecItemCopyMatching(query.cfDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data

        case errSecItemNotFound:
            return nil

        default:
            throw error(with: status)
        }
    }

    public var allKeys: Set<Key> {
        get throws {
            let query = baseQuery
                .merging(with: [
                    String(kSecMatchLimit): kSecMatchLimitAll,
                    String(kSecReturnAttributes): kCFBooleanTrue as Any,
                ])

            var result: AnyObject?
            let status = SecItemCopyMatching(query.cfDictionary, &result)

            switch status {
            case errSecSuccess:
                break

            case errSecItemNotFound:
                return []

            default:
                throw error(with: status)
            }

            var keys = Set<Key>()

            if let results = result as? [[AnyHashable: Any]] {
                for attributes in results {
                    if let account = attributes[kSecAttrAccount] as? String {
                        keys.insert(Key(account))
                    }
                }
            }

            return keys
        }
    }

    public func removeItem(for key: Key) throws {
        let query = baseQuery
            .merging(with: key.query)

        let status = SecItemDelete(query.cfDictionary)

        switch status {
        case errSecSuccess, errSecItemNotFound:
            return

        default:
            throw error(with: status)
        }
    }

    public func removeAllItems() throws {
        let query = baseQuery
            .merging(with: [
                String(kSecMatchLimit): kSecMatchLimitAll,
            ])
        let status = SecItemDelete(query.cfDictionary)

        switch status {
        case errSecSuccess, errSecItemNotFound:
            return

        default:
            throw error(with: status)
        }
    }
}

extension Keychain {
    // TODO: Rename to Attributes
    struct Query: ExpressibleByDictionaryLiteral {
        var dictionary: [String: Any]

        init(dictionaryLiteral elements: (String, Any)...) {
            var dictionary = [String: Any]()
            for (key, value) in elements {
                dictionary[key] = value
            }
            self.dictionary = dictionary
        }

        mutating func merge(with other: Query) {
            dictionary.merge(other.dictionary, uniquingKeysWith: { $1 })
        }

        func merging(with other: Query) -> Query {
            var copy = self
            copy.merge(with: other)
            return copy
        }

        var cfDictionary: CFDictionary {
            dictionary as CFDictionary
        }
    }
}

extension Keychain {
    public struct Key: ExpressibleByStringLiteral, Hashable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral: String) {
            self.rawValue = stringLiteral
        }

        var query: Query {
            [
                String(kSecAttrAccount): rawValue
            ]
        }
    }

    public enum Accessibility {
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case whenUnlocked
        case afterFirstUnlockThisDeviceOnly
        case afterFirstUnlock

        var query: Query {
            [
                String(kSecAttrAccessible): queryValue
            ]
        }

        private var queryValue: CFString {
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
}

public extension Keychain {
    func value<T>(for key: Key) throws -> T?
    where T: Decodable {
        try data(for: key).map {
            try JSONDecoder().decode(T.self, from: $0)
        }
    }

    func set<T>(value: T, for key: Key, withAccessibility accessibility: Accessibility? = nil, isSynchronizable synchronizable: Bool = false) throws
    where T: Encodable {
        try set(data: try JSONEncoder().encode(value), for: key, withAccessibility: accessibility, isSynchronizable: synchronizable)
    }
}
