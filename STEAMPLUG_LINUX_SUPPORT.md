# STEAMplug Linux compatibility support

## Scope and provenance

This repository is a narrow compatibility fork maintained by
[STEAMplug](https://github.com/STEAMplug-org) for server-side Swift deployments such as
the Linux Swift/Hummingbird `ilx-api` service. It exposes the existing Automerge Swift
API on Linux; it does not add repository, networking, or storage behavior from
`automerge-repo-swift`.

The compatibility line is based directly on:

- upstream repository: <https://github.com/automerge/automerge-swift>
- upstream release: `0.7.2`
- upstream Git commit: `aa45d17ac92cef2b8ded63b47e65a28dc85e3418`
- locked Rust core crate: `automerge` `0.7.2` from `rust/Cargo.lock`

STEAMplug owns this Linux compatibility layer until upstream supports ordinary Linux
SwiftPM consumption. The compatibility changes remove the intentional Linux compile
error, build the native Rust/UniFFI archive from the same checkout, exercise the
upstream Swift test suite on Linux, and document that process. They do not intentionally
change Automerge behavior.

The Apple package path remains upstream's released
`automergeFFI.xcframework` binary target. Do not remove or replace that path when
maintaining Linux support.

## Supported build environment

The supported and continuously tested environment is:

- Ubuntu 24.04 (Noble), `x86_64`
- Swift `6.3.x` (CI pins the official `swift:6.3.3-noble` image by digest)
- Rust and Cargo `1.89.0`
- Bash plus the normal Swift and Rust native-linker prerequisites

Linux `aarch64` is accepted by the build helper because both toolchains support it, but
it is not continuously tested by this fork. Other operating systems and Linux
architectures fail before the Rust build starts. Rust `1.89.0` follows the upstream
fix for the Edition 2024 transitive dependency used by this release line.

## Build and test locally

Install Swift `6.3.x` for Ubuntu Noble and Rust `1.89.0`, then run from the repository
root:

```bash
rustup toolchain install 1.89.0 --profile minimal
rustup run 1.89.0 ./scripts/test-linux.sh
```

The test helper runs the equivalent explicit sequence:

```bash
AUTOMERGE_FFI_ARCHIVE="$(rustup run 1.89.0 ./scripts/build-linux.sh)"
swift build --build-tests -Xlinker "${AUTOMERGE_FFI_ARCHIVE}"
```

`scripts/build-linux.sh`:

1. rejects unsupported hosts and unexpected Swift/Rust versions;
2. regenerates the Swift UniFFI files into a temporary directory and compares them
   with the checked-in bindings;
3. runs Cargo with `--locked` against `rust/Cargo.toml`;
4. prints only the absolute path to
   `rust/target/release/libuniffi_automerge.a` on standard output.

Build logs and errors go to standard error, so command substitution receives only the
linkable archive path.

CI uses the same `./scripts/test-linux.sh` command in
`.github/workflows/linux.yml`. The workflow runs in the digest-pinned official Swift
6.3.3 Noble container, installs the exact Rust toolchain through a commit-pinned
action, installs only the `curl`/CA transport that rustup needs, grants only
`contents: read`, builds the locked archive, and runs the discovered Swift tests
described below with that archive passed to the linker. The helper selects the
container's `clang` explicitly when a conventional `cc` linker shim is absent.

Swift 6.3/Linux can stall the upstream 0.7.2 XCTest process before it reports later
cases when all tests share one process. `scripts/test-linux.sh` therefore discovers
the compiled XCTest bundle and runs each case in an isolated process with a 30-second
timeout. One upstream negative-path test,
`AutomergeSingleValueEncoderImplTests.testErrorEncode_Int16`, also stalls when run
alone and is an explicit, reviewable exclusion. The successful Int16 encode path and
the adjacent throwing integer-width paths still run. The script fails if the exclusion
disappears from discovery, if any other test fails or times out, or if discovery is
empty.

## Why the archive and bindings must match

`AutomergeUniffi/automerge.swift`, the C header and module map under
`Sources/_CAutomergeUniffi`, the UDL in `rust/src/automerge.udl`, and the Rust static
archive are one generated ABI contract. Reusing an archive from another Automerge
Swift revision can produce missing symbols, UniFFI contract-check failures, or subtler
ABI incompatibilities even when the Swift package compiles.

Always build `libuniffi_automerge.a` from the same pinned checkout and locked Cargo
graph used to compile the Swift sources. Never copy an archive from another tag,
branch, or working tree into a downstream service.

## Linux behavioral coverage

The focused `LinuxSmokeHistoryTests.testCreatePersistForkMergeHistoryAndSync` case
proves the complete supported server path in one native-library execution:

- create and mutate;
- save and load;
- fork and historical heads;
- offline merge; and
- bidirectional sync message generation and receipt.

The isolated runner also executes every discovered upstream `AutomergeTests` case
except the one documented Swift 6.3/Linux hang above. Platform-specific Apple tests
remain conditionally compiled as upstream designed.

## Licensing

The upstream project and this compatibility fork are distributed under the MIT
License in `LICENSE`; preserve its copyright and permission notice in copies or
substantial portions. The Rust archive statically contains third-party crates with
their own license terms. Before distributing the archive, review the exact dependency
graph selected by `rust/Cargo.lock` and carry all notices required by those crates.
Do not treat the repository's MIT license as replacing dependency licenses.

## Syncing from upstream

Keep `upstream` set to <https://github.com/automerge/automerge-swift.git>. For each
supported upstream release:

1. fetch upstream branches and tags without rewriting them;
2. verify the release tag and resolve its exact commit;
3. create a new `codex/` or maintenance branch directly from that commit;
4. reapply only the Linux blocker removal, helper, CI, and fork documentation;
5. regenerate and compare UniFFI bindings, then run Apple and Linux validation;
6. review the complete fork diff for unintended package or Automerge behavior changes;
7. pin downstream consumers to the reviewed fork commit, never to a moving branch.

Do not move upstream tags, merge an arbitrary moving `main` into a compatibility
release, or reuse an older native archive after updating Rust, the UDL, generated
bindings, or `Cargo.lock`.

## Retirement criteria

Retire this compatibility layer when an upstream release:

- supports ordinary Linux SwiftPM consumption without manual removal of a compile
  blocker;
- provides or reproducibly builds the matching native Rust/UniFFI library;
- tests the supported Swift/Linux combination for create, persistence, history,
  offline merge, and sync behavior; and
- has been validated in the separate `ilx-api` production-linkage workflow.

After migration, archive the STEAMplug compatibility branch for provenance and move
downstream pins to the verified upstream release. Retirement does not require deleting
historical branches or rewriting tags.
