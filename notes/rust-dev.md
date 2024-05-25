# Rust development notes

Exposing something new from the Rust [core library](https://docs.rs/automerge/) is done through the lens of what `UniFFI` provides.

This project uses the [UDL file](https://mozilla.github.io/uniffi-rs/udl_file_spec.html) extensively. The UDL file maps [a limited set of Rust types](https://mozilla.github.io/uniffi-rs/udl/builtin_types.html) into the local rust crate, housed in [lib.rs](https://github.com/automerge/automerge-swift/blob/main/rust/src/lib.rs).
The project uses UniFFI to read in that definition, and from the `UDL` file, generate the Swift language bindings.

Because of this, exposing a new function, or type (or both) from the core library is usually a matter of determining of creating types to do the mapping from the swift interface into the Rust core library.

The `UDL` is constrained to only mapping types in the local crate.
Because of this constraint, new types in the core library that are going to be exposed to Swift need a replica so that Swift files can be mapped to them.
(At least I've failed to determine how to expose simple types from other crates, such as the core library.)

I usually pattern this as:

- Determine the signature of any new functions you want to expose.

If the function is exposing either very simple types, or types that already exist in the interface, this may mean that no new types need to be defined.

- Determine if those functions require new type definitions.
I often try to sketch out the details of the types in Rust, reviewing the [API documentation for the crate](https://docs.rs/automerge/), and another other useful notes I can find.
Looking at [WASM testing code](https://github.com/automerge/automerge/tree/main/rust/automerge-wasm/test) and [the JavaScript .next API docs](https://automerge.org/automerge/api-docs/js/modules/next.html) are often useful references, as those are the first developed for new features.

- Add new types that can be used across the Swift/Rust language border (that is, which fit into the constraints of the UDL) in Rust, and then expose them by adding references in `lib.rs`.

- Update the `UDL file` to reference the new, local types.

- Add new or updated functions in Rust. I primarily stub them out and don't flesh out everything at first, as I've found (so far) that the UDL constraints can imply significant changes to any implementation.

- Update the `UDL file` to expose the new functions.

- For mapping local types into the Automerge crate types, implement `From` and/or `Into` traits as needed.
For more information on these traits, the [From and Into chapter of Rust by Example](https://doc.rust-lang.org/rust-by-example/conversion/from_into.html) is an extremely useful reference.
The most common (so far) has been implementing the `From` trait to accept a variety of types as input parameters for functions.
In a few cases, `Into` has been needed in order to expose more complex types returned from Automerge.

- With `From` (and/or `Into`) traits implemented, implement the functionality in the methods to accept the local types.
Convert incoming parameters into the relevant structure needed for Automerge's Rust API, and handle the reverse transformation for any return values.

## General notes for the implementation

Follow the pattern of existing functions to help with handling [Error conditions](https://mozilla.github.io/uniffi-rs/udl/errors.html) (throwing errors through to the Swift language layer).

Most interface types are kept as simple as possible (Structs or Enums), but in some cases you may need to use reference-types.
Read through [Interfaces/Objects](https://mozilla.github.io/uniffi-rs/udl/interfaces.html) in the UniFFI user guide for an overview.
I've found both the [UDL definition for SyncState](https://github.com/automerge/automerge-swift/blob/main/rust/src/automerge.udl#L59-L74) and [its Rust implementation](https://github.com/automerge/automerge-swift/blob/main/rust/src/sync_state.rs) to be a useful, simple reference.

Callback interfaces _can_ be defined in the UDL, but closure parameters aren't supported. To date, the Automerge-swift doesn't use any callback interfaces.

### Development

I've been using [VSCode](https://code.visualstudio.com) with the extensions [Rust](https://marketplace.visualstudio.com/items?itemName=1YiB.rust-bundle)) and [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer) for the Rust development work.
Between the two plugins, it generally shows the key issues and errors while developing, with good feedback.
Most importantly (for me) it annotates types into the Editor, and since most of this work is managing type conversions to use the Automerge crate in Rust, I found that hugely beneficial.

For a quick check when the IDE isn't helping, I run the following command from a terminal:

```bash
cd rust
cargo build
```

This invokes _both_ the UniFFI UDL parsing and code generation, as well as Rust compilation, so you can generally see where something is going wrong.
I found it's very easy to use incorrect syntax in the UDL file, so I advice to make small, incremental steps there, independent of adding or updating Rust implementations of definitions.

### Testing

The local Rust library for this interface doesn't have any embedded tests. There functionally should be no business logic in these layers, only type conversion, so testing at this layer has minimal value.
If you find yourself wanting to add more complex logic that warrants testing, it is probably an indicator that the Automerge API in Rust should be updated instead.

As such, testing is all done in Swift.
Test functions should be written and included in the `Automerge` module in the Swift project.
The testing development cycle is notably longer, requiring a rebuild of the Rust library, compiling that into an XCFramework, and then invoking `swift test`.

Compiling the XCFramework is the most time intensive task, as it compiles multiple versions to combine everything into a multi-platform binary.
The pattern I typically use for this (from the root of the repository):

```bash
export LOCAL_BUILD=1
# tells Package.swift to use a locally built XCFramework instead of the latest released version
./scripts/build-xcframework.sh
./scripts/compress-framework.sh

# this is basically running `swift test`
./scripts/ci/test.sh
```

### Preparing a pull request

To prep a code change for a pull request, make sure to run `rustfmt` and verify with [clippy](https://doc.rust-lang.org/clippy/) (a static software analysis tool provided by the Rust language toolchain):

```bash
# this reformats the Rust code per language provided baselines
cargo fmt --manifest-path rust/Cargo.toml
# this verifies the formatting and linting for the Rust code
./scripts/ci/run.sh
```
