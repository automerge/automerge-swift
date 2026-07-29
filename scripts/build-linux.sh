#!/usr/bin/env bash
set -euo pipefail

readonly EXPECTED_SWIFT_SERIES="6.3"
readonly EXPECTED_RUST_VERSION="1.89.0"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
readonly REPOSITORY_ROOT="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd -P)"
readonly RUST_MANIFEST="${REPOSITORY_ROOT}/rust/Cargo.toml"
readonly RUST_TARGET_DIR="${REPOSITORY_ROOT}/rust/target"
readonly ARCHIVE_PATH="${RUST_TARGET_DIR}/release/libuniffi_automerge.a"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "missing prerequisite: '$1' is not on PATH"
}

if [[ "$(uname -s)" != "Linux" ]]; then
    fail "Linux archive builds are supported only on Linux; detected $(uname -s)"
fi

case "$(uname -m)" in
    x86_64 | aarch64) ;;
    *) fail "unsupported Linux architecture '$(uname -m)'; expected x86_64 or aarch64" ;;
esac

for command_name in cargo cmp diff mktemp rustc swift; do
    require_command "${command_name}"
done

readonly SWIFT_VERSION_OUTPUT="$(swift --version 2>&1)"
readonly RUST_VERSION_OUTPUT="$(rustc --version 2>&1)"
readonly CARGO_VERSION_OUTPUT="$(cargo --version 2>&1)"

if [[ ! "${SWIFT_VERSION_OUTPUT}" =~ Swift[[:space:]]version[[:space:]]6\.3(\.|[[:space:]]) ]]; then
    fail "Swift ${EXPECTED_SWIFT_SERIES}.x is required; found: ${SWIFT_VERSION_OUTPUT%%$'\n'*}"
fi

if [[ "${RUST_VERSION_OUTPUT}" != "rustc ${EXPECTED_RUST_VERSION} "* ]]; then
    fail "Rust ${EXPECTED_RUST_VERSION} is required; found: ${RUST_VERSION_OUTPUT}"
fi

if [[ "${CARGO_VERSION_OUTPUT}" != "cargo ${EXPECTED_RUST_VERSION} "* ]]; then
    fail "Cargo ${EXPECTED_RUST_VERSION} is required; found: ${CARGO_VERSION_OUTPUT}"
fi

[[ -f "${RUST_MANIFEST}" ]] || fail "missing Rust manifest at ${RUST_MANIFEST}"
[[ -f "${REPOSITORY_ROOT}/rust/Cargo.lock" ]] || fail "missing rust/Cargo.lock"
[[ -f "${REPOSITORY_ROOT}/rust/src/automerge.udl" ]] || fail "missing UniFFI definition"

readonly RUST_HOST="$(rustc --version --verbose | while IFS= read -r version_line; do
    if [[ "${version_line}" == host:\ * ]]; then
        printf '%s\n' "${version_line#host: }"
        break
    fi
done)"
[[ -n "${RUST_HOST}" ]] || fail "could not determine the Rust host target"

# Rust defaults to a `cc` linker. The official full Swift Noble image ships
# `clang` but no `cc` shim, so select clang explicitly in that environment.
readonly RUST_LINKER_VARIABLE_RAW="CARGO_TARGET_${RUST_HOST^^}_LINKER"
readonly RUST_LINKER_VARIABLE="${RUST_LINKER_VARIABLE_RAW//-/_}"
if ! command -v cc >/dev/null 2>&1 && [[ -z "${!RUST_LINKER_VARIABLE:-}" ]]; then
    require_command clang
    export "${RUST_LINKER_VARIABLE}=$(command -v clang)"
    printf 'Using %s as the Rust linker\n' "${!RUST_LINKER_VARIABLE}" >&2
fi

printf 'Building Linux archive with %s and %s\n' \
    "${SWIFT_VERSION_OUTPUT%%$'\n'*}" "${RUST_VERSION_OUTPUT}" >&2

readonly GENERATED_BINDINGS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/automerge-swift-bindings.XXXXXX")"
cleanup() {
    rm -rf -- "${GENERATED_BINDINGS_DIR}"
}
trap cleanup EXIT

# Generate into a temporary directory so this check never edits the checkout.
# If these files differ, the checked-in Swift ABI contract does not match the
# Rust/UDL sources that will be compiled into the archive.
cargo run \
    --manifest-path "${RUST_MANIFEST}" \
    --target-dir "${RUST_TARGET_DIR}" \
    --locked \
    --release \
    --features=uniffi/cli \
    --bin uniffi-bindgen \
    -- generate \
    "${REPOSITORY_ROOT}/rust/src/automerge.udl" \
    --language swift \
    --out-dir "${GENERATED_BINDINGS_DIR}" \
    1>&2

compare_generated_binding() {
    local generated_path="$1"
    local checked_in_path="$2"

    if ! cmp --silent "${generated_path}" "${checked_in_path}"; then
        diff --unified "${checked_in_path}" "${generated_path}" >&2 || true
        fail "generated UniFFI binding differs from ${checked_in_path#${REPOSITORY_ROOT}/}; regenerate all native bindings before building"
    fi
}

compare_generated_binding \
    "${GENERATED_BINDINGS_DIR}/automerge.swift" \
    "${REPOSITORY_ROOT}/AutomergeUniffi/automerge.swift"
compare_generated_binding \
    "${GENERATED_BINDINGS_DIR}/automergeFFI.h" \
    "${REPOSITORY_ROOT}/Sources/_CAutomergeUniffi/include/automergeFFI.h"
compare_generated_binding \
    "${GENERATED_BINDINGS_DIR}/automergeFFI.modulemap" \
    "${REPOSITORY_ROOT}/Sources/_CAutomergeUniffi/include/module.modulemap"

cargo build \
    --manifest-path "${RUST_MANIFEST}" \
    --target-dir "${RUST_TARGET_DIR}" \
    --locked \
    --release \
    --lib \
    1>&2

[[ -s "${ARCHIVE_PATH}" ]] || fail "Cargo completed without producing ${ARCHIVE_PATH}"

# Standard output is intentionally only the absolute archive path so callers
# can safely use: ARCHIVE_PATH="$(./scripts/build-linux.sh)"
printf '%s\n' "${ARCHIVE_PATH}"
