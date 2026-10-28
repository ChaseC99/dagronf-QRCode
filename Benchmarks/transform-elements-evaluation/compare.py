#!/usr/bin/env python3
"""Rebuild the comparison from retained raw reports; never alters those reports."""
from pathlib import Path
import json
from statistics import median
from datetime import datetime
from zoneinfo import ZoneInfo

here = Path(__file__).resolve().parent
root = here.parent
names = ["transform-original", "transform-batching-2", "transform-elements-3",
         "transform-batching-3", "transform-elements-4"]
reports = [json.loads((root / (name + "-macos-arm64.json")).read_text()) for name in names]
for report in reports[1:]:
    for field in ["revision", "harness_sha256", "os", "hardware", "swift_version", "xcode_version", "packageResolved"]:
        assert report["metadata"][field] == reports[0]["metadata"][field], field
    assert report["fixtures"] == reports[0]["fixtures"]
    assert report["method"] == reports[0]["method"]
rows = [{(r["fixture"], r["style"]): r for r in report["results"]} for report in reports]
assert all(list(r) == list(rows[0]) for r in rows)

def samples(key, operation, variant):
    indices = {"original": [0], "batching": [1, 3], "elements": [2, 4]}[variant]
    return [v for i in indices for v in rows[i][key][operation]["samplesMs"]]

def value(key, operation, variant):
    return median(samples(key, operation, variant))

out = ["# Release comparison: original, batching, element-wise accumulation", "",
       "Measurements on Apple M1 Pro / MacBookPro18,1, macOS 26.7.1 (25G241), Xcode 27.1 / Swift 6.4. "
       "These are macOS results; no physical-iPhone performance claim is made.", "",
       "The unchanged 25-style harness covers three fixed fixtures, 75 cases and 750 measured samples per run. "
       "Each operation/case has one warm-up and five samples. Original medians use five samples; batching "
       "and final candidate medians pool ten samples from two separate alternating runs. Full images include "
       "context allocation, masking, paths, drawing and makeImage. Path timings include only the pixel generator "
       "on the prepared matrix. Encoding, fixture preparation, validation and destruction are outside timing.", "",
       "## Recorded runs", "", "| Started (Los Angeles) | Variant | Test duration | Raw samples and source state |",
       "| --- | --- | ---: | --- |"]
for name, report in zip(names, reports):
    m = report["metadata"]
    seconds = (datetime.fromisoformat(m["finishedAt"]) - datetime.fromisoformat(m["startedAt"])).total_seconds()
    filename = name + "-macos-arm64.json"
    started = datetime.fromisoformat(m["startedAt"]).astimezone(ZoneInfo("America/Los_Angeles"))
    out.append(f"| {started:%Y-%m-%d %H:%M %Z} | {name} | {seconds:.0f} s | [JSON](../{filename}), [source](../{filename}.source-state.json) |")
out += ["", "The paired order was batching 2 → elements 3 → batching 3 → elements 4, followed by the original reference. "
        "All five reports have identical harness hashes, fixtures/matrix fingerprints, settings, dependency pins, "
        "hardware, OS and toolchain metadata. Runs were serial in the same temporary checkout; no other agent "
        "builds or tests ran during measurements. Build time is excluded above.", "", "## Large fixture", "",
        "Median milliseconds. Speedup is batching / elements, so values above 1 favor the replacement.", "",
        "| Style | Original path | Batched path | Element path | Path speedup | Original image | Batched image | Element image | Image speedup |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
for key in rows[0]:
    if key[0] != "large": continue
    p = [value(key, "path", v) for v in ["original", "batching", "elements"]]
    i = [value(key, "image", v) for v in ["original", "batching", "elements"]]
    out.append(f"| {key[1]} | {p[0]:.3f} | {p[1]:.3f} | {p[2]:.3f} | {p[1]/p[2]:.2f}× | {i[0]:.3f} | {i[1]:.3f} | {i[2]:.3f} | {i[1]/i[2]:.2f}× |")
flags = []
for key in rows[0]:
    for operation in ["path", "image"]:
        ratios = [rows[e][key][operation]["medianMs"] / rows[b][key][operation]["medianMs"] for b, e in [(1, 2), (3, 4)]]
        if min(ratios) > 1.05: flags.append((key, operation, ratios))
out += ["", "## Repeats, small cases and limits", "",
        f"Across all 150 case/operation combinations, **{len(flags)}** had a median increase greater than 5% in both adjacent batching/candidate pairs. "
        "This is a practical noise screen, not a statistical confidence interval or a guarantee for unmeasured workloads.", ""]
for key, operation, ratios in flags:
    out.append(f"- Repeat flag: {key}, {operation}, candidate/batching {ratios}.")
for operation in ["path", "image"]:
    key = ("small", "square")
    b, e = value(key, operation, "batching"), value(key, operation, "elements")
    ratios = [rows[ei][key][operation]["medianMs"] / rows[bi][key][operation]["medianMs"] for bi, ei in [(1, 2), (3, 4)]]
    out.append(f"Small Square {operation}: pooled {b:.4f} → {e:.4f} ms ({(e/b-1)*100:+.1f}%, {e-b:+.4f} ms); "
               f"individual-pair changes were {(ratios[0]-1)*100:+.1f}% and {(ratios[1]-1)*100:+.1f}%.")
    out.append("")
out += ["The small Square increases are disclosed rather than described as universal speedups. Their absolute size is small; "
        "the >5% increase did not repeat in the second pair. Large Square also changed direction between pairs. "
        "Full-image measurements vary more than path measurements, including the unchanged Horizontal/Vertical controls. "
        "Rounded Rectangle retains its identity append but loses the incoming common-generator batching bookkeeping, "
        "so its improvement is not attributed to the new helper.", "",
        "No material repeatable regression was identified in these measured workloads. More complex path construction "
        "improves substantially; complete-image gains are smaller where drawing dominates. Native transformed appends "
        "show much steeper size scaling on this installed OS. Memory, power and physical-iPhone performance were not measured.", "",
        "## All cases", "", "Cells are median [minimum–maximum] milliseconds, using five original or ten pooled comparison samples.", "",
        "| Fixture | Style | Operation | Original | Batching | Elements |", "| --- | --- | --- | ---: | ---: | ---: |"]
for key in rows[0]:
    for operation in ["path", "image"]:
        cells = []
        for variant in ["original", "batching", "elements"]:
            values = samples(key, operation, variant)
            cells.append(f"{median(values):.3f} [{min(values):.3f}–{max(values):.3f}]")
        out.append(f"| {key[0]} | {key[1]} | {operation} | " + " | ".join(cells) + " |")
(here / "comparison.md").write_text("\n".join(out) + "\n")
print("Verified comparison inputs and wrote", here / "comparison.md")
