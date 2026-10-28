#!/usr/bin/env python3
"""Compare the retained alternating Release runs; leave historical reports intact."""
from pathlib import Path
from statistics import median
from datetime import datetime
from zoneinfo import ZoneInfo
import json

here = Path(__file__).resolve().parent
names = ['elements-1', 'copy-1', 'elements-2', 'copy-2']
reports = [json.loads((here / (n + '.json')).read_text()) for n in names]
historical_names = ['transform-original', 'transform-batching-2', 'transform-batching-3']
historical = [json.loads((here.parent / (n + '-macos-arm64.json')).read_text()) for n in historical_names]
for report in reports[1:] + historical:
    for field in ['harness_sha256', 'os', 'hardware', 'architecture', 'configuration',
                  'swift_version', 'xcode_version', 'packageResolved']:
        assert report['metadata'][field] == reports[0]['metadata'][field], field
    assert report['fixtures'] == reports[0]['fixtures']
    assert report['method'] == reports[0]['method']
assert reports[0]['method']['samples'] == 5 and reports[0]['method']['warmups'] == 1
rows = [{(r['fixture'], r['style']): r for r in report['results']} for report in reports + historical]
assert all(len(r) == 75 and list(r) == list(rows[0]) for r in rows)
for key in rows[0]:
    for row in rows:
        assert row[key]['pixelSettings'] == rows[0][key]['pixelSettings']
        assert all(len(row[key][op]['samplesMs']) == 5 for op in ['path', 'image'])

def samples(key, op, indices):
    return [v for i in indices for v in rows[i][key][op]['samplesMs']]

def val(key, op, indices):
    return median(samples(key, op, indices))

repeated = []
for key in rows[0]:
    for op in ['path', 'image']:
        ratios = [val(key, op, [c]) / val(key, op, [e]) for e, c in [(0, 1), (2, 3)]]
        if all(r > 1.05 for r in ratios):
            repeated.append({'fixture': key[0], 'style': key[1], 'operation': op, 'ratios': ratios,
                             'deltaMs': val(key, op, [1, 3]) - val(key, op, [0, 2])})
(here / 'repeated-slowdowns.json').write_text(json.dumps(repeated, indent=2) + '\n')
lines = ['# Release comparison: copy-and-append versus elements', '',
         'Same unchanged harness, machine, software, dependency pins, fixtures and settings.',
         'Fresh runs alternate elements/copy/elements/copy. Each run uses one warm-up and',
         'five measured samples per operation. Tables pool ten samples per implementation.',
         'Times are milliseconds; speedup is elements ÷ copy (greater than 1 is faster).', '',
         '| Run | Started (Los Angeles) | Raw samples | Reconstructable source |',
         '| --- | --- | --- | --- |']
for name, report in zip(names, reports):
    started = datetime.fromisoformat(report['metadata']['startedAt']).astimezone(ZoneInfo('America/Los_Angeles'))
    lines.append(f'| {name} | {started:%Y-%m-%d %H:%M:%S %Z} | [JSON]({name}.json) | [Snapshot]({name}.json.source-state.json) |')
lines += ['', '## Repeatability check', '',
          f'{len(repeated)} case/operation combinations were more than 5% slower for copy in both adjacent pairs.',
          'This is a descriptive noise screen, not a statistical significance claim.',
          'The three unchanged styles (roundedRect, horizontal, vertical) are controls.', '']
if repeated:
    lines += ['| Fixture | Style | Operation | Pair 1 change | Pair 2 change | Pooled delta (ms) |',
              '| --- | --- | --- | ---: | ---: | ---: |']
    for r in repeated:
        lines.append(f"| {r['fixture']} | {r['style']} | {r['operation']} | {(r['ratios'][0]-1)*100:+.1f}% | {(r['ratios'][1]-1)*100:+.1f}% | {r['deltaMs']:+.4f} |")
for fixture in ['small', 'medium', 'large']:
    lines += ['', f'## {fixture.title()}', '',
              '| Style | Elements path | Copy path | Path speedup | Elements image | Copy image | Image speedup |',
              '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
    for key in rows[0]:
        if key[0] != fixture: continue
        ep, cp = [val(key, 'path', i) for i in [[0, 2], [1, 3]]]
        ei, ci = [val(key, 'image', i) for i in [[0, 2], [1, 3]]]
        lines.append(f'| {key[1]} | {ep:.4f} | {cp:.4f} | {ep/cp:.2f}× | {ei:.4f} | {ci:.4f} | {ei/ci:.2f}× |')
lines += ['', '## Historical original and batching references', '',
          'These original and batching measurements were retained from the earlier investigation,',
          'not rerun in this alternating experiment. Metadata/harness/fixtures/settings match, but',
          'the time separation means small differences must not be treated as causal evidence.', '',
          '| Large style | Original path | Batching path | Copy path | Original image | Batching image | Copy image |',
          '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for key in rows[0]:
    if key[0] != 'large': continue
    values = [val(key, op, indices) for op in ['path', 'image'] for indices in [[4], [5, 6], [1, 3]]]
    lines.append('| ' + key[1] + ' | ' + ' | '.join(f'{v:.4f}' for v in values) + ' |')
lines += ['', '## Sample ranges', '',
          '| Fixture | Style | Operation | Elements min–max | Copy min–max |',
          '| --- | --- | --- | ---: | ---: |']
for key in rows[0]:
    for op in ['path', 'image']:
        e, c = [samples(key, op, i) for i in [[0, 2], [1, 3]]]
        lines.append(f'| {key[0]} | {key[1]} | {op} | {min(e):.4f}–{max(e):.4f} | {min(c):.4f}–{max(c):.4f} |')
(here / 'comparison.md').write_text('\n'.join(lines) + '\n')
print('Repeated slowdowns:', repeated)
for key in [('small', 'square'), ('large', 'gear'), ('large', 'donut'), ('large', 'grid4x4')]:
    print(key, {op: {'elements': val(key, op, [0, 2]), 'copy': val(key, op, [1, 3])} for op in ['path', 'image']})
