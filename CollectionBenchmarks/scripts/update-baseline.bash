#/usr/bin/env bash

set -eou pipefail
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BENCHMARK_DIR=$THIS_SCRIPT_DIR/../

pushd ${BENCHMARK_DIR}

swift run -c release CollectionBenchmarks \
    library run Baselines/results.json \
    --library Library.json \
    --cycles 5 \
    --mode replace-all

swift run -c release CollectionBenchmarks \
    library render Baselines/results.json \
    --library Library.json \
    --output Baselines
