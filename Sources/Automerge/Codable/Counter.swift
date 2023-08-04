import Combine
import Foundation
import struct SwiftUI.Binding

/// A type that represents the value of an Automerge counter.
public final class Counter: ObservableObject, Codable {
    var doc: Document?
    var objId: ObjId?
    var codingkey: AnyCodingKey?
    var _unboundStorage: Int

    // MARK: Initializers and Bind

    /// Creates a new, unbound counter.
    /// - Parameter initialValue: An initial string value for the text reference.
    public init(_ initialValue: Int = 0) {
        _unboundStorage = initialValue
    }

    /// Creates a new text reference instance bound within an Automerge document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    ///   - initialValue: An initial string value for the text reference.
    public convenience init(_ initialValue: Int = 0, doc: Document, path: String) throws {
        self.init(initialValue)
        try bind(doc: doc, path: path)
    }

    public convenience init(doc: Document, objId: ObjId, key: AnyCodingKey) throws {
        self.init()
        if let index = key.intValue {
            if case .Scalar(.Counter(_)) = try doc.get(obj: objId, index: UInt64(index)) {
                self.doc = doc
                self.objId = objId
                codingkey = key
            } else {
                throw BindingError.NotCounter
            }
        } else {
            if case .Scalar(.Counter(_)) = try doc.get(obj: objId, key: key.stringValue) {
                self.doc = doc
                self.objId = objId
                codingkey = key
            } else {
                throw BindingError.NotCounter
            }
        }
    }

    public var isBound: Bool {
        doc != nil && objId != nil
    }

    /// Binds a text reference instance info an Automerge document.
    ///
    /// If the instance has an initial value other than an empty string, binding update the string within the Automerge
    /// document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    public func bind(doc: Document, path: String) throws {
        guard let objId = try doc.lookupPath(path: path) else {
            throw BindingError.InvalidPath(path)
        }
        guard let key = try AnyCodingKey.parsePath(path).last else {
            throw BindingError.InvalidPath(path)
        }
        if let index = key.intValue {
            if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, index: UInt64(index)) {
                self.doc = doc
                self.objId = objId
                codingkey = key
                // Set an initial value on bind, if it's not zero
                if _unboundStorage != 0 {
                    let bindingDifference = counterValue - Int64(_unboundStorage)
                    try doc.increment(obj: objId, index: UInt64(index), by: bindingDifference)
                }
            } else {
                throw BindingError.NotCounter
            }
        } else {
            if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, key: key.stringValue) {
                self.doc = doc
                self.objId = objId
                codingkey = key
                // Set an initial value on bind, if it's not zero
                if _unboundStorage != 0 {
                    let bindingDifference = counterValue - Int64(_unboundStorage)
                    try doc.increment(obj: objId, key: key.stringValue, by: bindingDifference)
                }
            } else {
                throw BindingError.NotCounter
            }
        }
    }

    // MARK: Exposing Int value and Binding<Int>

    /// The value of the counter.
    public var value: Int {
        get {
            guard let doc, let objId, let codingkey else {
                return _unboundStorage
            }
            do {
                if let index = codingkey.intValue {
                    if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, index: UInt64(index)) {
                        return Int(counterValue)
                    }
                } else {
                    if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, key: codingkey.stringValue) {
                        return Int(counterValue)
                    }
                }
            } catch {
                fatalError("Error attempting to read text value from objectId \(objId): \(error)")
            }
            fatalError()
        }
        set {
            guard let objId, let doc, let codingkey else {
                _unboundStorage = newValue
                return
            }
            do {
                if let index = codingkey.intValue {
                    if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, index: UInt64(index)) {
                        let bindingDifference = counterValue - Int64(newValue)
                        try doc.increment(obj: objId, index: UInt64(index), by: bindingDifference)
                    } else {
                        throw BindingError.NotCounter
                    }
                } else {
                    if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, key: codingkey.stringValue) {
                        let bindingDifference = counterValue - Int64(newValue)
                        try doc.increment(obj: objId, key: codingkey.stringValue, by: bindingDifference)
                    } else {
                        throw BindingError.NotCounter
                    }
                }
            } catch {
                fatalError("Error attempting to write '\(newValue)' to objectId \(objId): \(error)")
            }
        }
    }

    public func increment(by value: Int) {
        guard let objId, let doc, let codingkey else {
            _unboundStorage += value
            return
        }
        do {
            if let index = codingkey.intValue {
                if case .Scalar(.Counter(_)) = try doc.get(obj: objId, index: UInt64(index)) {
                    try doc.increment(obj: objId, index: UInt64(index), by: Int64(value))
                } else {
                    throw BindingError.NotCounter
                }
            } else {
                if case .Scalar(.Counter(_)) = try doc.get(obj: objId, key: codingkey.stringValue) {
                    try doc.increment(obj: objId, key: codingkey.stringValue, by: Int64(value))
                } else {
                    throw BindingError.NotCounter
                }
            }
        } catch {
            fatalError(
                "Error attempting to increment counter by '\(value)' to objectId \(objId) key \(codingkey): \(error)"
            )
        }
    }

    /// Returns a binding to the string value of a text object within an Automerge document.
    //    public func valueBinding() -> Binding<Int> {
    //        Binding(
    //            get: { () -> String in
    //                guard let doc = self.doc, let objId = self.objId else {
    //                    return self._unboundStorage
    //                }
    //                do {
    //                    return try doc.text(obj: objId)
    //                } catch {
    //                    fatalError("Error attempting to read text value from objectId \(objId): \(error)")
    //                }
    //            },
    //            set: { (newValue: String) in
    //                guard let objId = self.objId, self.doc != nil else {
    //                    self._unboundStorage = newValue
    //                    return
    //                }
    //                do {
    //                    try self.updateText(newText: newValue)
    //                } catch {
    //                    fatalError("Error attempting to write '\(newValue)' to objectId \(objId): \(error)")
    //                }
    //            }
    //        )
    //    }

    // MARK: Codable conformance

    private enum CodingKeys: String, CodingKey {
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _unboundStorage = try container.decode(Int.self, forKey: .value)
    }
}

// MARK: Counter Conversions

/// A failure to convert an Automerge scalar value to or from a signer integer counter representation.
// public enum CounterScalarConversionError: LocalizedError {
//    case notCounterValue(_ val: Value)
//    case notCounterScalarValue(_ val: ScalarValue)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notCounterValue(val):
//            return "Failed to read the value \(val) as a signed integer counter."
//        case let .notCounterScalarValue(val):
//            return "Failed to read the scalar value \(val) as a signed integer counter."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

// extension Counter: ScalarValueRepresentable {
//    public typealias ConvertError = CounterScalarConversionError
//
//    public static func fromValue(_ val: Value) -> Result<Counter, CounterScalarConversionError> {
//        switch val {
//        case let .Scalar(.Counter(d)):
//            return .success(Counter(d))
//        default:
//            return .failure(CounterScalarConversionError.notCounterValue(val))
//        }
//    }
//
//    public static func fromScalarValue(_ val: ScalarValue) -> Result<Counter, CounterScalarConversionError> {
//        switch val {
//        case let .Counter(d):
//            return .success(Counter(d))
//        default:
//            return .failure(CounterScalarConversionError.notCounterScalarValue(val))
//        }
//    }
//
//    public func toScalarValue() -> ScalarValue {
//        .Counter(Int64(value))
//    }
// }
