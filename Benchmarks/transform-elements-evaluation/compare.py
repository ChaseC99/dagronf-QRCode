#!/usr/bin/env python3
"""Rebuild the baseline/elements README and comparison from retained raw reports."""
from pathlib import Path
import json
from statistics import median
from datetime import datetime
from zoneinfo import ZoneInfo

here = Path(__file__).resolve().parent
root = here.parent
names = ["transform-original", "transform-elements-3", "transform-elements-4"]
reports = [json.loads((root / (name + "-macos-arm64.json")).read_text()) for name in names]
for report in reports[1:]:
    for field in ["revision", "harness_sha256", "os", "hardware", "architecture", "configuration",
                  "swift_version", "xcode_version", "packageResolved"]:
        assert report["metadata"][field] == reports[0]["metadata"][field], field
    assert report["fixtures"] == reports[0]["fixtures"]
    assert report["method"] == reports[0]["method"]
assert reports[0]["metadata"]["configuration"] == "release"
assert reports[0]["method"]["samples"] == 5
assert reports[0]["method"]["warmups"] == 1
rows = [{(r["fixture"], r["style"]): r for r in report["results"]} for report in reports]
assert all(len(report["results"]) == len(row) == 75 for report, row in zip(reports, rows))
assert all(list(row) == list(rows[0]) for row in rows)
for key in rows[0]:
    for row in rows:
        assert row[key]["pixelSettings"] == rows[0][key]["pixelSettings"], key
        for operation in ["path", "image"]:
            assert len(row[key][operation]["samplesMs"]) == 5, (key, operation)

labels = {
    "square": "Square", "circle": "Circle", "squircle": "Squircle",
    "flower": "Flower", "gear": "Gear", "roundedRect": "Rounded Rectangle",
    "grid2x2": "Grid 2×2", "grid3x3": "Grid 3×3", "grid4x4": "Grid 4×4",
    "donut": "Donut", "diagonalStripes": "Diagonal Stripes", "abstract": "Abstract",
    "roundedPath": "Rounded Path", "blob": "Blob", "circuit": "Circuit",
    "dripHorizontal": "Drip Horizontal", "dripVertical": "Drip Vertical",
    "crosshatch": "Crosshatch", "curvePixel": "Curve Pixel", "pointy": "Pointy",
    "razor": "Razor", "roundedEndIndent": "Rounded End Indent", "vortex": "Vortex",
    "horizontal": "Horizontal", "vertical": "Vertical",
}
controls = {"roundedRect", "horizontal", "vertical"}


def samples(key, operation, variant):
    indices = {"baseline": [0], "elements": [1, 2]}[variant]
    return [v for i in indices for v in rows[i][key][operation]["samplesMs"]]


def value(key, operation, variant):
    return median(samples(key, operation, variant))


def image_table(fixture, styles, describe_controls=False):
    result_heading = "Observed result" if describe_controls else "Speedup"
    lines = [f"| Style | Baseline (ms) | Elements (ms) | {result_heading} |",
             "| --- | ---: | ---: | ---: |"]
    for style in styles:
        key = (fixture, style)
        baseline, elements = [value(key, "image", variant) for variant in ["baseline", "elements"]]
        label = labels[style] + ("†" if style in controls else "")
        result = "About the same" if describe_controls and style in controls else f"{baseline / elements:,.2f}×"
        lines.append(f"| {label} | {baseline:,.3f} | {elements:,.3f} | {result} |")
    return "\n".join(lines)


def run_table(prefix):
    lines = ["| Run | Started (Los Angeles) | Test duration | Raw samples | Source state |",
             "| --- | --- | ---: | --- | --- |"]
    for label, name, report in zip(["Baseline", "Elements — run 3", "Elements — run 4"], names, reports):
        m = report["metadata"]
        seconds = (datetime.fromisoformat(m["finishedAt"]) - datetime.fromisoformat(m["startedAt"])).total_seconds()
        started = datetime.fromisoformat(m["startedAt"]).astimezone(ZoneInfo("America/Los_Angeles"))
        filename = prefix + name + "-macos-arm64.json"
        lines.append(f"| {label} | {started:%Y-%m-%d %H:%M %Z} | {seconds:,.0f} s | [JSON]({filename}) | [Snapshot]({filename}.source-state.json) |")
    return "\n".join(lines)


fixtures = ["| Fixture | Payload | UTF-8 bytes | Active data modules | Image size |",
            "| --- | --- | ---: | ---: | ---: |"]
for fixture in reports[0]["fixtures"]:
    payload = "URL" if fixture["name"] == "small" else "vCard"
    fixtures.append(f"| {fixture['name'].title()} | {payload} | {fixture['utf8Bytes']:,} | "
                    f"{fixture['activeDataModules']:,} | {fixture['imageWidth']} × {fixture['imageHeight']} |")
