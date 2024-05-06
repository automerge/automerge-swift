import Foundation

/// A type that represents the value of an Automerge counter.
///
/// Counter is a reference-type that you can create without an existing Automerge document, increment,
/// and later save into an Automerge document be encoding using ``AutomergeEncoder``, or by
/// calling the ``bind(doc:path:)`` function  to link the type into an existing Automerge document.
///
/// As a reference type, `Counter` updates the underlying Automerge document when a value is explicitly
/// set, or ``increment(by:)`` is called on the instance.
public final class Counter: Codable, @unchecked Sendable {
    var doc: Document?
    var objId: ObjId?
    var codingkey: AnyCodingKey?
    var _hashOfCurrentValue: Int
    #if canImport(Combine)
    var observerHandle: AnyCancellable?
    #endif
    var _unboundStorage: Int

    #if !os(WASI)
    fileprivate let queue = DispatchQueue(label: "automergecounter-sync-queue", qos: .userInteractive)
    fileprivate func sync<T>(execute work: () throws -> T) rethrows -> T {
        try queue.sync(execute: work)
    }
    #else
    fileprivate func sync<T>(execute work: () throws -> T) rethrows -> T {
        try work()
    }
    #endif

    // MARK: Initializers and Bind

    /// Creates a new, unbound counter.
    /// - Parameter initialValue: An initial string value for the text reference.
    public init(_ initialValue: Int = 0) {
        _unboundStorage = initialValue
        _hashOfCurrentValue = initialValue.hashValue
    }

    /// Creates a new Counter reference instance bound within an Automerge document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Counter` within the Automerge document.
    ///   - initialValue: An initial string value for the text reference.
    ///
    /// The initializer can throw an error if the `path` provided doesn't match to a counter type
    /// stored in the Automerge document you provide.
    public convenience init(_ initialValue: Int = 0, doc: Document, path: String) throws {
        self.init(initialValue)
        try bind(doc: doc, path: path)
    }

