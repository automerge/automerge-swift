import Foundation

// NOTE(heckj): The version Automerge after 2.0 is adding support for "marks"
// that apply to runs of text within the .Text primitive. This should map
// reasonably well to AttributedStrings. When it's merged, this type
// should be a reasonable placeholder from which to derive `AttributedString` and
// the flat `String` variations from the underlying data source in Automerge.

/// A reference to a Text object within an Automerge document.
///
/// You can create an instance of this class and provide initial values before it is attached to an Automerge document.
/// Changes that you make this instance will be local only to this class until it is explicitly attached (bound).
/// Use ``bind(doc:path:)`` to associate this instance with a specific schema location within an Automerge document,
/// or ``AutomergeEncoder/encode(_:)-7gbuh`` it as part of a larger document model into an Automerge document to store
/// the value.
///
/// When you use ``AutomergeDecoder/decode(_:)`` into a type that uses `AutomergeText`, the instances returned from the
/// decoder in your model are already bound to Automerge document.
///
/// For example, the initial non-bound state allows you to create next Text fields in SwiftUI,
/// and at a later point encode them the data model for your app.
///
/// In the [MeetingNotes demo app](https://github.com/automerge/MeetingNotes/), this is done when it creates a new
/// agenda item [within the
/// app](https://github.com/automerge/MeetingNotes/blob/main/MeetingNotes/Views/MeetingNotesDocumentView.swift):
///
/// ```swift
/// // Add a new AgendaItem (which uses AutomergeText) with a new value, not yet reflected in the Document.
/// document.model.agendas.append(AgendaItem(title: ""))
///
/// // Store the updated list of agenda items back into the document to save the value into the Document.
/// updateDoc()
/// ```
///
/// > Warning: Although `AutomergeText` conforms to `ObservableObject`, it does not send notifications of content
/// changes until it has been bound to an Automerge document.
public final class AutomergeText: Codable, @unchecked Sendable {
    var doc: Document?
    var objId: ObjId?
    var _hashOfCurrentValue: Int
    #if canImport(Combine)
    var observerHandle: AnyCancellable?
    #endif
    var _unboundStorage: String

    #if !os(WASI)
    fileprivate let queue = DispatchQueue(label: "automergetext-sync-queue", qos: .userInteractive)
    fileprivate func sync<T>(execute work: () throws -> T) rethrows -> T {
        try queue.sync(execute: work)
    }
    #else
    fileprivate func sync<T>(execute work: () throws -> T) rethrows -> T {
        try work()
    }
    #endif

    // MARK: Initializers and Bind

    /// Creates a new, unbound text reference instance.
    /// - Parameter initialValue: An initial string value for the text reference.
    public init(_ initialValue: String = "") {
        _unboundStorage = initialValue
        _hashOfCurrentValue = initialValue.hashValue
    }

    /// Creates a new text reference instance bound within an Automerge document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    ///   - initialValue: An initial string value for the text reference.
    public convenience init(_ initialValue: String = "", doc: Document, path: String) throws {
        self.init(initialValue)
        let codingPath = try AnyCodingKey.parsePath(path)
        if codingPath.isEmpty {
            throw BindingError.InvalidPath("Path can't be empty to bind an instance of AutomergeText")
        }
        if codingPath.count == 1 {
            // first path element in an Automerge doc _must_ be a key/string, can't be an array/int
            if codingPath[0].intValue != nil {
                throw BindingError
                    .InvalidPath("First path element in an Automerge document can't be an index position.")
            }
            let textObjId = try doc.putObject(obj: ObjId.ROOT, key: codingPath[0].stringValue, ty: .Text)
            self.doc = doc
            objId = textObjId
        } else {
            guard let lastPathElement = codingPath.last else {
                throw BindingError.InvalidPath("Unable to request a final path element from path \(path)")
            }
            let result = doc.retrieveObjectId(
                path: codingPath,
                containerType: .Value,
                strategy: .createWhenNeeded
            )
            switch result {
            case let .success(secondToLastPathItemObjId):
                if let indexLocation = lastPathElement.intValue {
                    let textObjId = try doc.putObject(
                        obj: secondToLastPathItemObjId,
                        index: UInt64(indexLocation),
                        ty: .Text
                    )
                    self.doc = doc
                    objId = textObjId
                } else {
                    let textObjId = try doc.putObject(
                        obj: secondToLastPathItemObjId,
                        key: lastPathElement.stringValue,
                        ty: .Text
                    )
                    self.doc = doc
                    objId = textObjId
                }
            case let .failure(failure):
                throw failure
            }
        }
        try updateText(newText: initialValue)
        observeDocForChanges()
    }

