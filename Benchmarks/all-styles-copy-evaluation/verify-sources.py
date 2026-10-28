#!/usr/bin/env python3
"""Verify the all-style reports and reconstruct their exact source states."""
from pathlib import Path
import base64
import hashlib
import json
import subprocess
import tempfile

here = Path(__file__).resolve().parent
root = here.parent.parent
names = ['copy-1', 'original', 'copy-2']
states = []
verification = []
for name in names:
    report = json.loads((here / (name + '.json')).read_text())
    sidecar = here / (name + '.json.source-state.json')
    assert hashlib.sha256(sidecar.read_bytes()).hexdigest() == report['metadata']['source_state_sha256']
    state = json.loads(sidecar.read_text())
    states.append(state)
    with tempfile.TemporaryDirectory(prefix='qrcode-all-style-verify-') as temporary:
        destination = Path(temporary)
        roots = subprocess.check_output(['git', 'ls-tree', '--name-only', state['revision']], cwd=root).decode().splitlines()
        inputs = [p for p in ['Sources', 'Tests', 'scripts', 'Package.swift', 'Package.resolved'] if p in roots]
        archive = subprocess.Popen(['git', 'archive', state['revision'], *inputs], cwd=root, stdout=subprocess.PIPE)
        subprocess.run(['tar', '-x', '-C', temporary], stdin=archive.stdout, check=True)
        archive.stdout.close()
        assert archive.wait() == 0
        if state['trackedDiff'].strip():
            subprocess.run(['git', 'apply', '--binary', '-'], cwd=destination, input=state['trackedDiff'].encode(), check=True)
        for path, data in state['untrackedFilesBase64'].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            target = destination / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(base64.b64decode(data))
        for path, sha in state['fileSHA256'].items():
            assert hashlib.sha256((destination / path).read_bytes()).hexdigest() == sha, (name, path)
        if name == 'original':
            baseline = 'a8b8a5166e072156baf66ec2fff0850aa14b5297'
            originals = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', baseline, '--', 'Sources'], cwd=root).decode().splitlines()
            for path in originals:
                data = subprocess.check_output(['git', 'show', baseline + ':' + path], cwd=root)
                assert (destination / path).read_bytes() == data, path
    verification.append({'report': name, 'verifiedFileHashes': len(state['fileSHA256'])})
    print(name, 'verified', len(state['fileSHA256']), 'files')
assert states[0]['fileSHA256'] == states[2]['fileSHA256']
for path, sha in states[0]['fileSHA256'].items():
    if not path.startswith('Sources/'):
        assert states[1]['fileSHA256'][path] == sha, path
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == sha, path
(here / 'source-verification.json').write_text(json.dumps({
    'reports': verification, 'originalTrackedProductionMatchesBaseline': True,
    'sameInputsOutsideProduction': True, 'bothCopyRunsMatchCurrentInputs': True,
}, indent=2) + '\n')
print('Original production matches baseline; both copy runs match current inputs; harness and other inputs are identical.')
