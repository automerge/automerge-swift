import Foundation
#if canImport(os)
import os // for structured logging
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers

@available(macOS 11.0, iOS 14.0, *)
public extension UTType {
    /// An Automerge document.
    ///
    /// The string identifier is `com.github.automerge` and conforms to the type `UTType.data`.
    ///
    /// If your app shares data with this type, include the type definition in your app's `Info.plist` file as an
    /// imported type, as described in <doc:AutomergeType>.
    static var automerge: UTType {
        UTType(importedAs: "com.github.automerge", conformingTo: UTType.data)
    }
}

#if canImport(CoreTransferable)
import CoreTransferable

@available(macOS 13.0, iOS 16.0, *)
extension Document: Transferable {
    /// A transfer representation of an Automerge document.
    ///
    /// Use the document's transfer representation for system interactions that move or share data, such as the Share
    /// button, drag and drop, or copy and paste.
    /// The type associated with this representation is ``Automerge/UniformTypeIdentifiers/UTType/automerge``.
    ///
    /// If your app shares data with this type, include the type definition in your app's Info.plist for an imported or
    /// exported type, as described in <doc:AutomergeType>.
    ///
    /// For more information on transfer representations, see [Core
    /// Transferable](https://developer.apple.com/documentation/coretransferable).
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .automerge) { document in
            document.save()
        } importing: { data in
            do {
                return try Document(data)
            } catch {
                #if canImport(os)
                Logger(subsystem: "Automerge", category: "Document")
                    .error("Error decoding transfered Automerge data: \(error, privacy: .public)")
                #endif
                return Document()
            }
        }
    }
}
#endif

#endif
