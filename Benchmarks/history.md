# Historical benchmark and batching investigations

These notes record successive experiments against `a8b8a51` on October 27–28,
2026. Statements such as “now,” “final,” and “next” refer to that stage of the
investigation. Batching was subsequently replaced by element-wise accumulation.
The recorded sources take precedence where earlier prose differs from later code;
see the [batching source audit](transform-before-append-evaluation/README.md#preserved-references-and-performance-scope).

Start with the [research overview](README.md) for the current recommendation,
the [final evaluation](transform-elements-evaluation/README.md) for the accepted
approach, or the [harness guide](HARNESS.md) to collect new measurements.
Historical reports, snapshots, and logs remain unchanged.

Run the opt-in XCTest benchmark on macOS from a quiet machine:

```sh
bash scripts/benchmark-render.sh
```

This builds and tests in **Release**, prints medians, and writes
`.build/benchmarks/render-release.json`. Ordinary test runs skip the benchmark.
There are no timing thresholds or additional Swift package dependencies. Source-state
capture uses Python 3 and its standard library.

To retain a named baseline or change the number of measured samples:

```sh
QRCODE_BENCHMARK_SAMPLES=7 bash scripts/benchmark-render.sh /tmp/baseline.json
```

The default is one warm-up and five measured samples per operation and case.
The large cases can take several minutes on an unoptimized implementation.
Keep the machine plugged in, avoid other heavy workloads, and use the same
hardware, OS, toolchain, dependencies, sample count, and harness for comparisons.
Repeat baseline and candidate runs in alternating order when evaluating a change.

## Workload

The current harness has 25 default pixel styles: the original six controls
(Square, Circle, Squircle, Flower, Gear, Rounded Rectangle), the five standalone
styles, and all 14 remaining generators. The original reports contain six styles,
the standalone reports contain 11, and the remaining-generator reports contain 25.
Three fixed payloads: a short URL, a medium vCard, and a large vCard
with a 95-repeat note (1,123 UTF-8 bytes). Payloads are included in the report.
All use the Core Image encoder and high error correction. Encoding happens once
per fixture, outside timing; style changes reuse that QR code.

The image has a black foreground, white background, square eyes with their default
pupils, no logo, and four **additional** quiet-zone modules on each side. This
setting is beyond any border already included by the encoder. A 720-pixel target
is rounded down to a whole number of pixels per module. The report records actual
matrix, image, and path dimensions, the active data-module count, and a fingerprint
of the masked matrix so differences between environments are visible.

Each case measures two operations separately:

| Measurement | Included |
| --- | --- |
| `path` | Pixel generator's `generatePath`, using a prepared matrix with eyes and border masked out, at the same module size as the image |
| `image` | `QRCode.cgImage`, including context creation, masking, all path construction, drawing, and image creation |

The path measurement excludes eye paths and drawing, so it is not the complete
vector export time. The image measurement excludes encoding, design/generator
construction, PNG conversion, scanning, and UI work. Neither uses `QRCode.Document`.

Measurements use a monotonic clock and alternate path/image order between samples.
Validation and object release occur after the timer stops, with an autorelease pool
per invocation. Validation checks nonempty paths and expected image dimensions;
this is a performance harness, not an assertion of visual equivalence.

## Comparing results

The JSON contains every sample in milliseconds, median, mean, minimum, maximum,
and population standard deviation. Compare medians for matching fixture/style/
operation combinations, and inspect spread before treating a difference as real.
Speedup is `baseline median / candidate median`.

Metadata records Git revision and working-tree status, the committed Sources tree
and tracked source diff hash, harness hash, resolved dependencies, CPU/model,
architecture, memory, core count, OS, Swift, Xcode, and build configuration.
Retain the patch as well if benchmarking an uncommitted source change; a hash does
not reconstruct it. The legacy source diff hash does not cover untracked source
files; new reports additionally retain reconstructable source-state sidecars
(see the standalone comparison below).

These are local macOS measurements. They do not establish physical-iPhone speedups.
The test can also run through Xcode on iOS with `QRCODE_BENCHMARK=1`, a writable
`QRCODE_BENCHMARK_OUTPUT` path in the test process, and optional
`QRCODE_BENCHMARK_SAMPLES`. The shell wrapper supplies desktop metadata; supply the
corresponding `QRCODE_BENCHMARK_*` values yourself for other destinations.

## Recorded baseline

[`baseline-macos-arm64.json`](baseline-macos-arm64.json) was collected on October 27,
2026 (America/Los_Angeles), against unchanged production sources at `a8b8a51`.
Machine: Apple M1 Pro, 10 cores, 32 GiB RAM; macOS 26.7.1; Xcode 27.1 / Swift 6.4.
The Release run passed all 18 cases (180 measured samples) in about 7.5 minutes.

Large vCard: 1,123 bytes, 171 × 171 matrix, 14,173 active data modules after masking,
716 × 716 image. Median milliseconds, with five samples after one warm-up:

| Style | Pixel path | Complete image |
| --- | ---: | ---: |
| Square | 633.481 | 631.933 |
| Circle | 1,772.083 | 1,837.830 |
| Squircle | 3,290.410 | 3,588.598 |
| Flower | 8,882.038 | 9,346.578 |
| Gear | 19,038.339 | 19,819.367 |
| Rounded Rectangle | 8.332 | 95.967 |

Path construction remains expensive in Release for the first five styles.
Rounded Rectangle has a different cost profile and is useful for checking that a
future change does not regress it. The operations are timed independently, so
small inversions such as Square's path/image medians reflect measurement variation.
For these large cases, standard deviation divided by mean was under 3% for both
operations. Raw samples and small/medium fixture results are retained in the JSON.

## Batching comparison

[`batched-macos-arm64.json`](batched-macos-arm64.json) uses the same harness,
environment, dependencies, settings, and encoded matrices as the baseline above.
The production change is limited to `CommonPixelGenerator`: accumulate 64 active
modules per temporary path, append each batch to the final path, and flush the
remainder. All geometry, transforms, traversal, and generator resets are preserved.
The batch size follows the earlier app experiment; it is not claimed to be optimal
for every style or device.

The 23 template-based styles use batching. Rounded Rectangle keeps its original
native path accumulation: an initial trial batching it increased path construction
time, so it is excluded from the final change.

Large-vCard medians in milliseconds (five samples after one warm-up):

| Style | Path before | Path after | Image before | Image after | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: |
| Square | 633.481 | 4.859 | 631.933 | 7.262 | 87.0× |
| Circle | 1,772.083 | 13.493 | 1,837.830 | 76.815 | 23.9× |
| Squircle | 3,290.410 | 18.745 | 3,588.598 | 304.794 | 11.8× |
| Flower | 8,882.038 | 50.895 | 9,346.578 | 491.639 | 19.0× |
| Gear | 19,038.339 | 101.803 | 19,819.367 | 874.702 | 22.7× |
| Rounded Rectangle (unbatched) | 8.332 | 7.788 | 95.967 | 86.848 | — |

The full run took about 15 seconds, versus 447 seconds for the original. The five
batched styles also improved full-image medians by 1.4–2.3× for the small fixture
and 6.1–21.1× for the medium fixture. Rounded Rectangle's image medians varied:
1.148→1.233 ms (small), 11.114→11.863 ms (medium), and 95.967→86.848 ms (large);
no speedup is attributed to that excluded style. Circle's large-image samples
ranged from 68.6 to 131.4 ms, so its median should be read alongside that variation.
These are local macOS results, not physical-iPhone results.

### Correctness checks

`QRCodePixelBatchingTests` compares 576 paths across all 24 shared pixel types
against an unbatched reference, first validated on the original production code.
The reference uses individual modules at their original matrix coordinates, with
stateful/spatial inset and rotation values evaluated against the complete matrix.
It reuses geometry code but does not exercise multi-module batching.

Checks cover empty and single-module matrices; sparse active counts around 64 and
128; odd/even dimensions; fractional rectangular sizes; custom and degenerate
settings; spatial and seeded random generators; and repeated renders. Path element
order, types, and point counts must match exactly, coordinates within 1e-10, and
RGBA raster output byte for byte. The coordinate tolerance accounts for tiny native
rectangle/ellipse expansion differences observed even before the production change.

The new suite passed in both Debug and Release. The final Release patch also passed
existing path, SVG, masking, export, and QR decoding tests (26 test methods total
including the new suite). To reproduce:

```sh
swift test -c release --filter 'QRCodePixelBatchingTests|QRCodePathTests|QRCodeSVGTests|QRCodeMaskingTests|QRCodeTests.testBasicDocumentionationCode|QRCodeDetectionTests.testBasicDetection'
bash scripts/benchmark-render.sh /tmp/batched.json
```

## Standalone template batching

Collected October 27, 2026 (America/Los_Angeles) on the same Apple M1 Pro,
10 cores / 32 GiB, macOS 26.7.1 (25G241), Xcode 27.1 (27A9275), Swift 6.4.
These are **macOS measurements**, not physical-iPhone measurements.

The five standalone styles now append transformed templates in groups of 64
emitted modules through the internal `QRCodeBatchedModulePath` accumulator.
Each complete group and final partial group is appended to one final vector path;
there is no separate drawing per group. Template geometry, transform expressions,
row/column traversal, subpath order, winding, and Donut/Diagonal Stripes' final
`closeSubpath()` calls are preserved. No neighbor-dependent generator or public
API changed. The pre-existing shared-pixel batching change remains intact.

The expanded harness adds these five styles after the six existing controls.
It retains all payloads, encoding, high error correction, quiet zone, colors,
output sizing, timing boundaries, validation, and alternating operation order.
Every operation/case uses one warm-up and five measured samples: 33 cases,
330 measured samples per report. BEFORE used the original five generators and
AFTER used batching, with exactly the same expanded harness.

| Fixture | Payload bytes | Matrix | Active data modules | Actual image |
| --- | ---: | --- | ---: | --- |
| small | 20 | 31 × 31 | 303 | 702 × 702 |
| medium | 298 | 91 × 91 | 3,863 | 693 × 693 |
| large | 1,123 | 171 × 171 | 14,173 | 716 × 716 |

Primary reports: [BEFORE](standalone-before-macos-arm64.json) and
[AFTER](standalone-after-macos-arm64.json). The measurement run took 532 seconds
before and 27 seconds after (build time excluded). All environment fields,
resolved dependencies, harness SHA-256, method settings, payloads, matrix
fingerprints, actual dimensions, case order, and pixel settings match.

The following tables report **median [minimum–maximum] milliseconds** from all
five samples. Speedup is BEFORE median / AFTER median. JSON reports also retain
every sample, mean, and population standard deviation. The primary pair is shown
in full, including noisy cases; repeat results are discussed below.

### Pixel-path construction

| Style | Payload | BEFORE ms [range] | AFTER ms [range] | Speedup |
| --- | --- | ---: | ---: | ---: |
| Grid 2×2 | small | 1.590 [1.462–1.629] | 0.337 [0.336–0.337] | 4.72× |
| Grid 3×3 | small | 3.371 [3.253–3.650] | 0.746 [0.742–0.795] | 4.52× |
| Grid 4×4 | small | 5.854 [5.805–6.383] | 1.312 [1.310–1.339] | 4.46× |
| Donut | small | 2.117 [1.983–2.533] | 0.482 [0.480–0.505] | 4.40× |
| Diagonal Stripes | small | 5.778 [5.571–6.594] | 1.302 [1.297–1.338] | 4.44× |
| Grid 2×2 | medium | 229.796 [225.349–239.418] | 4.496 [4.461–4.567] | 51.12× |
| Grid 3×3 | medium | 513.268 [505.816–516.974] | 10.062 [10.019–10.139] | 51.01× |
| Grid 4×4 | medium | 911.392 [907.898–935.320] | 17.615 [17.566–17.688] | 51.74× |
| Donut | medium | 317.898 [317.845–322.675] | 6.499 [6.429–6.547] | 48.92× |
| Diagonal Stripes | medium | 898.262 [889.323–930.088] | 17.478 [17.375–17.785] | 51.39× |
| Grid 2×2 | large | 3147.954 [3079.907–3524.269] | 16.706 [16.638–16.849] | 188.43× |
| Grid 3×3 | large | 7251.056 [7073.114–7389.109] | 38.491 [36.923–40.422] | 188.38× |
| Grid 4×4 | large | 12362.075 [12311.771–12391.174] | 65.312 [64.939–67.282] | 189.28× |
| Donut | large | 4348.380 [4325.618–4406.893] | 24.637 [24.049–25.182] | 176.50× |
| Diagonal Stripes | large | 12246.628 [12115.592–12426.784] | 64.207 [64.161–64.426] | 190.74× |

### Complete-image rendering

| Style | Payload | BEFORE ms [range] | AFTER ms [range] | Speedup |
| --- | --- | ---: | ---: | ---: |
| Grid 2×2 | small | 2.121 [2.048–2.372] | 0.858 [0.846–0.877] | 2.47× |
| Grid 3×3 | small | 4.208 [4.108–4.489] | 1.571 [1.554–1.635] | 2.68× |
| Grid 4×4 | small | 7.146 [6.999–7.561] | 2.395 [2.373–2.402] | 2.98× |
| Donut | small | 4.131 [3.838–4.473] | 2.270 [2.240–2.331] | 1.82× |
| Diagonal Stripes | small | 9.788 [9.586–10.196] | 4.605 [4.555–4.660] | 2.13× |
| Grid 2×2 | medium | 228.642 [227.854–232.278] | 7.720 [7.577–7.763] | 29.62× |
| Grid 3×3 | medium | 519.372 [516.125–526.300] | 18.904 [18.685–20.381] | 27.47× |
| Grid 4×4 | medium | 947.048 [930.596–984.921] | 30.961 [30.833–31.382] | 30.59× |
| Donut | medium | 368.002 [365.502–377.309] | 54.839 [54.640–55.465] | 6.71× |
| Diagonal Stripes | medium | 968.571 [960.596–1009.330] | 97.841 [97.149–97.931] | 9.90× |
| Grid 2×2 | large | 3090.975 [3078.505–3135.192] | 26.947 [26.788–27.223] | 114.71× |
| Grid 3×3 | large | 7183.933 [7059.240–7450.280] | 83.006 [80.446–87.629] | 86.55× |
| Grid 4×4 | large | 12526.184 [12498.295–12601.384] | 186.309 [185.794–195.130] | 67.23× |
| Donut | large | 4728.890 [4662.068–4811.809] | 382.554 [376.997–393.592] | 12.36× |
| Diagonal Stripes | large | 12974.215 [12771.891–13060.060] | 784.849 [773.303–791.967] | 16.53× |

### Controls and repeat measurements

The alternating BEFORE → AFTER → BEFORE-repeat → AFTER-repeat sequence retained
all four reports. [BEFORE repeat](standalone-before-repeat-macos-arm64.json) and
[AFTER repeat](standalone-after-repeat-macos-arm64.json) use source-state sidecars
identical to their respective original runs. All four reports have matching
environment, resolved dependencies, harness, fixtures, settings, and sample counts.

The initial medium Square image samples included a 14.934 ms outlier (median
2.687 ms; coefficient of variation, population SD / mean, 96.2%). The repeat
baseline median was 2.191 ms with 4.3% CV, versus 2.224 ms / 0.9% CV after.
The initial small Rounded Rectangle path had 26.3% CV; its repeat had 0.5% CV
before and 0.4% after. The small Circle image CV fell from 13.5% in the first
baseline to 0.6% in the repeat. The large original target cases were already
stable (0.2–5.2% CV), and their repeat baseline medians stayed within 2.2%.

Small control paths initially appeared up to 1.24× faster despite unchanged code.
That shift disappeared in the repeat (0.98–1.00×); small control images repeated
at 0.94–1.01×. Medium Circle/Squircle control images still varied by about 12%,
so small percentage changes are not attributed to this patch. No control shows
a regression exceeding observed variation in both pairs: medium Flower image
medians were 0.9% and 0.5% slower, within the sample spread. A spot check during the repeat
baseline showed Activity Monitor/system-monitoring CPU activity alongside XCTest,
although no competing builds/tests ran; this was not an isolated laboratory run.

Control speedups below are BEFORE median / AFTER median. All raw control samples
and variability are preserved in the reports.

| Control | Payload | Path, first pair | Image, first pair | Path, repeat | Image, repeat |
| --- | --- | ---: | ---: | ---: | ---: |
| Square | small | 1.04× | 1.07× | 0.98× | 0.94× |
| Circle | small | 1.05× | 1.03× | 1.00× | 0.99× |
| Squircle | small | 1.13× | 1.11× | 1.00× | 0.99× |
| Flower | small | 1.24× | 1.13× | 1.00× | 0.99× |
| Gear | small | 1.06× | 1.17× | 0.99× | 1.01× |
| Rounded Rectangle | small | 1.14× | 1.19× | 1.00× | 1.00× |
| Square | medium | 1.08× | 1.20× | 0.99× | 0.99× |
| Circle | medium | 1.02× | 1.05× | 1.08× | 1.12× |
| Squircle | medium | 1.02× | 1.02× | 1.06× | 1.12× |
| Flower | medium | 0.98× | 0.99× | 1.05× | 0.99× |
| Gear | medium | 1.02× | 1.01× | 1.02× | 1.02× |
| Rounded Rectangle | medium | 1.02× | 1.06× | 1.01× | 1.00× |
| Square | large | 1.00× | 1.01× | 1.00× | 1.00× |
| Circle | large | 1.02× | 1.03× | 1.01× | 0.98× |
| Squircle | large | 0.99× | 0.99× | 1.01× | 1.01× |
| Flower | large | 1.01× | 1.01× | 1.03× | 1.01× |
| Gear | large | 1.05× | 1.01× | 1.00× | 1.01× |
| Rounded Rectangle | large | 1.01× | 1.01× | 1.05× | 0.98× |

All five target styles improved in both pairs. The repeat yielded 4.13–4.27× path
and 1.74–2.84× image speedups for small payloads, 48.33–52.25× path and 6.47–31.10×
image speedups for medium payloads, and 184.51–193.84× path and 12.60–113.14× image
speedups for large payloads. Repeat target CVs were at most 5.6%. The primary
small-case estimates were somewhat optimistic, but every target still benefits.

<details>
<summary>Repeat target medians and min–max ranges (milliseconds)</summary>

**Pixel-path construction**

| Style | Payload | BEFORE repeat ms [range] | AFTER repeat ms [range] | Speedup |
| --- | --- | ---: | ---: | ---: |
| Grid 2×2 | small | 1.390 [1.388–1.406] | 0.336 [0.336–0.337] | 4.13× |
| Grid 3×3 | small | 3.139 [3.116–3.140] | 0.744 [0.743–0.759] | 4.22× |
| Grid 4×4 | small | 5.599 [5.539–5.697] | 1.312 [1.311–1.321] | 4.27× |
| Donut | small | 2.025 [1.968–2.042] | 0.481 [0.480–0.488] | 4.21× |
| Diagonal Stripes | small | 5.526 [5.427–5.648] | 1.303 [1.300–1.495] | 4.24× |
| Grid 2×2 | medium | 228.287 [224.053–238.556] | 4.462 [4.438–4.467] | 51.16× |
| Grid 3×3 | medium | 518.863 [503.238–536.237] | 9.997 [9.965–10.058] | 51.90× |
| Grid 4×4 | medium | 926.736 [897.226–953.026] | 17.737 [17.566–17.962] | 52.25× |
| Donut | medium | 322.476 [319.889–328.446] | 6.673 [6.521–6.861] | 48.33× |
| Diagonal Stripes | medium | 892.905 [887.684–913.782] | 17.462 [17.299–18.070] | 51.13× |
| Grid 2×2 | large | 3156.520 [3056.911–3240.108] | 16.689 [16.649–17.442] | 189.13× |
| Grid 3×3 | large | 7098.367 [6919.552–7145.865] | 37.421 [36.941–38.541] | 189.69× |
| Grid 4×4 | large | 12586.649 [12416.878–12749.101] | 64.935 [64.862–66.935] | 193.84× |
| Donut | large | 4416.642 [4334.836–4600.748] | 23.936 [23.846–25.380] | 184.51× |
| Diagonal Stripes | large | 12066.251 [12022.139–12275.922] | 64.164 [63.793–64.787] | 188.05× |

**Complete-image rendering**

| Style | Payload | BEFORE repeat ms [range] | AFTER repeat ms [range] | Speedup |
| --- | --- | ---: | ---: | ---: |
| Grid 2×2 | small | 1.939 [1.915–1.981] | 0.849 [0.839–0.878] | 2.28× |
| Grid 3×3 | small | 3.954 [3.941–3.976] | 1.549 [1.540–1.617] | 2.55× |
| Grid 4×4 | small | 6.785 [6.681–7.144] | 2.389 [2.368–2.398] | 2.84× |
| Donut | small | 3.913 [3.823–4.019] | 2.244 [2.229–2.278] | 1.74× |
| Diagonal Stripes | small | 8.852 [8.836–9.118] | 4.585 [4.570–5.147] | 1.93× |
| Grid 2×2 | medium | 232.040 [228.295–248.279] | 7.461 [7.457–7.654] | 31.10× |
| Grid 3×3 | medium | 519.866 [513.685–525.605] | 18.578 [18.563–19.922] | 27.98× |
| Grid 4×4 | medium | 925.964 [913.250–929.851] | 30.912 [30.697–31.445] | 29.96× |
| Donut | medium | 367.622 [365.718–382.384] | 56.795 [54.554–57.636] | 6.47× |
| Diagonal Stripes | medium | 982.237 [975.731–1010.796] | 97.933 [97.159–100.787] | 10.03× |
| Grid 2×2 | large | 3114.087 [3094.761–3230.103] | 27.525 [27.093–28.820] | 113.14× |
| Grid 3×3 | large | 7178.276 [6986.080–7284.215] | 80.820 [79.935–82.453] | 88.82× |
| Grid 4×4 | large | 12641.844 [12410.663–12738.705] | 187.769 [185.309–189.954] | 67.33× |
| Donut | large | 4787.405 [4676.181–4850.978] | 379.836 [378.098–387.986] | 12.60× |
| Diagonal Stripes | large | 12779.253 [12747.823–12903.510] | 786.356 [773.416–809.196] | 16.25× |

</details>

### Correctness and limits

`QRCodeStandaloneBatchingTests` passed against the original five generators in
Release **before** production changes. After batching, the selected regression
suite passed **30 tests in Debug and 30 in Release**, with zero failures. This
includes the four standalone tests, the shared-pixel suite, and existing path,
SVG, masking, image export, and QR detection tests. The standalone suite makes
187 path/raster comparisons and checks:

- All five styles; empty dimensions 0/1/8/9/12/13, single cells, sparse corner/edge
  cells, and dense odd/even matrices, including a dense 64-module matrix.
- Active counts 63/64/65 and 127/128/129 across dimensions 12 and 13, exact
  multiples, final remainders, and both orientations of fractional rectangular
  output sizes (197.25 × 153.75 and its transpose).
- Ordered element types, point counts and coordinates (1e-10 tolerance), plus
  byte-for-byte RGBA raster equality using a nonzero fill and translucent color.
- Exact move/close counts for 4/9/16 grid subpaths, two donut subpaths, and seven
  stripe subpaths per module, including exact and partial batches.
- Donut centers remain holes and rings remain filled under both nonzero and
  even-odd rules at every active cell, including batch boundaries and edges.

The reference appends one active module at a time at its original matrix location.
It shares the template/transform implementation but never exercises a full batch;
it is an accumulation-equivalence test, not an independent oracle for the original
artwork. The 1e-10 coordinate tolerance follows the earlier native-path expansion
findings; element ordering and raster bytes must match exactly. No claim is made
that 64 is the optimal group size, or that macOS timings predict iPhone gains.
These measurements do not cover memory usage, encoding, or vector-export latency.

### Exact source states and reproduction

Each new report has a sibling `<report>.source-state.json`, whose SHA-256 is
recorded in report metadata. It records HEAD, working-tree status, file hashes
for tracked/untracked Sources, Tests (including resources), scripts and tracked
package configuration, the complete binary-capable tracked diff against HEAD,
and the contents of all new files in those paths as base64. The new accumulator
is therefore captured even though it is untracked. The ignored `Package.resolved`
is recorded as parsed JSON in the benchmark's `metadata.packageResolved`.
The old reports remain unchanged. Neither HEAD nor a tracked diff alone identifies
these dirty source states.

Commands used (serially, with other builds/tests idle):

```sh
# Original standalone sources; expanded harness and tests already present:
bash scripts/benchmark-render.sh Benchmarks/standalone-before-macos-arm64.json
swift test -c release --filter QRCodeStandaloneBatchingTests

# After applying standalone batching:
swift test --filter 'QRCodeStandaloneBatchingTests|QRCodePixelBatchingTests|QRCodePathTests|QRCodeSVGTests|QRCodeMaskingTests|QRCodeTests.testBasicDocumentionationCode|QRCodeDetectionTests.testBasicDetection'
swift test -c release --filter 'QRCodeStandaloneBatchingTests|QRCodePixelBatchingTests|QRCodePathTests|QRCodeSVGTests|QRCodeMaskingTests|QRCodeTests.testBasicDocumentionationCode|QRCodeDetectionTests.testBasicDetection'
bash scripts/benchmark-render.sh Benchmarks/standalone-after-macos-arm64.json

# Restore the exact BEFORE source contents, then restore the exact AFTER contents:
bash scripts/benchmark-render.sh Benchmarks/standalone-before-repeat-macos-arm64.json
bash scripts/benchmark-render.sh Benchmarks/standalone-after-repeat-macos-arm64.json
```

The wrapper refuses to overwrite either a report or its source-state file.
Use fresh output names for additional runs. To reconstruct a recorded state in a
**new disposable checkout**, run this from the current repository (select any of
the four reports by changing `report`):

```sh
report="$PWD/Benchmarks/standalone-before-macos-arm64.json"
repro_dir="$(mktemp -d /tmp/qrcode-repro.XXXXXX)"
revision="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["metadata"]["revision"])' "$report")"
git worktree add --detach "$repro_dir" "$revision"
cd "$repro_dir"
python3 - "$report" <<'PYTHON'
import base64, hashlib, json, subprocess, sys
from pathlib import Path
report_path = Path(sys.argv[1])
report = json.loads(report_path.read_text())
state_bytes = Path(str(report_path) + '.source-state.json').read_bytes()
assert hashlib.sha256(state_bytes).hexdigest() == report['metadata']['source_state_sha256']
state = json.loads(state_bytes)
if state['trackedDiff']:
    subprocess.run(['git', 'apply', '--binary', '-'], input=state['trackedDiff'].encode(), check=True)
for name, content in state['untrackedFilesBase64'].items():
    path = Path(name)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(base64.b64decode(content))
for name, digest in state['fileSHA256'].items():
    assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == digest, name
Path('Package.resolved').write_text(json.dumps(report['metadata']['packageResolved'], indent=2) + '\n')
PYTHON
QRCODE_BENCHMARK_SAMPLES=5 bash scripts/benchmark-render.sh /tmp/reproduced-standalone.json
```

### Next candidates

Rounded Path, Blob, Circuit, and Drip are candidates for batching **emitted paths**.
Some emit geometry for off cells, so counting active cells alone would be wrong.
Before changing them, preserve complete neighborhood information and test all
512 possible 3×3 patterns, edges, and batch boundaries. Horizontal and Vertical
already merge runs into native rounded rectangles: benchmark them before changing
accumulation. Consider caching repeated geometry only if profiling shows it still
contributes materially after batching.

## Remaining generators completed

The [remaining-generator comparison](remaining-comparison.md) covers all 14
remaining styles, with complete medians, min–max ranges, controls, rejected trials,
repeat measurements, exact source states, reproduction commands, and limitations.
Twelve additional styles retain 64-emitted-path batching: Abstract, Rounded Path,
Blob, Circuit, both Drips, Crosshatch, Curve Pixel, Pointy, Razor, Rounded End Indent,
and Vortex. Horizontal and Vertical keep their original native merged-run paths
because batching regressed medium/large path construction. Overall, 40 of the 43
registered styles now batch; the three native exceptions are Rounded Rectangle,
Horizontal, and Vertical.

The first complete BEFORE/final-AFTER pair took 488/38 seconds (measurement only).
Large-payload paths improved 115–274× and images 17–86× for the 12 retained styles.
These are macOS measurements. All earlier reports and the pre-existing staged
change are preserved. The final patch passed 35 tests in both Debug and Release;
the new suite includes 50,353 path/raster comparisons, covering all 512 neighborhoods,
edges, off-cell emissions, exact batch boundaries, and seeded/spatial behavior.
The earlier “Next candidates” section records the assessment before this completed
follow-up. Geometry caching still requires profiling evidence before implementation.

The remaining-style repeat baseline encountered an external Xcode build near its
end. At the user's request, the work finished with the complete primary pair,
all-batched trial, and flagged baseline repeat; no additional AFTER repeat was
collected. See the detailed report's controls/noise section before interpreting
small differences or the unchanged Vertical image timings.