fixture_table = "\n".join(fixtures)
large_styles = [style for fixture, style in rows[0] if fixture == "large"]
small_styles = ["square", "circle", "squircle", "flower", "gear", "grid2x2",
                "roundedRect", "horizontal", "vertical"]
gear_path = [value(("large", "gear"), "path", variant) for variant in ["baseline", "elements"]]
gear_image = [value(("large", "gear"), "image", variant) for variant in ["baseline", "elements"]]
control_changes = {}
for fixture, style in [("medium", "horizontal"), ("medium", "vertical"), ("large", "horizontal")]:
    key = (fixture, style)
    control_changes[key] = (value(key, "image", "elements") / value(key, "image", "baseline") - 1) * 100

readme = f"""# QRCode rendering performance: baseline vs. elements

The proposed `addPixelPath` helper transforms individual pixel-path elements as
it adds them. This avoids the repeated scan of the accumulated path's bounds
observed with native transformed appends on the tested macOS version.

**Large Gear image generation falls from {gear_image[0] / 1000:.2f} seconds to {gear_image[1]:,.2f} ms
({gear_image[0] / gear_image[1]:.1f}× faster).** The tables below compare the original library with
the proposed implementation using the same Release benchmark.

## Large QR codes

Complete image generation for a **1,123-byte vCard**, high error correction,
**14,173 active data modules**, and a **716 × 716** image. All 25 measured styles
are shown. Times are medians in milliseconds; lower is better.

{image_table('large', large_styles)}

Speedup = baseline median ÷ elements median. Values above 1 indicate faster
rendering; values below 1 indicate slower rendering. † Rounded Rectangle,
Horizontal, and Vertical already use native appends without a non-identity
transform; they provide controls for measurement variability.

Path construction is measured separately. For large Gear, it falls from
**{gear_path[0]:,.3f} ms to {gear_path[1]:,.3f} ms ({gear_path[0] / gear_path[1]:,.1f}×)**. Complete-image gains
are smaller because image generation also includes drawing and other work.

## Small QR codes

A **20-byte URL**, high error correction, **303 active data modules**, and a
**702 × 702** image. These selected styles show the smaller absolute gains and
the three controls; [all styles and medium fixtures](transform-elements-evaluation/comparison.md)
are available in the detailed results.

{image_table('small', small_styles, describe_controls=True)}

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

{fixture_table}

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

Some control measurements are slower: medium Horizontal **+{control_changes['medium', 'horizontal']:.1f}%**,
medium Vertical **+{control_changes['medium', 'vertical']:.1f}%**, and large Horizontal **+{control_changes['large', 'horizontal']:.1f}%**
for complete images. These observations are retained in the detailed results;
small differences should not be treated as proof of either an improvement or a
regression. The report includes every sample, with no outliers removed. Sample
ranges describe the observations, not confidence intervals.

These measurements establish behavior on this Mac and OS. Physical-iPhone
performance, other OS versions, memory use, and power consumption were not
measured. Correctness is assessed separately through the
[geometry and raster checks](transform-elements-evaluation/README.md#correctness-evidence).

## Raw results and reproduction

{run_table('')}

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
"""

out = ["# Baseline vs. elements: complete results", "",
       "All 25 styles, three fixtures, and both measured operations. See the",
       "[comparison README](../README.md) for the summary tables, methodology,",
       "timing boundaries, and limitations.", "",
       "Cells are **median [minimum–maximum] milliseconds**: five baseline samples",
       "or ten pooled samples from elements runs 3 and 4. Speedup is the baseline",
       "median divided by the elements median, calculated before rounding. Values",
       "below 1 indicate slower measurements. Ranges are not confidence intervals.", "",
       "## Recorded runs", "", run_table("../"), "",
       "The baseline ran after the two elements runs. All three reports use the same",
       "harness, fixtures, settings, dependencies, hardware, OS, and toolchain.", ""]
for fixture in reports[0]["fixtures"]:
    out += [f"## {fixture['name'].title()} fixture", "",
            f"{fixture['utf8Bytes']:,} UTF-8 bytes · {fixture['activeDataModules']:,} active data modules · "
            f"{fixture['imageWidth']} × {fixture['imageHeight']} image.", "",
            "| Style | Operation | Baseline (ms) | Elements (ms) | Speedup |",
            "| --- | --- | ---: | ---: | ---: |"]
    for key in rows[0]:
        if key[0] != fixture["name"]:
            continue
        for operation in ["path", "image"]:
            cells = []
            for variant in ["baseline", "elements"]:
                values = samples(key, operation, variant)
                cells.append(f"{median(values):,.3f} [{min(values):,.3f}–{max(values):,.3f}]")
            speedup = value(key, operation, "baseline") / value(key, operation, "elements")
            out.append(f"| {labels[key[1]]} | {operation.title()} | " + " | ".join(cells) + f" | {speedup:,.2f}× |")
    out.append("")
for destination, content in [(root / "README.md", readme), (here / "comparison.md", "\n".join(out))]:
    destination.write_text(content)
    print("Verified comparison inputs and wrote", destination)
