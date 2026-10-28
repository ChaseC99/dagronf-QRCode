#!/usr/bin/env python3
"""Generate Benchmarks/README.md from the matched 43-style Release reports."""
from pathlib import Path
from statistics import median
from datetime import datetime
from zoneinfo import ZoneInfo
import json

here = Path(__file__).resolve().parent
root = here.parent
names = ['original', 'copy-1', 'copy-2']
reports = [json.loads((here / (n + '.json')).read_text()) for n in names]
for report in reports[1:]:
    for field in ['harness_sha256', 'hardware', 'architecture', 'os', 'configuration',
                  'swift_version', 'xcode_version', 'packageResolved', 'processorCount', 'physicalMemoryBytes']:
        assert report['metadata'][field] == reports[0]['metadata'][field], field
    assert report['method'] == reports[0]['method']
    assert report['fixtures'] == reports[0]['fixtures']
assert reports[0]['metadata']['configuration'] == 'release'
assert reports[0]['method']['samples'] == 5 and reports[0]['method']['warmups'] == 1
styles = reports[0]['method']['styles']
assert len(styles) == len(set(styles)) == 43
rows = [{(r['fixture'], r['style']): r for r in report['results']} for report in reports]
assert all(len(r) == 129 and list(r) == list(rows[0]) for r in rows)
for key in rows[0]:
    for row in rows:
        assert row[key]['pixelSettings'] == rows[0][key]['pixelSettings']
        assert row[key]['styleTitle'] == rows[0][key]['styleTitle']
        for op in ['path', 'image']: assert len(row[key][op]['samplesMs']) == 5

def samples(key, op, variant):
    return [v for i in ([0] if variant == 'original' else [1, 2]) for v in rows[i][key][op]['samplesMs']]

def value(key, op, variant):
    return median(samples(key, op, variant))

