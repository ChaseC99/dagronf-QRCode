# Pixel-path performance research

The proposed change uses `CGMutablePath.addPixelPath` to expand pixel templates
and transform their individual elements before accumulation. It preserves native
append for an empty destination or an identity transform. This avoids repeatedly
scanning the accumulated path on the macOS implementation investigated here,
without batch state or a temporary transformed-path copy.

## Start here

| Question | Reference |
| --- | --- |
| What is proposed, and what is its contract? | [Final implementation evaluation](transform-elements-evaluation/README.md) |
| What did the measurements show? | [Original vs. batching vs. element-wise comparison](transform-elements-evaluation/comparison.md) |
| Why was path construction expensive? | [CoreGraphics findings](cgmutablepath-findings.md) |
| How do I collect comparable measurements? | [Benchmark harness guide](HARNESS.md) |
| What happened in the earlier batching experiments? | [Historical notes](history.md), [remaining-style comparison](remaining-comparison.md) |
| Why was whole-path transformation rejected? | [Original proposal](transform-before-append-plan.md), [rejected-candidate evaluation](transform-before-append-evaluation/README.md) |
| How do I recover an exact historical implementation? | [Source-state restoration recipe](history.md#exact-source-states-and-reproduction) |

## Decisions and limits

- Use element-wise accumulation for the 40 styles with transformed appends.
  The three styles using identity/native accumulation retain their append calls.
  Relative to `a8b8a51`, the generator edits are 165 method-name substitutions;
  template geometry, transforms, traversal, and winding stay intact.
- Keep the helper scoped to pixel templates. Pending move-only subpaths and
  arbitrary continuation of closed paths have native bookkeeping differences.
  Open contours ending in a line or curve are supported; start a new subpath
  when extending a completed result.
- Reject whole-path `copy(using:)` plus identity append as a general replacement:
  the investigations found differences in pending moves, control-point bounds,
  and primitive expansion coordinates. Batching remains a historical comparator.
- Retain independent native reference tests and exact raster comparisons as
  supporting evidence. Their `BatchingTests` names reflect the earlier work;
  the current production implementation does not batch.
- Treat the recorded timings as macOS evidence. Physical-iPhone performance,
  memory, power, and behavior on other OS versions remain open validation work.
  Small/noisy cases and the contended historical repeat are disclosed in the
  comparison reports; no universal speedup is claimed.

## Branches and review scope

All three branches start from `main` at `a8b8a51` and build on one another:

| Branch | Additional contents |
| --- | --- |
| `pixel-path-performance` | Production changes and the focused helper regression test (`b46bc3f`) |
| `render-benchmarks` | Opt-in performance test, two scripts, and harness guide (`ef85931`) |
| `pixel-path-research` | Full native references, broad style tests, reports, logs, and this documentation |

The benchmark commit can be cherry-picked onto the baseline for comparisons with
the same harness. The research was preserved in `c88bc24` before documentation
cleanup. These are local branches; no pull request or remote branch was published
as part of this organization.

## Evidence and reproduction

Raw JSON reports, source-state sidecars, figures, and evaluation logs remain at
their original paths. Each report describes its recorded source state. The saved
measurements and test logs precede the helper rename from `addTransformedPixelPath`
to `addPixelPath`; they are not byte-for-byte snapshots of the organized branches.

From the repository root on `pixel-path-research`, verify the five archived
comparison inputs and regenerate their comparison without rerunning timings:

```sh
python3 Benchmarks/transform-elements-evaluation/verify-sources.py --archives-only
python3 Benchmarks/transform-elements-evaluation/compare.py
```

The archived `source-verification.json` records the original verification run.
Without `--archives-only`, the verifier also requires the current checkout to
match every recorded final input and rewrites that verification record; use that
mode only in a checkout reconstructed from the measured state. The source-state
restoration recipe above keeps reconstruction separate from active work.

To run the broader correctness coverage on this branch, use the same filter in
Debug and Release:

```sh
qrcode_research_tests='QRCodeTransformedPixelPathTests|QRCodePixelBatchingTests|QRCodeStandaloneBatchingTests|QRCodeNeighborBatchingTests|QRCodePathTests|QRCodeSVGTests|QRCodeMaskingTests|QRCodeTests.testBasicDocumentionationCode|QRCodeDetectionTests.testBasicDetection'
swift test -c debug --filter "$qrcode_research_tests"
swift test -c release --filter "$qrcode_research_tests"
```

Collect fresh performance results only when needed, with a new output filename
and the [same measurement controls](HARNESS.md#comparing-revisions).
