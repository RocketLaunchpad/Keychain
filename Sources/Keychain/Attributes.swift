import Foundation

struct Attributes: ExpressibleByDictionaryLiteral {
    var dictionary: [String: Any]

    init(dictionaryLiteral elements: (String, Any)...) {
        var dictionary = [String: Any]()
        for (key, value) in elements {
            dictionary[key] = value
        }
        self.dictionary = dictionary
    }

    mutating func merge(with other: Attributes?) {
        guard let other else { return }
        dictionary.merge(other.dictionary, uniquingKeysWith: { $1 })
    }

    func merging(with other: Attributes?) -> Attributes {
        var copy = self
        copy.merge(with: other)
        return copy
    }

    mutating func add(key: CFString, value: Any) {
        dictionary[String(key)] = value
    }

    mutating func add(key: CFString, boolValue value: Bool) {
        dictionary[String(key)] = (value ? kCFBooleanTrue : kCFBooleanFalse) as Any
    }

    func adding(key: CFString, value: Any) -> Attributes {
        var copy = self
        copy.add(key: key, value: value)
        return copy
    }

    func adding(key: CFString, boolValue value: Bool) -> Attributes {
        var copy = self
        copy.add(key: key, boolValue: value)
        return copy
    }

    var cfDictionary: CFDictionary {
        dictionary as CFDictionary
    }
}

