# Transform-before-append evaluation

**Later follow-up:** The [library-output evaluation](../copy-append-library-evaluation/README.md)
revisits this rejection under an output-equivalence requirement and adopts the
simple copy-and-append helper for the scoped pixel pipeline. The strict native
bounds/element differences documented below are retained, not erased.

**Historical rejected candidate.** Statements below about restored batching refer
to the end of this evaluation. The subsequent proposal used element-wise accumulation;
see the [research overview](../README.md) for the branch layout and final decision.

**Follow-up:** The [element-wise implementation](../transform-elements-evaluation/README.md)
addresses pixel accumulation with a scoped helper. The rejected whole-path-copy
candidate and its general-path failure evidence below remain unchanged.

**The proposed helper did not pass the independent native-equivalence gate, so it was not adopted.** The 23 common transformed append sites were migrated provisionally and tested. The incoming batching implementation was then restored exactly. The other 17 candidate styles were not migrated, and `QRCodeBatchedModulePath` remains in production.

Evaluated October 27, 2026 (America/Los_Angeles), on an Apple M1 Pro / MacBookPro18,1, macOS 26.7.1 (25G241), Xcode 27.1 (27A9275), Swift 6.4 (swiftlang-6.4.0.34.1). These findings describe this installed CoreGraphics implementation, not a guarantee about other operating systems.

## Independent correctness results

The [candidate helper](CGMutablePath+TransformedPath.swift) is the requested `copy(using:)` followed by identity `addPath`, with native transformed append as the nil-copy fallback. The [focused XCTest suite](QRCodeTransformedPathTests.swift) calls native `addPath(_:transform:)` directly for its expected results. Actual and expected paths begin as separate mutable copies of the same destination.

The suite checks 495 combinations of five destinations, eleven sources and nine transforms, 100 successive-append/continuation comparisons, and fourteen explicit hole comparisons. It includes empty and move-only paths; open and closed lines; quadratic and cubic curves; multiple subpaths; native rectangles and ellipses; same/opposite winding; identity, translation, nonuniform scale, rotation, reflection, shear, combined transforms, total zero scale and single-axis zero scale. It compares ordered elements, current point, both bounds properties, and exact RGBA output with nonzero fill, even-odd fill and stroke. Element coordinates and bounds use the existing 1e-10 tolerance.

Both Debug and Release produced **178 failed assertions in `testNativeAppendEquivalence`**. The hole and repeated-append tests passed. All three existing common-style tests also passed (576 integration comparisons across 24 common types). This is a failure of the requested general helper equivalence; it is not evidence that the normal common pixel loops produced incorrect images.

Two standalone cases establish the differences without QRCode or XCTest:

| Case | Native transformed append | Copy, then identity append |
| --- | --- | --- |
| Move-only destination, rectangle translated by (7.25, -3.5) | First move remains (1.25, 2.5) | First move becomes (8.5, -1.0) |
| Closed destination, mixed multi-subpath source with the same translation: `boundingBox` | (-0.75, -10.5, 40, 38) | (1.25, -2.5, 29.618950038622252, 22) |

The first case has different ordered geometry, bounds, and raster output: 400 differing RGBA bytes for each fill rule and 435 for stroke in the standalone fixture. The native operation's untransformed first move is surprising, but matching that operation was the independent reference requirement. The second case has equal ordered elements, current point, tight `boundingBoxOfPath`, and pixels, while the public control-point `boundingBox` differs materially. Neither difference can be covered by the existing coordinate tolerance.

The standalone probe emits identical results in Debug and Release. The optional copy-failure fallback is present but was not forced; no natural nil result occurred in these fixtures.

## Reproduce and inspect

From the repository root:

```sh
swiftc -Onone Benchmarks/transform-before-append-evaluation/native-equivalence-probe.swift -o /tmp/qrcode-equivalence-debug
/tmp/qrcode-equivalence-debug
swiftc -O Benchmarks/transform-before-append-evaluation/native-equivalence-probe.swift -o /tmp/qrcode-equivalence-release
/tmp/qrcode-equivalence-release
```

The probe exits with status **1 when equivalence fails**, intentionally. Its [source](native-equivalence-probe.swift), [Debug output](native-equivalence-debug.log), and [Release output](native-equivalence-release.log) are retained. It uses only public CoreGraphics APIs.

The complete provisional common-generator candidate, helper, test files, and existing harness can be reconstructed from [common-candidate.source-state.json](common-candidate.source-state.json), using the [existing source-state restoration recipe](../history.md#exact-source-states-and-reproduction). It is based on commit `a8b8a51`; restoration was checked against **all 308 recorded file hashes**. The resolved dependency pins are in the fresh batching report's `metadata.packageResolved`.

After restoring that snapshot in a separate checkout, run:

```sh
swift test --filter 'QRCodeTransformedPathTests|QRCodePixelBatchingTests'
swift test -c release --filter 'QRCodeTransformedPathTests|QRCodePixelBatchingTests'
```

The [initial Debug log](common-debug.log), [Debug log with bounds labels](helper-debug.log), and [Release log](common-release.log) preserve the failures. The candidate sources and tests in this report directory are review artifacts, outside the active SwiftPM source/test targets; no failing candidate tests were left in the normal test run.

## Preserved references and performance scope

All earlier baseline and batching reports remain unchanged. The [incoming source state](../transform-batching-reference.source-state.json) preserves the exact batching implementation at the start of this evaluation.

A [fresh Release batching report](../transform-batching-1-macos-arm64.json) and its [reconstructable source state](../transform-batching-1-macos-arm64.json.source-state.json) retain the existing, unchanged 25-style harness: three fixtures, one warm-up per operation and five measured samples, 75 cases and 750 measured samples. The run took approximately 40 seconds, excluding build time. Encoding and matrix preparation were outside timing; pixel-generator path construction and complete `QRCode.cgImage` rendering were timed separately. No other builds or tests were launched during its timed interval. Raw timings, payloads, matrix fingerprints, settings, dependencies, hardware and toolchain metadata are in the report.

The initial sandboxed launch failed before executing measurements; its [incomplete source state](../transform-batching-incomplete-sandbox.source-state.json) is not a benchmark result. The completed run used normal compiler-cache and hardware-metadata access.

The source audit also found that the incoming common generator batches Rounded Rectangle, despite the older benchmark notes describing it as excluded. Its identity append was left unchanged in the provisional candidate; removing common batching bookkeeping would also remove that batching. Horizontal and Vertical were unchanged throughout. Future comparisons should use the recorded sources rather than infer their exact implementation from older prose.

There is **no candidate speedup or no-regression claim** from this evaluation. Fresh original/candidate timing, alternating batching/candidate runs and the physical-iPhone spot check were not performed after correctness failed. A physical iPhone was detected, but no iOS performance conclusion is drawn.

## Restored implementation and next decision

After saving the candidate, all **306 incoming source, test, resource and script file hashes** were checked against the restored working tree. All 17 production files with incoming batching changes were byte-identical to their preserved versions. The Git index and frozen neighbor references were left unchanged.

The existing common, standalone and neighbor suites cover all 43 styles, including the full neighborhood enumeration, off-cell emissions and Vortex quadrants. On the restored implementation, the 35 selected tests passed in Debug and Release, including path, SVG, masking, image export and QR decoding checks. Logs: [Debug](restored-debug.log), [Release](restored-release.log).

Adoption remains incomplete. The next design must either preserve the demonstrated native edge cases and bounds behavior or explicitly establish a narrower helper contract that excludes them. Only then should the remaining migration and three-way performance comparison proceed. No branch was published and no maintainer PR was created.
