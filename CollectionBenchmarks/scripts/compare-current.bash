#/usr/bin/env bash

set -eou pipefail
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BENCHMARK_DIR=$THIS_SCRIPT_DIR/../

pushd ${BENCHMARK_DIR}

rm -rf Current
mkdir -p Current

swift run -c release CollectionBenchmarks \
    library run Current/results.json \
    --library Library.json \
    --cycles 3 \
    --mode replace-all

# library subcommands:
# - list, run, render

# results subcommands:
# - list-tasks, compare, merge, delete

# swift run -c release CollectionBenchmarks results list-tasks Current/results.json
#
# Building for production...
# Build complete! (0.16s)
# Text - append
# Text - append and read
# List - Integer append
# Map - Integer append

swift run -c release CollectionBenchmarks results compare Baselines/results.json Current/results.json
swift run -c release CollectionBenchmarks results compare Baselines/results.json Current/results.json --output diff.html
