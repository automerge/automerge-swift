import Foundation

struct AutomergeSingleValueDecodingContainer: SingleValueDecodingContainer {
    let impl: AutomergeDecoderImpl
    let value: Value
    let codingPath: [CodingKey]

    let objectId: ObjId

    init(impl: AutomergeDecoderImpl, codingPath: [CodingKey], automergeValue: Value, objectId: ObjId) {
        self.impl = impl
        self.codingPath = codingPath
        value = automergeValue
        self.objectId = objectId
    }

    func decodeNil() -> Bool {
        value == .Scalar(.Null)
    }

    func decode(_: Bool.Type) throws -> Bool {
        guard case let .Scalar(.Boolean(bool)) = value else {
            throw createTypeMismatchError(type: Bool.self, value: value)
        }

        return bool
    }

    func decode(_: String.Type) throws -> String {
        guard case let .Scalar(.String(string)) = value else {
            throw createTypeMismatchError(type: String.self, value: value)
        }

        return string
    }

    func decode(_: Double.Type) throws -> Double {
        guard case let .Scalar(.F64(double)) = value else {
            throw createTypeMismatchError(type: Double.self, value: value)
        }
        return double
    }

    func decode(_: Float.Type) throws -> Float {
        guard case let .Scalar(.F64(double)) = value else {
            throw createTypeMismatchError(type: Double.self, value: value)
        }
        return Float(double)
    }

    func decode(_: Int.Type) throws -> Int {
        guard case let .Scalar(.Int(intValue)) = value else {
            throw createTypeMismatchError(type: Int.self, value: value)
        }
        return Int(intValue)
    }

    func decode(_: Int8.Type) throws -> Int8 {
        guard case let .Scalar(.Int(intValue)) = value else {
            throw createTypeMismatchError(type: Int8.self, value: value)
        }
        return Int8(intValue)
    }

    func decode(_: Int16.Type) throws -> Int16 {
        guard case let .Scalar(.Int(intValue)) = value else {
            throw createTypeMismatchError(type: Int16.self, value: value)
        }
        return Int16(intValue)
    }

    func decode(_: Int32.Type) throws -> Int32 {
        guard case let .Scalar(.Int(intValue)) = value else {
            throw createTypeMismatchError(type: Int32.self, value: value)
        }
        return Int32(intValue)
    }

    func decode(_: Int64.Type) throws -> Int64 {
        guard case let .Scalar(.Int(intValue)) = value else {
            throw createTypeMismatchError(type: Int64.self, value: value)
        }
        return intValue
    }

    func decode(_: UInt.Type) throws -> UInt {
        guard case let .Scalar(.Uint(uintValue)) = value else {
            throw createTypeMismatchError(type: UInt.self, value: value)
        }
        return UInt(uintValue)
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        guard case let .Scalar(.Uint(uintValue)) = value else {
            throw createTypeMismatchError(type: UInt8.self, value: value)
        }
        return UInt8(uintValue)
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        guard case let .Scalar(.Uint(uintValue)) = value else {
            throw createTypeMismatchError(type: UInt16.self, value: value)
        }
        return UInt16(uintValue)
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        guard case let .Scalar(.Uint(uintValue)) = value else {
            throw createTypeMismatchError(type: UInt32.self, value: value)
        }
        return UInt32(uintValue)
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        guard case let .Scalar(.Uint(uintValue)) = value else {
            throw createTypeMismatchError(type: UInt64.self, value: value)
        }
        return uintValue
    }

    mutating func decode<S>(_: S.Type) throws -> S where S: ScalarValueRepresentable {
        if case let .Scalar(scalarValue) = value {
            let conversionResult = S.fromScalarValue(scalarValue)
            switch conversionResult {
            case let .success(success):
                return success
            case let .failure(failure):
                throw DecodingError.typeMismatch(S.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(S.self) but found \(value) instead.",
                    underlyingError: failure
                ))
            }
        } else {
            throw createTypeMismatchError(type: S.self, value: value)
        }
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        switch T.self {
        case is Date.Type:
            if case let .Scalar(.Timestamp(date)) = value {
                return date as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't a `.timestamp`."
                ))
            }
        case is Data.Type:
            if case let .Scalar(.Bytes(data)) = value {
                return data as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't a `.data`."
                ))
            }
        case is Counter.Type:
            guard let finalKey = codingPath.last else {
                throw DecodingError.keyNotFound(
                    codingPath as! CodingKey,
                    .init(
                        codingPath: codingPath,
                        debugDescription: "coding path doesn't have a final key to decode into a counter"
                    )
                )
            }
            if case .Scalar(.Counter) = value {
                return try Counter(doc: impl.doc, objId: objectId, key: AnyCodingKey(finalKey)) as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't a `.counter`."
                ))
            }
        case is AutomergeText.Type:
            if case .Scalar(.String(_)) = value {
                let reference = try AutomergeText(doc: impl.doc, objId: objectId)
                return reference as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't `.text`."
                ))
            }

        default:
            return try T(from: impl)
        }
    }
}

extension AutomergeSingleValueDecodingContainer {
    @inline(__always) private func createTypeMismatchError(type: Any.Type, value: Value) -> DecodingError {
        DecodingError.typeMismatch(type, .init(
            codingPath: codingPath,
            debugDescription: "Expected to decode \(type) but found \(TypeOfAutomergeValue.from(value)) instead."
        ))
    }
}
