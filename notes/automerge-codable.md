# Implementation Notes: Custom encoder and decoder for Automerge Documents

To support higher level interaction with iOS and macOS applications, Automerge-Swift includes an encoder and decoder that serializes any developer type that conforms to Codable into an Automerge document.
These notes are intended for anyone wanting to understand how that process works, and how the encoder and decoder are constructed.

## Automerge Document Structure

If you squint, and Automerge document has a lot of the same basic layout as a JSON document:
- It is primarily structured with maps and lists, with the root being a map.
- The maps all used String-based keys to reference other types.
- The values stored within maps or lists are similar to JSON primitives - but have more specifics.
  - Where JSON has `number`, Automerge primitive values include the more specific classificiations of Int, Floating Point, and UInt.
  - Automerge also have primitves for timestamps (dates) and raw data (byte buffers).
- There's an additional special object type, `Text`, that supports collaborative syncing of a string from multiple editors.
- There's also a special value for a Counter CRDT type.

Like JSON, an Automerge document is dynamic, in that there's no type constraints of what is stored within a list, or the values of a map.
With any change applied, those values can change types.

## Codable

Swift deals with the static-type to dynamic type with JSON files by supporting encoding and decoding through the [Codable](https://developer.apple.com/documentation/swift/codable) protocol.
The initial implementation reviewed an existing [JSONEncoder](https://github.com/swift-extras/swift-extras-json), and used its basic structure to work to an encoder that stores into an Automerge document.
In addition to existing source code, the book [Flight School Guide to Swift Codable](https://flight.school/books/codable/) was extremely helpful to understand how the internals of codable implementations operate.

## Coding Keys

The location that within an Automerge document can be represented as a path - routing through maps and/or lists until it reaches leaf values.
A sort of "path" is exposed by the raw Automerge API as PathElement, and when returned from Automerge's API, it includes an ObjectId that provides a unique identifier to the continer's location.
This maps extremely closely to Codable's concept of a CodingKey, which is a key part of the Codable protocols that keep track of "where you are" when encoding or decoding.
CodingKeys are typically closely related the types you are serializing. 
To fully externalize this into an easier to use form for just tracking "location" within an Automerge Document, this library includes `AnyCodingKey`, and supporting creating them from an Automerge `PathElement`, or parsing a String into an array of AnyCodingKey.

The mechanism to parse a string into an array of AnyCodingKey uses a [jq](https://jqlang.github.io/jq/) like filter construct:
- strings reference map (or object) containers
- integers within `[` and `]` reference an index into an array 

## Automerge Encoder

The Automerge Encoder follows the pattern of several other encoders - providing a high level interface using a struct (`AutomergeEncoder`), but doing the heavy lifting of the encoding itself with a stateful reference type (`AutomergeEncoderImpl`).
The AutomergeEncoder maintains a reference to the Automerge Document that it writes into, and configuration (`SchemaStrategy`) that details how to handle creating schema when needed.
While typical JSON encoders provide an `encode(:_)` method, the AutomergeEncoder also supports an `encode(:_,at:)` method that allows you to encode to a specific location within the Automerge schema.
This allows you to write to specific internal locations in an Automerge Document, and not always have to serialize everything from the top of the Document.

The `AutomergeEncoderImpl` class implements the required methods for the Encoder protocol, which in turn support encoding into a "keyed container" (such as a map), an "unkeyed container" (such as a list), or into a single value. 
The corresponding classes of AutomergeKeyedEncodingContainer, AutomergeUnkeyedEncodingContainer, and AutomergeSingleValueEncodingContainer then hold the relevant logic to create schema as needed within the Automerge document or write values. 

To use the underlying Automerge API to write into the document, you need an ObjectId.
The method `lookupPath`, on the `Document` class, takes an array of `AnyCodingKey` - or attempts to parses a string into that array, and walks the Automerge document to look up the relevant ObjectId.
If the location doesn't exist, the method returns a `nil`.
It can also throw an error - for example if you try to walk through a leaf-node (a value or Text object) as though it were a container.

The code for encoding within a container - keyed or unkeyed - uses a closely related method `retrieveObjectId`.
It doesn't throw an error - but instead returns either the ObjectId or a failure error within a Result type.
The key reason is that the initializers for the encoding containers don't support throwing errors, but that's possible within the realm of encoding into a dynamic document.
Instead, the initialized for the keyed and unkeyed containers establish a proxy container and store any critical lookup failures, which are them checked when `encode(:_)` is called on those containers (which _does_ throw).

There's a performance opportunity in the `retrieveObjectId` (and `lookupPath`) method, which might be useful down the road - especially when encoding a deep and dense document: caching.
Currently those methods do no caching - but may benefit from higher level looks already in memory as opposed to walking the Automerge document tree through the low-level API.
If such a cache is enabled, it should absolutely be cleared/reset on any sync of external changes, since the schema could notably change due to the dynamic nature of an Automerge document.
In practice, the speed of encoding documents is quite performant based on initial use cases and feedback so far.

The default strategy when dealing with this dynamic schema is `createWhenNeeded` - which creates schema when the encoder is trying to do it's work IF there's no existing schema that would conflict already in place. 

### Codable's inversion of Control

One thing to note: when you call encode on a type, the Codable protocol is set up to "hand control" over to code provided by the type (or synthesized by the compiler) that has the details of _how_ to encode that type.
In a few cases, this was surprising, and especially to support some of the specific Automerge primitives, the encoder adds special casing to use it's own logic - instead of the type's logic - for storing values into Automerge.
This can be seen within the generic encode methods on the encoder, which switches over the type provided looking for the Automerge types of Text or Counter, or the foundational types of Date or Data.
Each of keyed container, unkeyed container, and single-value container need to contain consistent logic for these scenarios.

### Type Checking an Automerge content

There's a boolean flag on the encoder implementation that supports doing a bit of additional "type checking" just to make sure that the type didn't change under the covers.
The type `TypeOfAutomergeValue` encapsulates that cascading Object->ScalarValue enumeration pattern that Automerge provides into a single, simple enumeration that represents just the type of the Automerge primitive.
This allows an additional mode of throwing an error if the type being written doesn't match the type that exists in the underlying Automerge document. 

## Automerge Decoder

The decoder is in many ways simpler, walking the Automerge document tree and reading the data provided.
The same special-case-logic for specific types (Date, Data, Counter, and Text) is included within the decoder, again to _not_ hand control over to the synthesized code.

