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
public final class AutomergeText: Codable {
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

    /// Returns a Boolean value that indicates the AutomergeText instance is actively bound to an Automerge document.
    ///
    /// Before an instance is bound, changes made to the content of AutomergeText are local only to this class, and
    /// and updates won't be reflected in an Automerge document.
    ///
    /// Use ``bind(doc:path:)`` to associate this instance with a specific schema location within an Automerge document,
    /// or encode it as part of a larger document model into an Automerge document to store the value.
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

    private func updateText(newText: String) throws {
        guard let objId, let doc else {
            throw BindingError.Unbound
        }
        let current = try doc.text(obj: objId)
        if current != newText {
            try doc.updateText(obj: objId, value: newText)
            sendObjectWillChange()
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

#if canImport(Combine)

import Combine

extension AutomergeText: ObservableObject {
    fileprivate func sendObjectWillChange() {
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
}
#endif
