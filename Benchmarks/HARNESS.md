# Render benchmark

Run the opt-in XCTest benchmark on macOS from a quiet machine:

```sh
bash scripts/benchmark-render.sh
```

This builds and tests in Release, prints medians, and writes
`.build/benchmarks/render-release.json` plus a reconstructable source-state sidecar.
Ordinary test runs skip the benchmark. There are no timing thresholds or additional
Swift package dependencies. Source-state capture requires Python 3.

To choose an output path and sample count:

```sh
QRCODE_BENCHMARK_SAMPLES=7 bash scripts/benchmark-render.sh /tmp/render.json
```

The default is one warm-up and five measured samples per operation and case.
Use a fresh output filename for each run; the wrapper refuses to overwrite reports
or their source-state sidecars. The output argument is relative to the caller.

## What is measured

The harness covers 25 pixel styles and three fixed payloads using the Core Image
encoder with high error correction. It measures pixel-path construction on a
prepared matrix and complete image generation separately. Encoding, fixture
preparation, validation, and object release are outside the timed intervals.
The image measurement includes context creation, masking, path construction,
drawing, and image creation; it excludes PNG conversion and scanning.

Reports include raw samples, medians, spread, workload settings, matrix
fingerprints, dependency pins, source hashes, and hardware/toolchain metadata.
Validation checks nonempty paths and expected image dimensions; it does not
establish visual equivalence.

## Comparing revisions

Use the same harness, machine, OS, toolchain, dependencies, workload settings, and
sample count for both revisions. Run measurements serially on a quiet machine,
and alternate baseline and candidate runs when evaluating a change. Compare
matching fixture/style/operation medians and inspect the raw samples for noise.
Speedup is baseline median divided by candidate median.

The benchmark commit is separate from the implementation commit so the same
harness can be applied to baseline and candidate checkouts. Preserve the report
and its `.source-state.json` sidecar together. Existing reports are evidence for
their recorded source states, not for every subsequent revision.

These are local macOS measurements. They do not establish physical-iPhone
performance, memory use, or power consumption.
