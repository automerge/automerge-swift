#!/usr/bin/env bash
set -eou pipefail

# see https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PACKAGE_PATH=$THIS_SCRIPT_DIR/../
BUILD_DIR=$PACKAGE_PATH/.build

pushd ${PACKAGE_PATH}
# Enables deterministic output
# - useful when you're committing the results to host on github pages
export DOCC_JSON_PRETTYPRINT=YES

# Swift package plugin for hosted content:
#
$(xcrun --find swift) package \
    --allow-writing-to-directory ./docs \
    generate-documentation \
    --fallback-bundle-identifier com.github.automerge.automerge-swifter \
    --target Automerge \
    --output-path ${PACKAGE_PATH}/docs \
    --emit-digest \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path 'automerge-swifter' \

# The following options are Swift 5.8  *only* and add github reference
# links to the hosted documentation.
#    --source-service github \
#    --source-service-base-url https://github.com/automerge/automerge-swifter/blob/main \
#    --checkout-path ${PACKAGE_PATH}

