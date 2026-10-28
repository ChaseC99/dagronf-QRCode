# Copy-and-append: library output evaluation

The implementation on `pixel-path-performance` uses `copy(using:)` followed by identity `addPath`,
with native transformed append as the nil-copy fallback. This replaces the
per-element switch in `addPixelPath`. Call sites, templates, traversal and the
three existing identity-append styles are unchanged; batching remains removed.

This follow-up evaluates the user's revised acceptance criterion: preserve library
output, rather than require identical CoreGraphics control-point bounds caches.
The previous rejection and element-wise implementation remain available in Git
and the historical benchmark snapshots.

## Does the bounds discrepancy affect this library?

No effect was observed in library rendering or export on the tested macOS version.
The cached `CGPath.boundingBox` **can still differ** for a generated pixel path.
This is an observable compatibility difference for clients inspecting that property,
not a claim of universal CGPath equivalence.

Source audit:

- `Sources/QRCode/private/CGPath+extensions.swift`, `flipped()`, is the only
  production reader of the control-point `boundingBox`. Its callers build the
  Heart, Diagonal, Flame, Koala and Leaf **templates before accumulation**. This
  change does not modify those templates or those calls.
- Logo layout reads `boundingBoxOfPath` on the separate logo/mask path, in
  `QRCode+LogoTemplate.swift`, `QRCode+Drawing.swift` and `QRCode+SVG.swift`.
- Fill styles use the caller-supplied drawing rectangle for gradients/images and
  clip against the pixel geometry. Inner shadows use a fixed mask and the path;
  they do not size themselves using the pixel path's cached control bounds.
- SVG enumerates path elements and formats coordinates to at most three decimal
  places. Image/PNG and PDF export use the drawing pipeline. Views use supplied
  view rectangles or the resulting image, rather than accumulated pixel bounds.
- The library returns CGPaths from public APIs and permits custom generators.
  External consumers can inspect their bounds; equivalence for those observations
  is deliberately not promised by this optimization.

## Independent output checks

`Tests/QRCodeTests/QRCodePixelOutputEquivalenceTests.swift` compares the production
implementation against **frozen native transformed-append generators**, not against
another invocation of the new helper.

All 43 registered styles are tested with four designs:

1. A translucent solid fill.
2. A linear gradient, drop shadow, logo mask, off pixels, pixel backgrounds and quiet zone.
3. A radial gradient, inner shadow and inverted pixels.
4. An image fill, logo mask, quiet zone and eyes/pupils generated with the pixel style.

For each of the 172 combinations, the tests require:

- Exact RGBA equality for images at 197.25 × 153.75 and 512 × 512 requested sizes.
- Exact SVG string equality at dimension 197.
- Exact decoded PNG pixel equality.
- Exact rendered PDF pixel equality at 2× scale. PDF file bytes are not compared,
  because serialization metadata and internal encodings are not the rendering contract.
- Equivalent tight bounds for public paths with all/on/off/negative components,
  with both zero and fractional additional quiet space.

In these fixtures, Heart, Koala and Razor generated control bounds differing by
more than 1e-9; none of the composed public paths differed at that threshold.
That last result is fixture-specific: the source audit and rendering tests, not
coincidental equality after composition, justify the change.

A separate synthetic multi-contour curve fixture **exposes different control
bounds on this Mac**, while tight bounds and SVG path text agree. It records
whether that discrepancy occurs, so other CoreGraphics versions need not
reproduce the same cache behavior to pass. It then requires
identical raster bytes for all four fill types with no shadow, a drop shadow and
an inner shadow (12 comparisons). Thus the output tests exercise the known
bounds discrepancy even if particular built-in templates do not expose it.

The existing suites retain all 43 styles, sparse/dense and fractional rectangular
matrices, setting extremes, stateful/repeated rendering, 512 neighborhoods,
edges/corners, off-cell emissions, Vortex quadrants, holes and both fill rules.
The focused helper suite retains 465 comparisons of structure/order, coordinates,
current point, tight bounds and exact fill/even-odd/stroke pixels.