def table(fixture):
    lines = ['| Style | Original path (ms) | Copy path (ms) | Path speedup | Original image (ms) | Copy image (ms) | Image speedup |',
             '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
    for style in styles:
        key = (fixture, style)
        op, cp = [value(key, 'path', v) for v in ['original', 'copy']]
        oi, ci = [value(key, 'image', v) for v in ['original', 'copy']]
        label = rows[0][key]['styleTitle'] + ('†' if style in ['roundedRect', 'horizontal', 'vertical'] else '')
        lines.append(f'| {label} | {op:,.3f} | {cp:,.3f} | {op/cp:,.2f}× | {oi:,.3f} | {ci:,.3f} | {oi/ci:,.2f}× |')
    return '\n'.join(lines)

key = ('large', 'gear')
op, cp = [value(key, 'path', v) for v in ['original', 'copy']]
oi, ci = [value(key, 'image', v) for v in ['original', 'copy']]
text = f'''# QRCode rendering performance: all 43 styles

The `addPixelPath` helper transforms a copy of each incoming pixel template, then
appends it with an identity transform. This avoids repeated scans of the growing
destination observed in native transformed appends on this Mac, without batching
or a per-element command switch.

**Large Gear complete-image generation: {oi/1000:.2f} seconds → {ci:,.2f} ms
({oi/ci:.1f}× faster).** Its pixel-path construction falls from {op:,.3f} ms to
{cp:,.3f} ms ({op/cp:,.1f}× faster).

The tables below include **every registered style: 43 styles × three fixtures ×
two operations**, measured with the same expanded Release harness. These are new
43-style original/copy runs; no missing styles were filled in from the older
25-style reports. All medians are milliseconds. Speedup = original median ÷ copy
median; values below 1 are slower. † marks the three unchanged identity-append
styles used as controls.

The output investigation found exact image, SVG, PNG-pixel and rendered-PDF
agreement across all 43 styles and four designs; 46 selected tests passed in Debug
and Release. Cached control-point bounds and tiny coordinate rounding can still
differ. See [correctness and compatibility](copy-append-library-evaluation/README.md).
'''
fixtures = {f['name']: f for f in reports[0]['fixtures']}
for name in ['large', 'medium', 'small']:
    f = fixtures[name]
    text += f'''\n## {name.title()} QR codes — all 43 styles

{f['utf8Bytes']:,}-byte {'URL' if name == 'small' else 'vCard'} · high error correction ·
{f['activeDataModules']:,} active data modules · {f['imageWidth']} × {f['imageHeight']} image.

{table(name)}
'''
text += '''
## Methodology

| Setting | Value |
| --- | --- |
| Hardware | Apple M1 Pro, MacBookPro18,1; 10 cores; 32 GiB RAM; arm64 |
| Software | macOS 26.7.1 (25G241), Xcode 27.1 (27A9275), Swift 6.4 |
| Build | Release |
| Coverage | All 43 registered default pixel styles; three fixed payloads; path and image separately |
| Sampling | One warm-up, then five measured samples per operation/case/run |
| Run order | Copy 1 → original → copy 2, serially in one temporary checkout |
| Aggregation | Median of five original samples versus ten pooled copy samples |
| Clock | DispatchTime.uptimeNanoseconds |

All runs use the same harness hash, style settings, payloads, prepared matrix
fingerprints, dependencies, hardware, OS and toolchain. The Core Image encoder uses
high error correction; rendering uses black foreground, white background, square
eyes, no logo and four additional quiet-zone modules. A target dimension of 720
is rounded down to whole pixels per module, producing the image sizes above.
No agent builds or tests run concurrently with timed measurements.

- **Path** times only pixel-generator construction on a prepared, eye-masked matrix.
- **Image** times `QRCode.cgImage`, including context allocation, masking, all paths,
  drawing and `makeImage`.
- QR encoding, fixture/design preparation, validation, destruction, PNG conversion
  and scanning are outside the timing boundaries.

Path and image are measured independently; their medians are not additive. A
separate path median can exceed an image median because of measurement variation.
Every raw sample is retained without outlier removal. The original has one run,
so its between-run variability is not established; these are descriptive timings,
not statistical significance claims.
'''
vo, vc = [value(('large', 'vertical'), 'image', v) for v in ['original', 'copy']]
text += f'''
The unchanged large Vertical control measures {vo:.3f} → {vc:.3f} ms
({(vc/vo-1)*100:+.1f}%) for complete images. Its generator is unchanged. This substantial
control variation limits attributing modest render-time differences to the helper;
the slower values remain in the tables and raw samples.
'''
text += '''
The earlier alternating element-wise/copy comparison found path-only copying
costs for Flower and Gear alongside gains for Square and grids. Those
[tradeoffs](copy-append-library-evaluation/comparison.md) remain documented; the
simpler implementation is not claimed to beat element-wise construction in every
workload. That older experiment has 25 styles and is separate from this table.

No physical-iPhone performance, other OS versions, allocation/memory use or power
consumption has been measured. The CoreGraphics behavior is an observation of the
installed implementation, not a cross-platform complexity guarantee.

## Raw samples and source states

| Run | Started (Los Angeles) | Test duration | Samples | Reconstructable source |
| --- | --- | ---: | --- | --- |
'''
for index in [1, 0, 2]:
    name, report = names[index], reports[index]
    meta = report['metadata']
    started = datetime.fromisoformat(meta['startedAt']).astimezone(ZoneInfo('America/Los_Angeles'))
    seconds = (datetime.fromisoformat(meta['finishedAt']) - datetime.fromisoformat(meta['startedAt'])).total_seconds()
    path = 'all-styles-copy-evaluation/' + name + '.json'
    text += f'| {name} | {started:%Y-%m-%d %H:%M:%S %Z} | {seconds:,.0f} s | [JSON]({path}) | [Snapshot]({path}.source-state.json) |\n'
text += '''
Durations exclude build time and include fixture setup and warm-ups. Each report
contains 129 cases, with five path samples and five image samples per case,
including medians, minima, maxima and standard deviations. Source snapshots record
the exact measured files, not merely the branch name after publication.

Regenerate this README and verify the retained source states:

```sh
python3 Benchmarks/all-styles-copy-evaluation/render-readme.py
python3 Benchmarks/all-styles-copy-evaluation/verify-sources.py
```

Use the [harness guide](HARNESS.md) for fresh measurements, always with a new output
filename. The older [element-wise comparison](transform-elements-evaluation/comparison.md)
is retained unchanged as historical evidence and does not describe the current helper.

## Branches and implementation

| Branch | Contents |
| --- | --- |
| [pixel-path-performance](https://github.com/ChaseC99/dagronf-QRCode/tree/pixel-path-performance) | One commit above main: copy-and-append helper, mechanical accumulation updates and focused correctness tests |
| [render-benchmarks](https://github.com/ChaseC99/dagronf-QRCode/tree/render-benchmarks) | Performance branch plus a separate opt-in, all-43-style benchmark commit |
| [pixel-path-research](https://github.com/ChaseC99/dagronf-QRCode/tree/pixel-path-research) | Benchmarks plus full output/native-reference tests, investigations, reports and source snapshots |
| [codex/pixel-path-elements](https://github.com/ChaseC99/dagronf-QRCode/tree/codex/pixel-path-elements) | Preserved previous element-wise implementation, its benchmark harness and all prior research at ce204d0 |

The benchmark-only commit can be cherry-picked onto another implementation for a
matched comparison. [CoreGraphics findings](cgmutablepath-findings.md), the
[copy-and-append evaluation](copy-append-library-evaluation/README.md), and the
[historical investigation](history.md) explain the implementation and its limits.
'''
(root / 'README.md').write_text(text)
print('Verified matched reports and wrote', root / 'README.md', 'with 43 styles in each of three tables.')
