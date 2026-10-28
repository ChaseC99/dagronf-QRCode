#!/bin/bash
# Run from any directory; the optional output path is relative to the caller.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
output="${1:-$root/.build/benchmarks/render-release.json}"
mkdir -p "$(dirname "$output")"
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"
cd "$root"

# Preserve reports and their reconstructable source snapshots, including new files.
if [[ -e "$output" || -e "$output.source-state.json" ]]; then
  echo "Refusing to overwrite benchmark report or source state: $output" >&2
  exit 1
fi
python3 scripts/benchmark-source-state.py "$output.source-state.json"
export QRCODE_BENCHMARK_SOURCE_STATE_SHA256="$(shasum -a 256 "$output.source-state.json" | cut -d ' ' -f 1)"

export QRCODE_BENCHMARK=1
export QRCODE_BENCHMARK_OUTPUT="$output"
export QRCODE_BENCHMARK_ROOT="$root"
export QRCODE_BENCHMARK_REVISION="$(git rev-parse HEAD)"
export QRCODE_BENCHMARK_SOURCE_TREE="$(git rev-parse HEAD:Sources)"
export QRCODE_BENCHMARK_SOURCE_DIFF_SHA256="$(git diff HEAD -- Sources | shasum -a 256 | cut -d ' ' -f 1)"
export QRCODE_BENCHMARK_WORKTREE_STATUS="$(git status --porcelain)"
export QRCODE_BENCHMARK_HARNESS_SHA256="$(shasum -a 256 Tests/QRCodeTests/QRCodePerformanceTests.swift | cut -d ' ' -f 1)"
export QRCODE_BENCHMARK_SWIFT_VERSION="$(swift --version)"
export QRCODE_BENCHMARK_XCODE_VERSION="$(xcodebuild -version)"
export QRCODE_BENCHMARK_HARDWARE="$(sysctl -n machdep.cpu.brand_string) / $(sysctl -n hw.model)"
export QRCODE_BENCHMARK_ARCHITECTURE="$(uname -m)"

# Serial execution is deliberate. Do not run other benchmarks alongside this one.
swift test -c release --filter QRCodePerformanceTests.testRenderBaseline
