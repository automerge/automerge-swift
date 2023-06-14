/// A type that represents the encoder strategy to establish or error on differences in existing Automerge documents
/// as compared to expected encoding.
public enum SchemaStrategy {
    /// Creates schema where none exists, errors on schema mismatch.
    ///
    /// Basic schema checking for containers that creates relevant objects in Automerge at the relevant path doesn't
    /// exist.
    /// If there is something in an existing Automerge document that doesn't match the type of container, or if the
    /// path
    /// is a leaf-node
    /// (a scalar value, or a Text instance), then the lookup captures the schema error for later presentation.
    case createWhenNeeded

    /// Creates schema, irregardless of existing schema.
    ///
    /// Disregards any existing schema that currently exists in the Automerge document and overwrites the path
    /// elements
    /// as
    /// the encoding progresses. This option will potentially change the schema within an Automerge document.
    case override

    /// Allows updating of values only.
    /// If the schema does not pre-exist in the format that the encoder expects, the lookup doesn't create schema
    /// and
    /// captures an error for later presentation.
    case readonly
}
