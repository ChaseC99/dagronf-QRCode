# QRCode rendering performance: baseline vs. elements

The proposed `addPixelPath` helper transforms individual pixel-path elements as
it adds them. This avoids the repeated scan of the accumulated path's bounds
observed with native transformed appends on the tested macOS version.

**Large Gear image generation falls from 20.09 seconds to 800.96 ms
(25.1× faster).** The tables below compare the original library with
the proposed implementation using the same Release benchmark.

## Large QR codes

Complete image generation for a **1,123-byte vCard**, high error correction,
**14,173 active data modules**, and a **716 × 716** image. All 25 measured styles
are shown. Times are medians in milliseconds; lower is better.

| Style | Baseline (ms) | Elements (ms) | Speedup |
| --- | ---: | ---: | ---: |
| Square | 637.412 | 7.078 | 90.06× |
| Circle | 1,862.359 | 64.098 | 29.05× |
| Squircle | 3,608.131 | 291.804 | 12.36× |
| Flower | 9,383.248 | 450.992 | 20.81× |
| Gear | 20,088.497 | 800.960 | 25.08× |
| Rounded Rectangle† | 91.536 | 87.898 | 1.04× |
| Grid 2×2 | 3,101.833 | 18.333 | 169.20× |
| Grid 3×3 | 6,971.985 | 58.004 | 120.20× |
| Grid 4×4 | 12,777.947 | 144.462 | 88.45× |
| Donut | 4,875.411 | 364.587 | 13.37× |
| Diagonal Stripes | 12,906.573 | 738.476 | 17.48× |
| Abstract | 1,600.446 | 60.927 | 26.27× |
| Rounded Path | 2,449.491 | 40.129 | 61.04× |
| Blob | 4,589.168 | 67.458 | 68.03× |
| Circuit | 5,960.349 | 226.175 | 26.35× |
| Drip Horizontal | 3,912.983 | 134.378 | 29.12× |
| Drip Vertical | 3,777.832 | 112.280 | 33.65× |
| Crosshatch | 5,613.548 | 316.486 | 17.74× |
| Curve Pixel | 1,144.526 | 30.322 | 37.75× |
| Pointy | 676.930 | 7.743 | 87.42× |
| Razor | 2,856.414 | 52.113 | 54.81× |
| Rounded End Indent | 1,105.428 | 30.140 | 36.68× |
| Vortex | 1,473.840 | 56.172 | 26.24× |
| Horizontal† | 21.043 | 22.168 | 0.95× |
| Vertical† | 52.770 | 53.405 | 0.99× |

Speedup = baseline median ÷ elements median. Values above 1 indicate faster
rendering; values below 1 indicate slower rendering. † Rounded Rectangle,
Horizontal, and Vertical already use native appends without a non-identity
transform; they provide controls for measurement variability.

Path construction is measured separately. For large Gear, it falls from
**19,074.806 ms to 18.186 ms (1,048.9×)**. Complete-image gains
are smaller because image generation also includes drawing and other work.

## Small QR codes

A **20-byte URL**, high error correction, **303 active data modules**, and a
**702 × 702** image. These selected styles show the smaller absolute gains and
the three controls; [all styles and medium fixtures](transform-elements-evaluation/comparison.md)
are available in the detailed results.

| Style | Baseline (ms) | Elements (ms) | Observed result |
| --- | ---: | ---: | ---: |
| Square | 0.635 | 0.463 | 1.37× |
| Circle | 1.714 | 1.099 | 1.56× |
| Squircle | 3.314 | 2.168 | 1.53× |
| Flower | 6.918 | 3.156 | 2.19× |
| Gear | 11.261 | 3.235 | 3.48× |
| Grid 2×2 | 1.909 | 0.708 | 2.70× |
| Rounded Rectangle† | 1.139 | 1.174 | About the same |
| Horizontal† | 0.746 | 0.763 | About the same |
| Vertical† | 0.867 | 0.902 | About the same |

For the three small controls, the median differences are only **0.02–0.04 ms**
and the observed sample ranges overlap, so these timings are described as about
the same. This is a descriptive comparison, not a statistical significance test.

## Methodology

| Setting | Value |
| --- | --- |
| Machine | Apple M1 Pro, MacBookPro18,1, 32 GiB RAM, arm64 |
| Software | macOS 26.7.1 (25G241), Xcode 27.1 (27A9275), Swift 6.4 |
| Build | Release |
| Workloads | 25 pixel styles × 3 fixtures × 2 operations |
| Sampling | 1 warm-up, then 5 measured samples per operation and case, per run |
| Baseline | Original native-append implementation at `a8b8a51`; 1 run |
| Elements | Final element-wise implementation; runs 3 and 4 |
| Aggregation | Median of 5 baseline samples vs. median of 10 pooled elements samples |
| Timer | `DispatchTime.uptimeNanoseconds`, converted to milliseconds |

