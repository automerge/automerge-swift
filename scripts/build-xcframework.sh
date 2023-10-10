#!/usr/bin/env bash

# This script was cribbed from https://github.com/y-crdt/y-uniffi/blob/7cd55266c11c424afa3ae5b3edae6e9f70d9a6bb/lib/build-xcframework.sh
# which was written by Joseph Heck and  Aidar Nugmanoff and licensed under the
# MIT license. We have made some slight naming changes

# currently macabi/Catalyst target has no prebuild rust-std library hence we use `-Z build-std`
# how to build-std: https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#build-std
# list of targets with prebuild rust-std https://doc.rust-lang.org/nightly/rustc/platform-support.html

# WARNING this build script to work requires pinned rust version due a known issue with Catalyst build
# that was later introduced https://github.com/rust-lang/rust/issues/106021

set -e # immediately terminate script on any failure conditions
set -x # echo script commands for easier debugging

THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PACKAGE_NAME="AutomergeUniffi"
LIB_NAME="libuniffi_automerge.a"
RUST_FOLDER="$THIS_SCRIPT_DIR/../rust"

FRAMEWORK_NAME="automergeFFI"

SWIFT_FOLDER="$THIS_SCRIPT_DIR/../AutomergeUniffi"
BUILD_FOLDER="$RUST_FOLDER/target"

XCFRAMEWORK_FOLDER="$THIS_SCRIPT_DIR/../${FRAMEWORK_NAME}.xcframework"

# The specific issue with an earlier nightly version and linking into an
# XCFramework appears to be resolved with latest versions of +nightly toolchain
# (as of 10/10/23), but leaving it open to float seems less useful than
# moving the pinning forward, since Catalyst support (target macabi) still
# requires an active, nightly toolchain.
RUST_NIGHTLY="nightly-2023-10-09"

echo "Install nightly and rust-src for Catalyst"
rustup toolchain install ${RUST_NIGHTLY}
rustup component add rust-src --toolchain ${RUST_NIGHTLY}
rustup update
rustup default ${RUST_NIGHTLY}

echo "▸ Install toolchains"
rustup target add x86_64-apple-ios # iOS Simulator (Intel)
rustup target add aarch64-apple-ios-sim # iOS Simulator (M1)
rustup target add aarch64-apple-ios # iOS Device
rustup target add aarch64-apple-darwin # macOS ARM/M1
rustup target add x86_64-apple-darwin # macOS Intel/x86
cargo_build="cargo build --manifest-path $RUST_FOLDER/Cargo.toml"
cargo_build_nightly="cargo +${RUST_NIGHTLY} build --manifest-path $RUST_FOLDER/Cargo.toml"


echo "▸ Clean state"
rm -rf "${XCFRAMEWORK_FOLDER}"

mkdir -p "${SWIFT_FOLDER}"
echo "▸ Generate Swift Scaffolding Code"
cargo run --manifest-path "$RUST_FOLDER/Cargo.toml"  \
    --features=uniffi/cli \
    --bin uniffi-bindgen generate \
    "$RUST_FOLDER/src/automerge.udl" \
    --language swift \
    --out-dir "${SWIFT_FOLDER}"

echo "▸ Building for x86_64-apple-ios"
CFLAGS_x86_64_apple_ios="-target x86_64-apple-ios" \
$cargo_build --target x86_64-apple-ios --locked --release

echo "▸ Building for aarch64-apple-ios-sim"
CFLAGS_aarch64_apple_ios="-target aarch64-apple-ios-sim" \
$cargo_build --target aarch64-apple-ios-sim --locked --release

echo "▸ Building for aarch64-apple-ios"
CFLAGS_aarch64_apple_ios="-target aarch64-apple-ios" \
$cargo_build --target aarch64-apple-ios --locked --release

echo "▸ Building for aarch64-apple-darwin"
CFLAGS_aarch64_apple_darwin="-target aarch64-apple-darwin" \
$cargo_build --target aarch64-apple-darwin --locked --release

echo "▸ Building for x86_64-apple-darwin"
CFLAGS_x86_64_apple_darwin="-target x86_64-apple-darwin" \
$cargo_build --target x86_64-apple-darwin --locked --release

echo "▸ Building for aarch64-apple-ios-macabi"
$cargo_build_nightly -Z build-std --target aarch64-apple-ios-macabi --locked --release

echo "▸ Building for x86_64-apple-ios-macabi"
$cargo_build_nightly -Z build-std --target x86_64-apple-ios-macabi --locked --release

echo "▸ Consolidating the headers and modulemaps for XCFramework generation"
mkdir -p "${BUILD_FOLDER}/includes"
cp "${SWIFT_FOLDER}/automergeFFI.h" "${BUILD_FOLDER}/includes"
cp "${SWIFT_FOLDER}/automergeFFI.modulemap" "${BUILD_FOLDER}/includes/module.modulemap"

echo "▸ Lipo (merge) x86 and arm simulator static libraries into a fat static binary"
mkdir -p "${BUILD_FOLDER}/ios-simulator/release"
lipo -create  \
    "${BUILD_FOLDER}/x86_64-apple-ios/release/${LIB_NAME}" \
    "${BUILD_FOLDER}/aarch64-apple-ios-sim/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/ios-simulator/release/${LIB_NAME}"

echo "▸ Lipo (merge) x86 and arm macOS static libraries into a fat static binary"
mkdir -p "${BUILD_FOLDER}/apple-darwin/release"
lipo -create  \
    "${BUILD_FOLDER}/x86_64-apple-darwin/release/${LIB_NAME}" \
    "${BUILD_FOLDER}/aarch64-apple-darwin/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/apple-darwin/release/${LIB_NAME}"

echo "▸ Lipo (merge) x86 and arm macOS Catalyst static libraries into a fat static binary"
mkdir -p "${BUILD_FOLDER}/apple-macabi/release"
lipo -create  \
    "${BUILD_FOLDER}/x86_64-apple-ios-macabi/release/${LIB_NAME}" \
    "${BUILD_FOLDER}/aarch64-apple-ios-macabi/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/apple-macabi/release/${LIB_NAME}"

xcodebuild -create-xcframework \
    -library "$BUILD_FOLDER/aarch64-apple-ios/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "${BUILD_FOLDER}/ios-simulator/release/${LIB_NAME}" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "$BUILD_FOLDER/apple-darwin/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "$BUILD_FOLDER/apple-macabi/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -output "${XCFRAMEWORK_FOLDER}"

echo "▸ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_FOLDER" "$XCFRAMEWORK_FOLDER.zip"

echo "▸ Compute checksum"
openssl dgst -sha256 "$XCFRAMEWORK_FOLDER.zip"
