#!/usr/bin/env bash
set -eou pipefail

# see https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

$THIS_SCRIPT_DIR/rustfmt.sh
$THIS_SCRIPT_DIR/clippy.sh
$THIS_SCRIPT_DIR/test.sh