    /// Creates a new Counter reference instance bound within an Automerge document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - objId: A string path that represents the object that contains a `Value` within the Automerge document.
    ///   - key: The key (index position or dictionary key) on the `objId` provided.
    public convenience init(doc: Document, objId: ObjId, key: any CodingKey) throws {
        self.init()
        // TODO: convert this, akin to Text, to create an instance at the path provided
        if let index = key.intValue {
            if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, index: UInt64(index)) {
                sync {
                    self.doc = doc
                    self.objId = objId
                    codingkey = AnyCodingKey(key)
                    _hashOfCurrentValue = counterValue.hashValue
                }
            } else {
                throw BindingError.NotCounter
            }
        } else {
            if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, key: key.stringValue) {
                sync {
                    self.doc = doc
                    self.objId = objId
                    codingkey = AnyCodingKey(key)
                    _hashOfCurrentValue = counterValue.hashValue
                }
            } else {
                throw BindingError.NotCounter
            }
        }
        observeDocForChanges()
    }

    deinit {
        #if canImport(Combine)
        observerHandle?.cancel()
        #endif
    }

    /// Returns a Boolean value that indicates wether this reference type is actively updating an Automerge document.
    public var isBound: Bool {
        sync {
            doc != nil && objId != nil
        }
    }

    /// Binds a text reference instance info an Automerge document.
    ///
    /// If the instance has an initial value other than an empty string, binding update the string within the Automerge
    /// document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    public func bind(doc: Document, path: String) throws {
        let objId: ObjId
        let codingPath = try AnyCodingKey.parsePath(path)
        let lookupResult = doc.retrieveObjectId(path: codingPath, containerType: .Value, strategy: .readonly)
        switch lookupResult {
        case let .success(success):
            objId = success
        case let .failure(failure):
            throw failure
        }
        guard let key = codingPath.last else {
            throw BindingError.InvalidPath(path)
        }
        if let index = key.intValue {
            if case .Scalar(.Counter) = try doc.get(obj: objId, index: UInt64(index)) {
                sync {
                    self.doc = doc
                    self.objId = objId
                    codingkey = key
                }
                let currentUnboundValue = sync { self._unboundStorage }
                if currentUnboundValue != 0 {
                    // If the unbound counter has been adjusted, positive or negative, use
                    // that as an increment value on the existing counter to ensure that
                    // all the counter changes are maintained and appended to each other.
                    try doc.increment(obj: objId, index: UInt64(index), by: Int64(_unboundStorage))
                    sync {
                        _unboundStorage = 0
                    }
                }
            } else {
                throw BindingError.NotCounter
            }
        } else {
            if case .Scalar(.Counter) = try doc.get(obj: objId, key: key.stringValue) {
                sync {
                    self.doc = doc
                    self.objId = objId
                    codingkey = key
                }
                let currentUnboundValue = sync { self._unboundStorage }
                if currentUnboundValue != 0 {
                    // If the unbound counter has been adjusted, positive or negative, use
                    // that as an increment value on the existing counter to ensure that
                    // all the counter changes are maintained and appended to each other.
                    try doc.increment(obj: objId, key: key.stringValue, by: Int64(_unboundStorage))
                    sync {
                        _unboundStorage = 0
                    }
                }
            } else {
                throw BindingError.NotCounter
            }
        }
        observeDocForChanges()
    }

    private func observeDocForChanges() {
        #if canImport(Combine)
        guard let doc = doc else {
            return
        }
        // Admittedly, this is the _least_ efficient way to handle change update notifications
        // from the Automerge document. As the number of AutomergeText instances grows on a single
        // document, the amount of processing grows - each has to receive the signal from the
        // document, and then (optimally) do any comparisons to determine if the local instance has
        // changed.
        //
        // However, for a relatively few number of AutomergeText instances per document, there's not
        // outrageous overhead, and this code is the easiest (most localized) to put in place to a
        // change signal properly operational.
        if observerHandle == nil {
            observerHandle = doc.objectWillChange.sink(receiveValue: { [weak self] _ in
                guard let self else {
                    return
                }
                // This is firing off in a concurrent task explicitly to leave the synchronous
                // context that can happen when a doc is being updated and Combine is triggering
                // a change notification.
                let _hashOfCurrentValue = sync { self._hashOfCurrentValue }
                Task {
                    let currentValue = self.getCounterValue()
                    if currentValue.hashValue != _hashOfCurrentValue {
                        self.sendObjectWillChange()
                    }
                }
            })
        }
        #endif
    }

    // MARK: Exposing Int value and Binding<Int>

    /// The value of the counter.
    public var value: Int {
        get {
            getCounterValue()
        }
        set {
            setCounterValue(newValue)
        }
    }

    fileprivate func getCounterValue() -> Int {
        guard let doc, let objId, let codingkey else {
            return sync {
                _unboundStorage
            }
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

    fileprivate func setCounterValue(_ intValue: Int) {
        _hashOfCurrentValue = sync { intValue.hashValue }
        guard let objId, let doc, let codingkey else {
            sync { _unboundStorage = intValue }
            return
        }
        do {
            if let index = codingkey.intValue {
                if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, index: UInt64(index)) {
                    let bindingDifference = Int64(intValue) - counterValue
                    try doc.increment(obj: objId, index: UInt64(index), by: bindingDifference)
                } else {
                    throw BindingError.NotCounter
                }
            } else {
                if case let .Scalar(.Counter(counterValue)) = try doc.get(obj: objId, key: codingkey.stringValue) {
                    let bindingDifference = Int64(intValue) - counterValue
                    try doc.increment(obj: objId, key: codingkey.stringValue, by: bindingDifference)
                } else {
                    throw BindingError.NotCounter
                }
            }
        } catch {
            fatalError("Error attempting to write '\(intValue)' to objectId \(objId): \(error)")
        }
    }

    /// Updates the counter, incrementing or decrementing by the value you provide.
    /// - Parameter value: The value to add (or subtract) from the counter.
    public func increment(by value: Int) {
        guard let objId, let doc, let codingkey else {
            sync {
                _unboundStorage += value
                _hashOfCurrentValue = _unboundStorage.hashValue
            }
            return
        }
        do {
            if let index = codingkey.intValue {
                if case let .Scalar(.Counter(currentValue)) = try doc.get(obj: objId, index: UInt64(index)) {
                    try doc.increment(obj: objId, index: UInt64(index), by: Int64(value))
                    sync {
                        _hashOfCurrentValue = (Int(currentValue) + value).hashValue
                    }
                } else {
                    throw BindingError.NotCounter
                }
            } else {
                if case let .Scalar(.Counter(currentValue)) = try doc.get(obj: objId, key: codingkey.stringValue) {
                    try doc.increment(obj: objId, key: codingkey.stringValue, by: Int64(value))
                    sync {
                        _hashOfCurrentValue = (Int(currentValue) + value).hashValue
                    }
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

    // MARK: Codable conformance

    private enum CodingKeys: String, CodingKey {
        case value
    }

    /// Encodes the counter instance into the encoder instance you provide.
    /// - Parameter encoder: The encoder instance to write into.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }

    /// Decodes a counter instance from the decoder instance you provide.
    /// - Parameter decoder: The decoder to read.
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _unboundStorage = try container.decode(Int.self, forKey: .value)
        _hashOfCurrentValue = _unboundStorage.hashValue
    }
}

extension Counter: Equatable {
    /// Returns a Boolean value that indicates whether value of two counters are equal.
    /// - Parameters:
    ///   - lhs: The first counter to compare.
    ///   - rhs: The second counter to compare.
    /// - Returns: Returns `true` if equal.
    public static func == (lhs: Counter, rhs: Counter) -> Bool {
        if lhs.objId != nil, rhs.objId != nil {
            return lhs.objId == rhs.objId
        } else {
            return lhs.value == rhs.value
        }
    }
}

extension Counter: Hashable {
    public func hash(into hasher: inout Hasher) {
        sync {
            hasher.combine(objId)
            hasher.combine(value)
        }
    }
}

extension Counter: CustomStringConvertible {
    /// A string representation of the value of the counter.
    public var description: String {
        String(value)
    }
}

#if canImport(Combine)
import Combine

extension Counter: ObservableObject {
    fileprivate func sendObjectWillChange() {
        objectWillChange.send()
    }
}
#else
fileprivate extension Counter {
    func sendObjectWillChange() {}
}
#endif

#if canImport(SwiftUI)
import struct SwiftUI.Binding

public extension Counter {
    /// Returns a binding to the string value of a text object within an Automerge document.
    func valueBinding() -> Binding<Int> {
        Binding(
            get: { () -> Int in
                self.getCounterValue()
            },
            set: { (newValue: Int) in
                self.setCounterValue(newValue)
            }
        )
    }
}
#endif