The same Core Image encoder, high error correction, default pixel-style settings,
black foreground, white background, square eyes, and no logo are used throughout.
The target dimension is 720 with `additionalQuietZonePixels = 4`; integer pixels
per module produce the actual image sizes below.

| Fixture | Payload | UTF-8 bytes | Active data modules | Image size |
| --- | --- | ---: | ---: | ---: |
| Small | URL | 20 | 303 | 702 × 702 |
| Medium | vCard | 298 | 3,863 | 693 × 693 |
| Large | vCard | 1,123 | 14,173 | 716 × 716 |

The image dimensions are similar across fixtures; QR complexity changes much
more than output resolution.

**What is timed**

- **Path:** pixel-generator work on a prepared, eye-masked matrix, excluding eyes
  and the quiet zone.
- **Image:** `QRCode.cgImage`, including context allocation, masking, all paths,
  drawing, and image creation.
- **Excluded:** QR encoding, fixture/design preparation, validation, object
  release, PNG conversion, and scanning. These are render timings, not total
  time from input text to an exported file.

Path and image calls are timed independently, alternating their order between
samples. Their medians are not additive; a separately measured path median can
occasionally exceed the image median because of measurement variability.

The reports match on harness hash, fixtures and matrix fingerprints, pixel
settings, dependency pins, hardware, OS, and toolchain. Measurements ran serially
in the same temporary checkout, with no concurrent agent builds or tests.
The baseline was collected after both elements runs. This was **one baseline
run and two elements runs**, not a randomized, alternating baseline/elements
experiment; between-run variability of the baseline is not established.

## Variability and limits

Some control measurements are slower: medium Horizontal **+9.2%**,
medium Vertical **+6.0%**, and large Horizontal **+5.3%**
for complete images. These observations are retained in the detailed results;
small differences should not be treated as proof of either an improvement or a
regression. The report includes every sample, with no outliers removed. Sample
ranges describe the observations, not confidence intervals.

These measurements establish behavior on this Mac and OS. Physical-iPhone
performance, other OS versions, memory use, and power consumption were not
measured. Correctness is assessed separately through the
[geometry and raster checks](transform-elements-evaluation/README.md#correctness-evidence).

## Raw results and reproduction

| Run | Started (Los Angeles) | Test duration | Raw samples | Source state |
| --- | --- | ---: | --- | --- |
| Baseline | 2026-10-27 23:41 PDT | 1,419 s | [JSON](transform-original-macos-arm64.json) | [Snapshot](transform-original-macos-arm64.json.source-state.json) |
| Elements — run 3 | 2026-10-27 23:36 PDT | 33 s | [JSON](transform-elements-3-macos-arm64.json) | [Snapshot](transform-elements-3-macos-arm64.json.source-state.json) |
| Elements — run 4 | 2026-10-27 23:38 PDT | 33 s | [JSON](transform-elements-4-macos-arm64.json) | [Snapshot](transform-elements-4-macos-arm64.json.source-state.json) |

Test duration excludes the build and includes the benchmark's setup and warm-up.
The [full comparison](transform-elements-evaluation/comparison.md) lists all
150 fixture/style/operation combinations, including median, minimum, maximum,
and speedup. Each JSON contains `path.samplesMs` and `image.samplesMs` for every
case, plus workload and environment metadata.

The source-state sidecars identify the exact measured inputs. Those snapshots
use the helper name `addTransformedPixelPath`; it was subsequently renamed to
`addPixelPath` without changing behavior.

Regenerate this README and the detailed comparison from the retained JSON,
without rerunning timings:

```sh
python3 Benchmarks/transform-elements-evaluation/compare.py
```

Verify archived source snapshots without rewriting their verification record:

```sh
python3 Benchmarks/transform-elements-evaluation/verify-sources.py --archives-only
```

See the [harness guide](HARNESS.md) to collect fresh measurements with a new
output filename and the [source-state restoration recipe](history.md#exact-source-states-and-reproduction)
to reconstruct a measured implementation.

## Implementation and research

| Reference | Contents |
| --- | --- |
| [Implementation evaluation](transform-elements-evaluation/README.md) | Helper contract, correctness evidence, and implementation decisions |
| [CoreGraphics findings](cgmutablepath-findings.md) | Why transformed appends repeatedly scan accumulated bounds |
| [Historical investigations](history.md) | Earlier experiments and their retained evidence |
| [Rejected proposal](transform-before-append-plan.md) and [evaluation](transform-before-append-evaluation/README.md) | Why whole-path transformation was rejected |

The `pixel-path-performance` branch contains the production change and focused
test. `render-benchmarks` adds the optional harness; `pixel-path-research` adds
the reports, research, and broader correctness tests. The benchmark commit
`ef85931` can be cherry-picked onto the baseline to use the same harness.
