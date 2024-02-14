# Automerge integration with CloudKit

## alexg — Feb 14, 2024 at 1:25 PM

I have had some thoughts about how CloudKit could be used for application sync.
I think if we use effectively the same scheme as we use for managing concurrent changes to storage in automerge-repo it should be possible.
The requirements of the storage layer are that it provide a key/value interface with byte arrays as values and a range query.
I believe both of these requirements are satisfied by CloudKit.

The way this works is that every time a change is made to a document you write the new change to a key of the form `<document ID>/incremental/<change hash>`.
You can then load the document by querying all the keys that begin with `<document ID>/incremental/`, concatenating the bytes of all those changes, and loading them into an automerge document.
However, this would not take advantage of the compaction which save() provides.
To compact then, we first save the document and write the output to `<document ID>/snapshot/<hash of the heads of the document>`, then we delete all the keys which were used when loading the document.

This is safe in the face of concurrent compacting operations because:
 a) we only delete changes we have already written out, so no data is lost, and
 b) if two processes are racing to snapshot then they are either compacting the same data, in which case they will write the same bytes to the same key, or they are compacting different data in which case the key they write to will be different.
 Loading now becomes querying for all keys beginning with `<document ID>/`, concatnating them, and loading the result.
