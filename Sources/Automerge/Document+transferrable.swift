import Foundation
import os // for structured logging
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers

@available(macOS 11.0, iOS 14.0, *)
extension UTType {
    /// An Automerge document.
    static var automerge: UTType {
        UTType(exportedAs: "com.github.automerge")
    }
}

#if canImport(CoreTransferable)
import CoreTransferable

@available(macOS 13.0, iOS 16.0, *)
extension Document: Transferable {
    
    /// A transfer representation of an Automerge document.
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .automerge) { document in
            document.save()
        } importing: { data in
            do {
                return try Document(data)
            } catch {
                Logger(subsystem: "Automerge", category: "Document")
                    .error("Error decoding transfered Automerge data: \(error, privacy: .public)")
                return Document()
            }
        }
    }
}
#endif

#endif
