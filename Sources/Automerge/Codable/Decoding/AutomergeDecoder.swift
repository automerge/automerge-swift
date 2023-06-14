import Foundation

public struct AutomergeDecoder {
    public var codingPath: [CodingKey]

    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public let doc: Document

    public init(doc: Document) {
        self.doc = doc
        codingPath = []
    }

    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
        let decoder = AutomergeDecoderImpl(
            doc: doc,
            userInfo: userInfo,
            codingPath: []
        )
        return try decoder.decode(T.self)
    }

    @inlinable public func decode<T: Decodable>(_: T.Type, from path: [CodingKey]) throws -> T {
        let decoder = AutomergeDecoderImpl(
            doc: doc,
            userInfo: userInfo,
            codingPath: path
        )
        return try decoder.decode(T.self)
    }
}