    public convenience init(doc: Document, objId: ObjId) throws {
        self.init()
        if doc.objectType(obj: objId) == .Text {
            sync {
                self.doc = doc
                self.objId = objId
            }
        } else {
            throw BindingError.NotText
        }
        observeDocForChanges()
    }

    deinit {
        #if canImport(Combine)
        observerHandle?.cancel()
        #endif
    }

    /// Returns a Boolean value that indicates the AutomergeText instance is actively bound to an Automerge document.
    ///
    /// Before an instance is bound, changes made to the content of AutomergeText are local only to this class, and
    /// and updates won't be reflected in an Automerge document.
    ///
    /// Use ``bind(doc:path:)`` to associate this instance with a specific schema location within an Automerge document,
    /// or encode it as part of a larger document model into an Automerge document to store the value.
    public var isBound: Bool {
        sync { doc != nil && objId != nil }
    }

    /// Binds a text reference instance info an Automerge document with the schema path you provide.
    ///
    /// If the instance has an initial value other than an empty string, binding update the string within the Automerge
    /// document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    public func bind(doc: Document, path: String) throws {
        assert(self.doc == nil && objId == nil)
        let codingPath = try AnyCodingKey.parsePath(path)
        if codingPath.isEmpty {
            throw BindingError.InvalidPath("Path can't be empty to bind an instance of AutomergeText")
        }
        if codingPath.count == 1 {
            // first path element in an Automerge doc _must_ be a key/string, can't be an array/int
            if codingPath[0].intValue != nil {
                throw BindingError
                    .InvalidPath("First path element in an Automerge document can't be an index position.")
            }
            let textObjId = try doc.putObject(obj: ObjId.ROOT, key: codingPath[0].stringValue, ty: .Text)
            sync {
                self.doc = doc
                objId = textObjId
            }
        } else {
            guard let lastPathElement = codingPath.last else {
                throw BindingError.InvalidPath("Unable to request a final path element from path \(path)")
            }
            let result = doc.retrieveObjectId(
                path: codingPath,
                containerType: .Value,
                strategy: .createWhenNeeded
            )
            switch result {
            case let .success(secondToLastPathItemObjId):
                if let indexLocation = lastPathElement.intValue {
                    let textObjId = try doc.putObject(
                        obj: secondToLastPathItemObjId,
                        index: UInt64(indexLocation),
                        ty: .Text
                    )
                    sync {
                        self.doc = doc
                        objId = textObjId
                    }
                } else {
                    let textObjId = try doc.putObject(
                        obj: secondToLastPathItemObjId,
                        key: lastPathElement.stringValue,
                        ty: .Text
                    )
                    sync {
                        self.doc = doc
                        objId = textObjId
                    }
                }
            case let .failure(failure):
                throw failure
            }
        }
        if !_unboundStorage.isEmpty {
            try updateText(newText: _unboundStorage)
            sync {
                _unboundStorage = ""
            }
        }
        observeDocForChanges()
    }

    /// Binds a text reference instance info an Automerge document at the object ID you provide.
    ///
    /// If the instance has an initial value other than an empty string, binding update the string within the Automerge
    /// document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    public func bind(doc: Document, id: ObjId) throws {
        // this assert runs afoul of the encoder, which doesn't make sense right now, but
        // I don't want to second guess it at the moment.
        //
        // assert(self.doc == nil && self.objId == nil)
        if doc.objectType(obj: id) == .Text {
            sync {
                self.doc = doc
                objId = id
            }
        } else {
            throw BindingError.NotText
        }
        if !_unboundStorage.isEmpty {
            try updateText(newText: _unboundStorage)
            sync {
                _unboundStorage = ""
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
                guard let self = self, let objId = self.objId else {
                    return
                }
                // This is firing off in a concurrent task explicitly to leave the synchronous
                // context that can happen when a doc is being updated and Combine is triggering
                // a change notification.
                Task {
                    let valueFromDoc = try doc.text(obj: objId)
                    let hashOfCurrentValue = self.sync { self._hashOfCurrentValue }
                    if valueFromDoc.hashValue != hashOfCurrentValue {
                        self.sendObjectWillChange()
                    }
                }
            })
        }
        #endif
    }

    // MARK: Exposing String value and Binding<String>

    /// The string value of the text reference in an Automerge document.
    public var value: String {
        get {
            sync {
                guard let doc, let objId else {
                    return _unboundStorage
                }
                do {
                    let content = try doc.text(obj: objId)
                    if content.hashValue != self._hashOfCurrentValue {
                        self._hashOfCurrentValue = content.hashValue
                    }
                    return content
                } catch {
                    fatalError("Error attempting to read text value from objectId \(objId): \(error)")
                }
            }
        }
        set {
            guard let objId, doc != nil else {
                sync {
                    _unboundStorage = newValue
                }
                return
            }
            do {
                try updateText(newText: newValue)
            } catch {
                fatalError("Error attempting to write '\(newValue)' to objectId \(objId): \(error)")
            }
        }
    }

    private func updateText(newText: String) throws {
        guard let objId, let doc else {
            throw BindingError.Unbound
        }
        let current = try doc.text(obj: objId)
        if current != newText {
            sync {
                _hashOfCurrentValue = newText.hashValue
            }
            try doc.updateText(obj: objId, value: newText)
        }
    }

    // MARK: Codable conformance

    public enum CodingKeys: String, CodingKey {
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _unboundStorage = try container.decode(String.self, forKey: .value)
        _hashOfCurrentValue = _unboundStorage.hashValue
    }
}

