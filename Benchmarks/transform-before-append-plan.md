# Plan for transforming pixel paths before appending

Replace repeated transformed appends with a small internal helper that transforms each incoming path first, then appends it using an identity transform. This addresses the [observed CoreGraphics bounds-scan behavior](/Users/chase/Documents/Code/iOS/dagronf-QRCode/Benchmarks/cgmutablepath-findings.md) and removes batching state. Adoption depends on correctness checks and a Release comparison against both the original implementation and batching.

1. **Preserve comparable references.** Retain the existing baseline reports and record the exact current production source state. Use the same benchmark harness and settings for all implementations being compared; if coverage expands, run that expanded harness against each implementation. Keep the original native transformed-append operation available in test code as an independent reference.

2. **Add one internal helper.** A dedicated source file can contain this implementation and a short comment explaining why the transform is applied before the append:

```swift
import CoreGraphics

internal extension CGMutablePath {
    func addTransformedPath(
        _ path: CGPath,
        transform: CGAffineTransform
    ) {
        var transform = transform
        guard let transformed = path.copy(using: &transform) else {
            // Preserve existing behavior if copying fails.
            addPath(path, transform: transform)
            return
        }

        addPath(transformed)
    }
}
```

The fallback preserves rendering behavior if the optional copy cannot be created. The helper adds no public API, dependency, cache, or tunable batch size.

3. **Replace affected accumulation calls.** Start with `CommonPixelGenerator`, validate it, then apply the same change to the 17 other candidate styles. The basic substitution is mechanical:

```diff
- path.addPath(template, transform: transform)
+ path.addTransformedPath(template, transform: transform)
```

Remove the temporary batch path, counters, flush operations, and final batch merge. Generators should append directly into one result path. Remove `QRCodeBatchedModulePath` only after all its production callers have migrated.

Keep existing transform expressions, template selection, traversal order, generator resets, winding, and `closeSubpath()` calls. Leave the existing identity appends in Rounded Rectangle, Horizontal, and Vertical intact. Confine substitutions to pixel-generation accumulation loops; one-off template construction and unrelated eye or pupil rendering are outside this change. The algorithm becomes simpler, although covering all 40 candidates will touch multiple files.

4. **Verify geometry independently.** Add focused helper tests comparing the new operation with native `addPath(_:transform:)` on the same starting destination. Cover empty and populated destinations; empty, open, closed, and multi-subpath sources; lines, quadratic and cubic curves; identity, translation, scale, rotation, reflection, and zero-scale transforms. Compare path elements, current point, bounds, and raster output, including hole behavior under both fill rules.

Reuse the existing common, standalone, and neighbor correctness suites to cover all 43 styles. Include sparse and dense matrices, fractional rectangular sizes, inset and rotation extremes, stateful generators, repeated renders, and neighbor patterns at edges and corners. Preserve coverage for shapes emitted around off cells and Vortex's quadrant behavior.

The current common and standalone test references reuse the production generator one cell at a time. They remain useful integration checks, but the independent helper comparison is essential because changing the helper would otherwise affect both actual and expected paths. Keep the frozen neighbor references on their original append implementation. Retain exact element ordering and raster comparisons, with the existing documented coordinate tolerance where needed. Run these suites in Debug and Release, plus the relevant path, SVG, masking, export, and decoding tests.

5. **Measure the actual library.** Use the existing Release harness with one warm-up and five measured samples, fixed payloads, prepared matrices, and separate path and complete-image timings. Include simple and complex common styles, grids, Donut, and representative neighbor-dependent styles; retain the three unaffected styles as controls. Expand the harness consistently across comparison runs if necessary.

Compare original accumulation, batching, and the candidate on the same quiet machine, OS, toolchain, dependencies, and harness. Retain raw samples and reconstructable source states; alternate batching and candidate runs to assess noise. Check small cases for allocation overhead, large cases for scaling, and complete-image time for the user-visible effect. Run a Release spot check on a physical iPhone before making iOS performance claims. Resolve repeatable regressions before broadening the replacement.

6. **Prepare the maintainer change.** Include the helper, mechanical call-site updates, batching removal, and focused correctness coverage. Present measured Release results with the hardware, OS, sample count, and timing boundaries. Keep the benchmark harness and full reports available separately for review, with a verified branch link when one exists. Avoid unrelated refactoring or claims that this CoreGraphics behavior is guaranteed across operating systems.

Completion means equivalent output across the supported styles and settings, no material repeatable regression against batching in the measured workloads, and retained performance evidence supporting the simpler implementation.
