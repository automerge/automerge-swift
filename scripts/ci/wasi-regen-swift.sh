#!/usr/bin/env bash

# This script is strictly for CI usage to support pull requests that update
# the Rust core library. The headers need to be regenerated for the WASI build
# explicitly, which is part of the release process for general purposes, but
# may need an explicit one-off to correctly test a local build in CI.

# bash "strict" mode
# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euxo pipefail

THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ROOT_FOLDER="$THIS_SCRIPT_DIR/../.."
RUST_FOLDER="$ROOT_FOLDER/rust"
SWIFT_FOLDER="$ROOT_FOLDER/AutomergeUniffi"

FRAMEWORK_NAME="automergeFFI"

cargo_build="cargo build --manifest-path ${RUST_FOLDER}/Cargo.toml"

mkdir -p "${SWIFT_FOLDER}"

echo "▸ Generate Swift Scaffolding Code"
cargo run --manifest-path "$RUST_FOLDER/Cargo.toml"  \
    --features=uniffi/cli \
    --bin uniffi-bindgen generate \
    "$RUST_FOLDER/src/automerge.udl" \
    --language swift \
    --out-dir "${SWIFT_FOLDER}"

echo "▸ Building for WASM"
$cargo_build --target wasm32-wasip1 --locked --release
$cargo_build --target wasm32-wasip1-threads --locked --release
cp "${RUST_FOLDER}/target/wasm32-wasip1/release/libuniffi_automerge.a" "${ROOT_FOLDER}/libuniffi_automerge.a"
cp "${RUST_FOLDER}/target/wasm32-wasip1-threads/release/libuniffi_automerge.a" "${ROOT_FOLDER}/libuniffi_automerge_threads.a"

# copies the generated header from AutomergeUniffi/automergeFFI.h to
# Sources/_CAutomergeUniffi/include/automergeFFI.h within the project
cp "${SWIFT_FOLDER}/automergeFFI.h" "${SWIFT_FOLDER}/../Sources/_CAutomergeUniffi/include"
cp "${SWIFT_FOLDER}/automergeFFI.modulemap" "${SWIFT_FOLDER}/../Sources/_CAutomergeUniffi/include/module.modulemap"
