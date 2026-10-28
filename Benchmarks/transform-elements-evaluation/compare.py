#!/usr/bin/env python3
"""Rebuild only the historical 25-style baseline/elements comparison."""
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


def samples(key, operation, variant):
    indices = {"baseline": [0], "elements": [1, 2]}[variant]
    return [v for i in indices for v in rows[i][key][operation]["samplesMs"]]


def value(key, operation, variant):
    return median(samples(key, operation, variant))


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
for destination, content in [(here / "comparison.md", "\n".join(out))]:
    destination.write_text(content)
    print("Verified comparison inputs and wrote", destination)
