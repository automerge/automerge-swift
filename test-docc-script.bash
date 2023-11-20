#!/usr/bin/env bash
set -eou pipefail

# see https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PACKAGE_PATH=$THIS_SCRIPT_DIR/
BUILD_DIR=$PACKAGE_PATH/.build

#echo "THIS_SCRIPT_DIR= ${THIS_SCRIPT_DIR}"
#echo "PACKAGE_PATH = ${PACKAGE_PATH}"
#echo "BUILD_DIR = ${BUILD_DIR}"
pushd ${PACKAGE_PATH}

# Enables deterministic output
# - useful when you're committing the results to host on github pages
export DOCC_JSON_PRETTYPRINT=YES

# Sets the reference to the XCFramework to local instead of network resolved,
# inside Package.swift for this library
export LOCAL_BUILD=YES

# mkdir -p "${BUILD_DIR}/symbol-graphs"
#
# $(xcrun --find swift) build --target Automerge \
#    -Xswiftc -emit-symbol-graph \
#    -Xswiftc -emit-symbol-graph-dir -Xswiftc "${BUILD_DIR}/symbol-graphs"
#
# $(xcrun --find docc) convert Sources/Automerge/Automerge.docc \
#     --output-path ./docs \
#     --fallback-display-name Automerge \
#     --fallback-bundle-identifier com.github.automerge.automerge-swift \
#     --fallback-bundle-version 0.0.1 \
#     --additional-symbol-graph-dir "${BUILD_DIR}/symbol-graphs" \
#     --emit-digest \
#     --transform-for-static-hosting \
#     --hosting-base-path 'automerge-swift'

# The following options are Swift 5.8  *only* and add github reference
# links to the hosted documentation.
#    --source-service github \
#    --source-service-base-url https://github.com/automerge/automerge-swift/blob/main \
#    --checkout-path ${PACKAGE_PATH}

# Swift package plugin for hosted content - this _should_ work, but it's not generating
# any symbols in the resulting documentation. Swift 5.6 to 5.9 doesn't support the plugin
# with a _local_ XCFframework reference.
#   Bug filed: https://github.com/apple/swift-docc-plugin/issues/52
# The workaround is to buld and extract the symbols to generate the documentation
# manually.

export PATH=$PATH:~/src/swift-project/build/Ninja-RelWithDebInfoAssert/swift-macosx-arm64/bin/

~/src/swift-project/build/Ninja-RelWithDebInfoAssert/swift-macosx-arm64/bin/swift package \
#$(xcrun --find swift) package \
    -v \
    --allow-writing-to-directory ./docs \
    generate-documentation \
    --fallback-bundle-identifier com.github.automerge.automerge-swift \
    --target Automerge \
    --output-path ${PACKAGE_PATH}/docs \
    --emit-digest \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path 'automerge-swift'

IDENTIFIER_COUNT=$(cat docs/linkable-entities.json | jq '.[].referenceURL' | wc -l)

echo "Generated ${IDENTIFIER_COUNT} identifiers/symbols"