extension AutomergeText: Equatable {
    public static func == (lhs: AutomergeText, rhs: AutomergeText) -> Bool {
        if lhs.objId != nil, rhs.objId != nil {
            return lhs.objId == rhs.objId
        } else {
            return lhs.value == rhs.value
        }
    }
}

extension AutomergeText: Hashable {
    public func hash(into hasher: inout Hasher) {
        sync {
            hasher.combine(objId)
            hasher.combine(_unboundStorage)
        }
    }
}

extension AutomergeText: CustomStringConvertible {
    public var description: String {
        value
    }
}

#if canImport(Combine)

import Combine
#if canImport(os)
import os
#endif

extension AutomergeText: ObservableObject {
    fileprivate func sendObjectWillChange() {
        #if canImport(os)
        if #available(macOS 11, iOS 14, *) {
            let logger = Logger(subsystem: "Automerge", category: "AutomergeText")
            if let objId = self.objId {
                logger.trace("AutomergeText (\(objId.debugDescription)) sending ObjectWillChange")
            } else {
                logger.trace("AutomergeText (unbound) sending ObjectWillChange")
            }
        }
        #endif
        objectWillChange.send()
    }
}
#else
fileprivate extension AutomergeText {
    func sendObjectWillChange() {}
}
#endif

#if canImport(SwiftUI)
import struct SwiftUI.Binding

public extension AutomergeText {
    /// Returns a binding to the string value of a text object within an Automerge document.
    func textBinding() -> Binding<String> {
        Binding(
            get: { () -> String in
                guard let doc = self.doc, let objId = self.objId else {
                    return self.sync { self._unboundStorage }
                }
                do {
                    let content = try doc.text(obj: objId)
                    if content.hashValue != self._hashOfCurrentValue {
                        self._hashOfCurrentValue = content.hashValue
                    }
                    return content
                } catch {
                    fatalError("Error attempting to read text value from objectId \(objId): \(error)")
                }
            },
            set: { (newValue: String) in
                guard let objId = self.objId, self.doc != nil else {
                    self.sync {
                        self._unboundStorage = newValue
                        self._hashOfCurrentValue = newValue.hashValue
                    }
                    return
                }
                do {
                    if newValue.hashValue != self._hashOfCurrentValue {
                        try self.updateText(newText: newValue)
                    }
                } catch {
                    fatalError("Error attempting to write '\(newValue)' to objectId \(objId): \(error)")
                }
            }
        )
    }
}
#endif
