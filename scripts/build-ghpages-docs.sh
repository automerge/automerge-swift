#!/usr/bin/env bash
set -eou pipefail

# see https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PACKAGE_PATH=$THIS_SCRIPT_DIR/../
BUILD_DIR=$PACKAGE_PATH/.build

swift build \
    --package-path $PACKAGE_PATH \
    --target Automerge \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir \
    -Xswiftc $BUILD_DIR
xcrun docc convert Automerge.docc \
    --fallback-display-name Automerge \
    --fallback-bundle-identifier org.automerge.Automerge \
    --fallback-bundle-version 1 \
    --additional-symbol-graph-dir $BUILD_DIR \
    --transform-for-static-hosting \
    --hosting-base-path automerge-swifter \
    --output-path $PACKAGE_PATH/docs/
