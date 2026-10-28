# Matched Release measurements for all 43 pixel styles

The [main report](../README.md) is generated from this directory's three runs:
`copy-1`, `original`, `copy-2`. Each run uses every style returned by
`QRCodePixelShapeFactory.shared.all()`, all three fixed payloads, one warm-up and
five measured samples per path/image operation. This is 129 cases and 1,290 raw
measured samples per report.

The expanded harness is identical across runs. It differs from the historical
25-style harness only in style discovery, recorded style names/titles and flushing
progress output after each case, outside timing. The new report does not mix old
and new harness results.

Run order is copy/original/copy in one temporary checkout, using the same build
cache serially. Each JSON has a `.source-state.json` companion with the base
revision, patch, new file contents and hashes of the source/test/build inputs.
The base revision `ce204d0` is preserved on
[codex/pixel-path-elements](https://github.com/ChaseC99/dagronf-QRCode/tree/codex/pixel-path-elements).

The original variant restores every tracked production file from `a8b8a51`.
It also retains the unused copy helper so the same test target compiles; no
original production generator calls that helper. Verification checks the
original production bytes, identical non-production inputs, and matching copy
states against the final source.

```sh
python3 Benchmarks/all-styles-copy-evaluation/render-readme.py
python3 Benchmarks/all-styles-copy-evaluation/verify-sources.py
```

Neither command reruns timings. The report generator updates only
`Benchmarks/README.md`; the earlier `transform-elements-evaluation/comparison.md`
is left unchanged. See [HARNESS.md](../HARNESS.md) for fresh measurements.
