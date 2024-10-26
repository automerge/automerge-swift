#!/usr/bin/env bash

# This script was cribbed from https://github.com/y-crdt/y-uniffi/blob/7cd55266c11c424afa3ae5b3edae6e9f70d9a6bb/lib/build-xcframework.sh
# which was written by Joseph Heck and  Aidar Nugmanoff and licensed under the
# MIT license. We have made some slight naming changes

# currently macabi/Catalyst target has no prebuild rust-std library hence we use `-Z build-std`
# how to build-std: https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#build-std
# list of targets with prebuild rust-std https://doc.rust-lang.org/nightly/rustc/platform-support.html

# WARNING this build script to work requires pinned rust version due a known issue with Catalyst build
# that was later introduced https://github.com/rust-lang/rust/issues/106021

# bash "strict" mode
# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euxo pipefail

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
RUST_NIGHTLY="nightly-2024-05-23"

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
rustup target add wasm32-wasip1 # WebAssembly
rustup target add wasm32-wasip1-threads # WebAssembly with native multi threading capabilities
cargo_build="cargo build --manifest-path $RUST_FOLDER/Cargo.toml"
cargo_build_nightly="cargo +${RUST_NIGHTLY} build --manifest-path $RUST_FOLDER/Cargo.toml"
cargo_build_nightly_with_std="cargo -Zbuild-std build --manifest-path $RUST_FOLDER/Cargo.toml"


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

echo "▸ Building for aarch64-apple-visionos-sim"
CFLAGS_aarch64_apple_visionos="-target aarch64-apple-visionos-sim" \
$cargo_build_nightly_with_std --target aarch64-apple-visionos-sim --locked --release

echo "▸ Building for aarch64-apple-visionos"
CFLAGS_aarch64_apple_visionos="-target aarch64-apple-visionos" \
$cargo_build_nightly_with_std --target aarch64-apple-visionos --locked --release

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

echo "▸ Building for WASM"
$cargo_build --target wasm32-wasip1 --locked --release
$cargo_build --target wasm32-wasip1-threads --locked --release

echo "▸ Consolidating the headers and modulemaps for XCFramework generation"
# copies the generated header from AutomergeUniffi/automergeFFI.h to
# Sources/_CAutomergeUniffi/include/automergeFFI.h within the project
cp "${SWIFT_FOLDER}/automergeFFI.h" "${SWIFT_FOLDER}/../Sources/_CAutomergeUniffi/include"
cp "${SWIFT_FOLDER}/automergeFFI.modulemap" "${SWIFT_FOLDER}/../Sources/_CAutomergeUniffi/include/module.modulemap"
# copies the generated header into the build folder structure for local XCFramework usage
mkdir -p "${BUILD_FOLDER}/includes"
cp "${SWIFT_FOLDER}/automergeFFI.h" "${BUILD_FOLDER}/includes"
cp "${SWIFT_FOLDER}/automergeFFI.modulemap" "${BUILD_FOLDER}/includes/module.modulemap"

echo "▸ Lipo (merge) x86 and arm simulator static libraries into a fat static binary"
mkdir -p "${BUILD_FOLDER}/ios-simulator/release"
lipo -create  \
    "${BUILD_FOLDER}/x86_64-apple-ios/release/${LIB_NAME}" \
    "${BUILD_FOLDER}/aarch64-apple-ios-sim/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/ios-simulator/release/${LIB_NAME}"

echo "▸ arm simulator static libraries into a static binary"
mkdir -p "${BUILD_FOLDER}/visionos-simulator/release"
lipo -create  \
    "${BUILD_FOLDER}/aarch64-apple-visionos-sim/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/visionos-simulator/release/${LIB_NAME}"

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
    -library "$BUILD_FOLDER/aarch64-apple-visionos/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "${BUILD_FOLDER}/visionos-simulator/release/${LIB_NAME}" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "$BUILD_FOLDER/aarch64-apple-ios/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "${BUILD_FOLDER}/ios-simulator/release/${LIB_NAME}" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "$BUILD_FOLDER/apple-darwin/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -library "$BUILD_FOLDER/apple-macabi/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -output "${XCFRAMEWORK_FOLDER}"

# per feedback from Apple DTS, privacy manifests are 'resources' for the purpose
# of including that manifest in an XCFramework - so there's two locations for
# supporting iOS and macOS.
# https://developer.apple.com/documentation/bundleresources/placing_content_in_a_bundle
PRIVACY_FOLDER="${THIS_SCRIPT_DIR}/../privacy"

# macOS
mkdir -p ${XCFRAMEWORK_FOLDER}/macos-arm64_x86_64/Versions
mkdir -p ${XCFRAMEWORK_FOLDER}/macos-arm64_x86_64/Versions/A
mkdir -p ${XCFRAMEWORK_FOLDER}/macos-arm64_x86_64/Versions/A/Resources
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/macos-arm64_x86_64/Versions/A/Resources

# Mac Catalyst
mkdir -p ${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-maccatalyst/Versions
mkdir -p ${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-maccatalyst/Versions/A
mkdir -p ${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-maccatalyst/Versions/A/Resources
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-maccatalyst/Versions/A/Resources

# iOS
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/ios-arm64/

# iOS simulator
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-simulator/

# Mac Catalyst
mkdir -p ${XCFRAMEWORK_FOLDER}/visionos-arm64_x86_64-maccatalyst/Versions
mkdir -p ${XCFRAMEWORK_FOLDER}/visionos-arm64_x86_64-maccatalyst/Versions/A
mkdir -p ${XCFRAMEWORK_FOLDER}/visionos-arm64_x86_64-maccatalyst/Versions/A/Resources
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-maccatalyst/Versions/A/Resources

# visionos
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/xros-arm64/

# visionos simulator
cp ${PRIVACY_FOLDER}/PrivacyInfo.xcprivacy ${XCFRAMEWORK_FOLDER}/xros-arm64-simulator/


echo "▸ Expose libuniffi_automerge.a WebAssembly archive"
cp "${BUILD_FOLDER}/wasm32-wasip1/release/libuniffi_automerge.a" "$THIS_SCRIPT_DIR/../"
cp "${BUILD_FOLDER}/wasm32-wasip1-threads/release/libuniffi_automerge.a" "$THIS_SCRIPT_DIR/../libuniffi_automerge_threads.a"
