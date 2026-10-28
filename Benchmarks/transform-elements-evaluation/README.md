# Transforming pixel-path elements before accumulation

The replacement expands each incoming template into path elements, then passes its transform to the individual move, line, quadratic and cubic additions. Those operations transform the new coordinates without repeatedly rescanning the accumulated path. This uses no batch path, batch counter, cache, size parameter or temporary transformed-path copy.

The internal `addPixelPath` helper retains native append for an empty destination and an identity transform. The first native append only processes one template and preserves CoreGraphics' initial primitive representation. Other appends use individual elements. All 40 candidate styles have migrated; the three identity-append styles retain their original append expressions. Removing common-generator batching also removes the bookkeeping that previously affected Rounded Rectangle.

## Why the first proposal failed

The [first evaluation](../transform-before-append-evaluation/README.md) found two general-path differences with `copy(using:)` followed by identity append. Extending that candidate to all pixel styles revealed another difference:

1. **Pending moves.** In the installed native append implementation, the original destination point count is captured before appending a primitive. A primitive can replace an existing move point; the subsequent transform loop starts at the old count, so that replacement point can escape transformation. The earlier standalone rectangle reproducer demonstrates an untransformed first move and different pixels. A trailing move after existing geometry also needs native-specific handling.
2. **Control-point bounds.** The identity branch of `CG::Path::append` calls `path_bounding_box()` and combines those tight curve bounds with the destination cache. The non-identity branch instead scans all stored points, including controls. Large incoming paths copied with `memcpy` can therefore produce different public `boundingBox` values, even with identical elements and pixels. Replaying individual elements maintains the bounds as their control points are added.
3. **Primitive expansion order.** CoreGraphics stores native rectangles, rounded rectangles and ellipses in specialized representations. Transforming that representation and then expanding it can produce slightly different curve coordinates from expanding first and transforming those points. The copy-and-append trial failed the existing 1e-10 coordinate tolerance for Rounded Path, Rounded End Indent, Curve Pixel and Razor: [failure counts](copy-append-style-failures.json). All of their raster comparisons still passed. One two-module Rounded Path case differed by approximately 1.33e-10 at a cubic control coordinate. Element-wise transformation passes the unchanged tolerance.

The [append disassembly](coregraphics-append-disassembly.txt) and [primitive disassembly](coregraphics-primitive-disassembly.txt) were read from the installed macOS CoreGraphics image with LLDB, without attaching to a process. In the append function, the identity bounds call is at offset +984 and the non-identity scan at +1048 through +1112. These observations apply to macOS 26.7.1 (25G241), not a promised implementation on other systems. The source implementation uses only public CoreGraphics APIs.

## Deliberately limited contract

This is a pixel-template helper, not a drop-in implementation of every native `addPath` behavior. Templates and the destination must not end in a pending move-only subpath. Open contours ending in a line or curve are valid: Diagonal uses them. Each new template begins its own subpath. A caller extending a completed result should explicitly start a new subpath.

That last distinction is observable in a separate general-path experiment: after many native appends, continuing a previously closed subpath with a line and another close produced a different cached `currentPoint` from element-wise construction, although the elements and pixels matched. The [diagnostic log](general-path-continuation.log) preserves it. The production pixel generators never use that continuation pattern. The scoped name and source comment preserve this restriction rather than claiming arbitrary native-path equivalence.

The test suites check that all generated pixel paths have no consecutive or trailing move-only elements. Their ordered output is also compared with independent native references, so the contract check does not replace geometry verification.

## Correctness evidence

All **40 selected tests passed in Debug and Release** on Apple M1 Pro / MacBookPro18,1, macOS 26.7.1, Xcode 27.1 / Swift 6.4. Logs: [Debug](debug-tests.log), [Release](release-tests.log).

- Common, standalone and neighbor suites cover all 43 styles. They retain sparse/dense matrices, fractional rectangular sizes, settings extremes, stateful generators, repeated renders, all 512 neighborhoods, edge/corner placements, off-cell emissions and Vortex quadrants.
- The common and five standalone styles now also use frozen native accumulation references from `a8b8a51`, independent of the production helper. The one-cell integration raster checks remain. Existing frozen neighbor sources were not changed.
- Every style comparison checks exact element types/order/counts, coordinates within the existing 1e-10 tolerance, exact RGBA output, current point, control-point bounds and tight path bounds.
- Focused helper tests make 465 comparisons: 360 source/destination/transform combinations, 91 repeated-append/new-subpath checks and 14 explicit hole checks. They include open/closed and multi-subpath sources, lines and both curve types, native primitives, both fill rules, stroke rasters, reflections and zero-scale transforms.
- Existing path, SVG, masking, image export and QR detection tests pass.

The production audit found exactly **165 method-name substitutions in 16 generator files** relative to the original native implementation. Every other byte in those files matches `a8b8a51`. Template selection/construction, traversal, transform expressions, resets, winding and `closeSubpath()` calls remain intact. `QRCodeBatchedModulePath` has no remaining production callers and has been removed.

## Performance evidence

The unchanged 25-style Release harness uses the same three fixed payloads, prepared matrices, settings, one warm-up and five measured samples per operation. Each run has 75 cases and 750 measured samples. Pixel path construction and complete image generation are timed separately; encoding, matrix preparation, validation and destruction are outside the timed boundaries specified by the harness.

Final comparisons run serially in one temporary checkout on the same Mac, with batching and element-wise variants alternating. No builds or tests run concurrently with measurements. Each report has raw samples, dependency pins, hardware/toolchain metadata, matrix fingerprints and a reconstructable source-state sidecar. The working source in the main checkout remains the element-wise implementation.

The [full three-way comparison](comparison.md) includes the original native implementation and two alternating runs of each final variant. Large Gear path construction measures 19,074.806 ms originally, 102.829 ms with batching, and 18.186 ms with element-wise accumulation (5.65× faster than batching). Complete Gear image generation improves from 881.308 to 800.960 ms versus batching. No case/operation shows a >5% increase in both paired runs. The report explicitly includes the small Square tradeoff and noisy controls rather than claiming every measurement improves.

The earlier `transform-elements-1` report is exploratory and includes additional checks for degenerate general paths; `transform-elements-2` measures the final code in the main checkout. Neither is substituted for the paired comparison runs. All old reports remain intact.

All five comparison source states were reconstructed and checked against every recorded file hash; the original production files match `a8b8a51`, and the main checkout matched the final measured inputs at verification time. The helper has since been renamed from `addTransformedPixelPath` to `addPixelPath` without changing its behavior. Saved source states retain the measured name; the verification script's exact checkout-hash check will flag this rename. See [verification results](source-verification.json). Rebuild the checks and comparison from the repository root with:

```sh
python3 Benchmarks/transform-elements-evaluation/verify-sources.py
python3 Benchmarks/transform-elements-evaluation/compare.py
```

Physical-iPhone performance has not been measured; no iOS speedup is claimed. No branch or PR has been published.
