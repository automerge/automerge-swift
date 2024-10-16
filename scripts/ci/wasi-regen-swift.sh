#!/usr/bin/env bash

# This script is strictly for CI usage to support pull requests that update
# the Rust core library. The headers need to be regenerated for the WASI build
# explicitly, which is part of the release process for general purposes, but
# may need an explicit one-off to correctly test a local build in CI.

# bash "strict" mode
# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euxo pipefail

THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
RUST_FOLDER="$THIS_SCRIPT_DIR/../../rust"

FRAMEWORK_NAME="automergeFFI"

SWIFT_FOLDER="$THIS_SCRIPT_DIR/../../AutomergeUniffi"
cargo_build="cargo build --manifest-path ${RUST_FOLDER}/Cargo.toml"

mkdir -p "${SWIFT_FOLDER}"

echo "▸ Generate Swift Scaffolding Code"
cargo run --manifest-path "$RUST_FOLDER/Cargo.toml"  \
    --features=uniffi/cli \
    --bin uniffi-bindgen generate \
    "$RUST_FOLDER/src/automerge.udl" \
    --language swift \
    --out-dir "${SWIFT_FOLDER}"

echo "▸ Building for wasm32-wasip1-threads"
$cargo_build --target wasm32-wasip1-threads --locked --release

# copies the generated header from AutomergeUniffi/automergeFFI.h to
# Sources/_CAutomergeUniffi/include/automergeFFI.h within the project
cp "${SWIFT_FOLDER}/automergeFFI.h" "${SWIFT_FOLDER}/../Sources/_CAutomergeUniffi/include"
cp "${SWIFT_FOLDER}/automergeFFI.modulemap" "${SWIFT_FOLDER}/../Sources/_CAutomergeUniffi/include/module.modulemap"
