import Foundation

public struct Key: ExpressibleByStringLiteral, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral: String) {
        self.rawValue = stringLiteral
    }

    var attributes: Attributes {
        [
            String(kSecAttrAccount): rawValue
        ]
    }
}
