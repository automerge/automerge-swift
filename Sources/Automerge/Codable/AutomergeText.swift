import Combine
import Foundation
import struct SwiftUI.Binding

// NOTE(heckj): The version Automerge after 2.0 is adding support for "marks"
// that apply to runs of text within the .Text primitive. This should map
// reasonably well to AttributedStrings. When it's merged, this type
// should be a reasonable placeholder from which to derive `AttributedString` and
// the flat `String` variations from the underlying data source in Automerge.

/// A reference to a Text object within an Automerge document.
public final class AutomergeText: ObservableObject, Codable {
    var doc: Document?
    var objId: ObjId?
    var _unboundStorage: String

    // MARK: Initializers and Bind

    /// Creates a new, unbound text reference instance.
    /// - Parameter initialValue: An initial string value for the text reference.
    public init(_ initialValue: String = "") {
        _unboundStorage = initialValue
    }

    /// Creates a new text reference instance bound within an Automerge document.
    /// - Parameters:
    ///   - doc: The Automerge document associated with this reference.
    ///   - path: A string path that represents a `Text` container within the Automerge document.
    ///   - initialValue: An initial string value for the text reference.
    public convenience init(_ initialValue: String = "", doc: Document, path: String) throws {
        self.init(initialValue)
        try bind(doc: doc, path: path)
    }

    public convenience init(doc: Document, objId: ObjId) throws {
        self.init()
        if doc.objectType(obj: objId) == .Text {
            self.doc = doc
            self.objId = objId
        } else {
            throw BindingError.NotText
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
        guard let objId = try doc.lookupPath(path: path) else {
            throw BindingError.InvalidPath(path)
        }
        if doc.objectType(obj: objId) == .Text {
            self.doc = doc
            self.objId = objId
        } else {
            throw BindingError.NotText
        }
        if !_unboundStorage.isEmpty {
            try updateText(newText: _unboundStorage)
            _unboundStorage = ""
        }
    }

    // MARK: Exposing String value and Binding<String>

    /// The string value of the text reference in an Automerge document.
    public var value: String {
        get {
            guard let doc, let objId else {
                return _unboundStorage
            }
            do {
                return try doc.text(obj: objId)
            } catch {
                fatalError("Error attempting to read text value from objectId \(objId): \(error)")
            }
        }
        set {
            guard let objId, doc != nil else {
                _unboundStorage = newValue
                return
            }
            do {
                try updateText(newText: newValue)
            } catch {
                fatalError("Error attempting to write '\(newValue)' to objectId \(objId): \(error)")
            }
        }
    }

    /// Returns a binding to the string value of a text object within an Automerge document.
    public func textBinding() -> Binding<String> {
        Binding(
            get: { () -> String in
                guard let doc = self.doc, let objId = self.objId else {
                    return self._unboundStorage
                }
                do {
                    return try doc.text(obj: objId)
                } catch {
                    fatalError("Error attempting to read text value from objectId \(objId): \(error)")
                }
            },
            set: { (newValue: String) in
                guard let objId = self.objId, self.doc != nil else {
                    self._unboundStorage = newValue
                    return
                }
                do {
                    try self.updateText(newText: newValue)
                } catch {
                    fatalError("Error attempting to write '\(newValue)' to objectId \(objId): \(error)")
                }
            }
        )
    }

    private func updateText(newText: String) throws {
        guard let objId, let doc else {
            throw BindingError.Unbound
        }
        let current = try! doc.text(obj: objId).utf8
        let diff: CollectionDifference<String.UTF8View.Element> = newText.utf8.difference(from: current)
        var updated = false
        for change in diff {
            updated = true
            switch change {
            case let .insert(offset, element, _):
                let index = offset
                let char = String(bytes: [element], encoding: .utf8)
                try! doc.spliceText(obj: objId, start: UInt64(index), delete: 0, value: char)
            case let .remove(offset, _, _):
                let index = offset
                try! doc.spliceText(obj: objId, start: UInt64(index), delete: 1)
            }
        }
        if updated {
            objectWillChange.send()
        }
    }

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
        _unboundStorage = try container.decode(String.self, forKey: .value)
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
        hasher.combine(objId)
        hasher.combine(_unboundStorage)
    }
}

extension AutomergeText: CustomStringConvertible {
    public var description: String {
        value
    }
}

/// Binding errors
public enum BindingError: LocalizedError, Equatable {
    public static func == (lhs: BindingError, rhs: BindingError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }

    /// The path provided was invalid to bind into the Automerge document.
    case InvalidPath(String)
    /// The Automerge object at the path provided was not a Text object.
    case NotText
    /// The instance is not bound to an Automerge Document.
    case Unbound

    /// A localized message describing the error.
    public var errorDescription: String? {
        switch self {
        case let .InvalidPath(path):
            return "Attempted to bind to an invalid path within the Automerge document: \(path)"
        case .NotText:
            return "Path location was not an Automerge Text object."
        case .Unbound:
            return "The object does not yet reference an Automerge Text object."
        }
    }
}
