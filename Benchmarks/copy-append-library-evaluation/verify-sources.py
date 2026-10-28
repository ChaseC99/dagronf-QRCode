#!/usr/bin/env python3
"""Reconstruct all four benchmark input states and verify their recorded hashes."""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check-current', action='store_true', help='Also check the reconstructed measured checkout and rewrite its verification record')
args = parser.parse_args()

here = Path(__file__).resolve().parent
root = here.parent.parent
names = ['elements-1', 'copy-1', 'elements-2', 'copy-2', 'validation']
helper = 'Sources/QRCode/styles/data/pixel/private/CGMutablePath+PixelPath.swift'
verified = []
states = []
for name in names:
    source = here / (name + ('.source-state.json' if name == 'validation' else '.json.source-state.json'))
    if name != 'validation':
        report = json.loads((here / (name + '.json')).read_text())
        assert hashlib.sha256(source.read_bytes()).hexdigest() == report['metadata']['source_state_sha256']
    state = json.loads(source.read_text())
    states.append(state)
    with tempfile.TemporaryDirectory(prefix='qrcode-copy-verification-') as temporary:
        destination = Path(temporary)
        tracked_roots = subprocess.check_output(['git', 'ls-tree', '--name-only', state['revision']], cwd=root).decode().splitlines()
        inputs = [p for p in ['Sources', 'Tests', 'scripts', 'Package.swift', 'Package.resolved'] if p in tracked_roots]
        archive = subprocess.Popen(['git', 'archive', state['revision'], *inputs], cwd=root, stdout=subprocess.PIPE)
        subprocess.run(['tar', '-x', '-C', temporary], stdin=archive.stdout, check=True)
        archive.stdout.close()
        assert archive.wait() == 0
        if state['trackedDiff'].strip():
            subprocess.run(['git', 'apply', '--binary', '-'], cwd=destination,
                           input=state['trackedDiff'].encode(), check=True)
        for path, data in state['untrackedFilesBase64'].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            target = destination / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(base64.b64decode(data))
        for path, sha in state['fileSHA256'].items():
            assert hashlib.sha256((destination / path).read_bytes()).hexdigest() == sha, (name, path)
    verified.append({'report': name, 'verifiedFileHashes': len(state['fileSHA256'])})
    print(name, 'verified', len(state['fileSHA256']), 'files')
assert states[0]['fileSHA256'] == states[2]['fileSHA256']
assert states[1]['fileSHA256'] == states[3]['fileSHA256']
assert {p for p in states[0]['fileSHA256'] if states[0]['fileSHA256'][p] != states[1]['fileSHA256'][p]} == {helper}
assert states[0]['fileSHA256'][helper] == hashlib.sha256(subprocess.check_output(
    ['git', 'show', states[0]['revision'] + ':' + helper], cwd=root)).hexdigest()
assert {p for p in states[3]['fileSHA256'] if states[3]['fileSHA256'][p] != states[4]['fileSHA256'][p]} == {
    'Tests/QRCodeTests/QRCodePixelOutputEquivalenceTests.swift'}
if not args.check_current:
    print('All archived sources verified; current checkout and historical verification record left unchanged.')
    raise SystemExit(0)
for path, sha in states[-1]['fileSHA256'].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == sha, path
(here / 'source-verification.json').write_text(json.dumps({
    'reports': verified, 'onlyHelperDiffersBetweenVariants': True,
    'elementsHelperMatchesBaseCommit': True, 'currentInputsMatchFinalValidation': True,
    'finalValidationDiffersFromTimedCopyOnlyInOutputTest': True,
}, indent=2) + '\n')
print('Only helper differs between timed variants; validation differs only in the output test and matches current inputs.')
