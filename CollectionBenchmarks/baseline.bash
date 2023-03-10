#/usr/bin/env bash
set -eou pipefail

swift run -c release CollectionBenchmarks \
    library run Baselines/results.json \
    --library Library.json \
    --cycles 5 \
    --mode replace-all

swift run -c release CollectionBenchmarks \
    library render Baselines/results.json \
    --library Library.json \
    --output Baselines