## Intentional test-contract changes

The unchanged strict tests first produced 2,907 assertions:

- 2,074 control-bounds assertions (including 50 in the generic helper suite).
- 833 coordinate assertions: Rounded Path 412, Rounded End Indent 412,
  Curve Pixel 8 and Razor 1.
- **Zero other assertions**: no raster, tight-bounds, current-point or structural failures.

See [raw diagnostic](strict-diagnostic.log) and [classified counts](strict-diagnostic-summary.json).
These tests were run against the simple helper before relaxing any checks.

The accepted tests now compare tight geometric bounds instead of requiring the
control-bounds cache to match. Only the four affected neighbor styles use a
coordinate tolerance of 1e-9 instead of 1e-10, accommodating the previously measured
approximately 1.33e-10 primitive-expansion difference. All other coordinate
checks keep 1e-10. Element counts, types and order remain exact; raster comparisons
remain byte-exact. The native references are unchanged.

The helper remains internal and limited to pixel accumulation. Templates start
new subpaths and leave no pending move-only subpath. The historical pending-move
native discrepancy is outside that contract; this is not a general replacement
for every `CGMutablePath.addPath` use.

## Validation and performance

All **46 selected tests pass in Debug and Release**. See [Debug tests](debug-tests.log), [Release tests](release-tests.log), and the
[Release comparison](comparison.md). The performance harness is unchanged: 25
styles, three prepared fixtures, one warm-up and five measured samples for each
path/image operation. Fresh runs alternate elements/copy/elements/copy in one
checkout, serially, with source snapshots retained alongside the raw samples.
Original native and batching reports remain intact.

Pooled large path medians (elements → copy, milliseconds): Square 4.518 → 3.102,
Grid 4×4 19.070 → 11.758, Flower 9.174 → 11.333, Gear 18.120 → 19.515.
Flower and Gear show repeatable path-only overhead from copying, while their large
complete-image changes are about +1.9% and +1.4%. The retained batching path
medians for those two are 50.219 and 102.829 ms, respectively. Small Flower image
time rose 0.195 ms in the pooled samples (+6.1%), but did not exceed 5% in both
adjacent pairs. No changed style had an image slowdown above 5% in both pairs;
the unchanged Vertical control did, demonstrating rendering noise. The simple
helper is chosen for equivalent output and less code, not a universal speedup
versus element-wise construction.

All four benchmark states reconstruct successfully (314 file hashes each), and
only the helper differs between timed variants. The final synthetic-test portability
change replaces a requirement for an OS-specific cache discrepancy with a diagnostic;
it does not change production code, the benchmark harness, settings or fixtures. Its focused Debug and
Release reruns are in [portability-tests.log](portability-tests.log). The exact final
validation source is also [retained](validation.source-state.json).

Reproduce the reports/verification from the repository root:

```sh
python3 Benchmarks/copy-append-library-evaluation/compare.py
python3 Benchmarks/copy-append-library-evaluation/verify-sources.py
```


Hardware: Apple M1 Pro, MacBookPro18,1, 32 GiB RAM, arm64. Software: macOS 26.7.1,
Xcode 27.1, Swift 6.4. These results describe the installed macOS CoreGraphics
implementation. No physical-iPhone measurements or iOS performance claim.

## Expanded coverage and publication

The [main report](../README.md) uses new matched original/copy measurements for
all 43 styles. The 25-style experiment here remains evidence for the copying
tradeoff against element-wise appends. The previous implementation and snapshot
base revision `ce204d0` are retained on
[codex/pixel-path-elements](https://github.com/ChaseC99/dagronf-QRCode/tree/codex/pixel-path-elements).
The verifier defaults to archived inputs; use `--check-current` only in a checkout
reconstructed from `validation.source-state.json`, before the harness expansion.
