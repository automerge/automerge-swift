#!/usr/bin/env bash

# bash "strict" mode
# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euxo pipefail

THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
FRAMEWORK_NAME="automergeFFI"
XCFRAMEWORK_FOLDER="$THIS_SCRIPT_DIR/../${FRAMEWORK_NAME}.xcframework"

echo "▸ code-sign the XCFramework"
codesign --timestamp -v --sign "Apple Development: Joseph Heck (RGF7P769P6)" ${FRAMEWORK_NAME}.xcframework

echo "▸ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_FOLDER" "$XCFRAMEWORK_FOLDER.zip"

echo "▸ Compute checksum"
openssl dgst -sha256 "$XCFRAMEWORK_FOLDER.zip"

