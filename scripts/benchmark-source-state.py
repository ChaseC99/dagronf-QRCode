#!/usr/bin/env python3
"""Record benchmark inputs, plus the dirty/new content needed to reconstruct HEAD."""
import base64
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def git(*args):
    return subprocess.check_output(["git", *args])


# Include resources, build configuration, test harnesses and scripts, not generated reports.
paths = ["Sources", "Tests", "scripts", "Package.swift", "Package.resolved"]
tracked = set(git("ls-files", "-z", "--", *paths).decode().split("\0")) - {""}
untracked = set(git("ls-files", "--others", "--exclude-standard", "-z", "--", *paths).decode().split("\0")) - {""}
files = sorted(path for path in tracked | untracked if Path(path).is_file())
state = {
    "revision": git("rev-parse", "HEAD").decode().strip(),
    "worktreeStatus": git("status", "--porcelain").decode(),
    "fileSHA256": {path: hashlib.sha256(Path(path).read_bytes()).hexdigest() for path in files},
    "trackedDiff": git("diff", "--binary", "HEAD", "--", *paths).decode(),
    "untrackedFilesBase64": {
        path: base64.b64encode(Path(path).read_bytes()).decode() for path in sorted(untracked)
    },
}
with open(sys.argv[1], "x") as output:
    json.dump(state, output, indent=2, sort_keys=True)
    output.write("\n")
