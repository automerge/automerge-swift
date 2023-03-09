# CollectionBenchmarks

List the available benchmarks:

    swift run -c release CollectionBenchmarks info --tasks

Run the benchmarks for sizes from 1 to 300,000, iterating 5 times, and put the results into the file `./temp`:

    swift run -c release CollectionBenchmarks run --max-size 300000 --cycles 5 ./temp

Render the benchmark results into an image named `./temp.png`:

    swift run -c release CollectionBenchmarks render ./temp temp.png

Generate and report the baselines for tasks defined in `Library.json`:

```bash
swift run -c release CollectionBenchmarks \
    library run Baselines/results.json \
    --library Library.json \
    --cycles 5 \
    --mode replace-all

swift run -c release CollectionBenchmarks \
    library render Baselines/results.json \
    --library Library.json \
    --output Baselines
```

