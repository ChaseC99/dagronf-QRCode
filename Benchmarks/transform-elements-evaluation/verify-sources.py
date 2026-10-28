#!/usr/bin/env python3
"""Verify archived comparison inputs, optionally checking the final checkout too."""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--archives-only", action="store_true",
                    help="Verify recorded inputs without checking the current tree or rewriting the saved verification record")
args = parser.parse_args()

here = Path(__file__).resolve().parent
root = here.parent.parent
names = ["transform-original", "transform-batching-2", "transform-elements-3",
         "transform-batching-3", "transform-elements-4"]
verified = []
final_state = None
for name in names:
    report_path = root / "Benchmarks" / (name + "-macos-arm64.json")
    report = json.loads(report_path.read_text())
    state_path = Path(str(report_path) + ".source-state.json")
    state_sha = hashlib.sha256(state_path.read_bytes()).hexdigest()
    assert state_sha == report["metadata"]["source_state_sha256"]
    state = json.loads(state_path.read_text())
    with tempfile.TemporaryDirectory(prefix="qrcode-source-verification-") as temporary:
        destination = Path(temporary)
        archive = subprocess.Popen(["git", "archive", state["revision"]], cwd=root, stdout=subprocess.PIPE)
        subprocess.run(["tar", "-x", "-C", temporary], stdin=archive.stdout, check=True)
        archive.stdout.close()
        assert archive.wait() == 0
        native_sources = {str(p.relative_to(destination)): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in (destination / "Sources").rglob("*") if p.is_file()}
        if state["trackedDiff"].strip():
            subprocess.run(["git", "apply", "--binary", "-"], input=state["trackedDiff"].encode(),
                           cwd=destination, check=True)
        for path, encoded in state["untrackedFilesBase64"].items():
            assert not Path(path).is_absolute() and ".." not in Path(path).parts
            target = destination / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(base64.b64decode(encoded))
        for path, expected in state["fileSHA256"].items():
            assert hashlib.sha256((destination / path).read_bytes()).hexdigest() == expected, path
        if name == "transform-original":
            for path, expected in native_sources.items():
                assert state["fileSHA256"][path] == expected, path
    verified.append({"report": report_path.name, "verifiedFileHashes": len(state["fileSHA256"]),
                     "sourceStateSHA256": state_sha})
    print(name, len(state["fileSHA256"]), "file hashes verified")
    final_state = state
if args.archives_only:
    print("Verified all archived comparison inputs; current checkout and saved verification record left unchanged.")
    raise SystemExit(0)
for path, expected in final_state["fileSHA256"].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, path
assert not (root / "Sources/QRCode/styles/data/pixel/private/QRCodeBatchedModulePath.swift").exists()
(here / "source-verification.json").write_text(json.dumps({
    "reports": verified, "originalTrackedSourcesMatchHEAD": True,
    "mainCheckoutMatchesFinalInputs": True,
}, indent=2) + "\n")
print("Verified original production sources and unchanged final inputs in the main checkout.")
