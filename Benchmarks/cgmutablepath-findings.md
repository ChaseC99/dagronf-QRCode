# CGMutablePath performance findings

The [follow-up implementation report](transform-elements-evaluation/README.md)
documents the final element-wise approach and the additional native-path behavior
that prevented using a whole transformed-path copy as a general replacement.

Large QR codes spend much of their generation time repeatedly appending transformed pixel paths. Inspection of CoreGraphics on this Mac identifies a concrete cause: each non-identity transformed append recomputes the bounding box of the entire accumulated path. Transforming each small path before appending it is a promising, simpler replacement for batching.

**The expensive operation is a repeated bounds scan.** Apple documents that [`addPath(_:transform:)`](https://developer.apple.com/documentation/coregraphics/cgmutablepath/addpath%28_%3Atransform%3A%29) transforms the incoming path before appending its elements, without promising a particular complexity. The installed macOS 26.7.1 build 25G241 implementation, reached through `CGPathAddPath` → `CG::Path::append`, takes two routes:

| Append operation | Observed bounds calculation |
| --- | --- |
| Identity transform or no transform | Combine the existing bounds with the incoming path's bounds. |
| Non-identity transform | Transform the newly appended points, reset the cached bounds, and scan every point in the destination. |

The native ARM64 disassembly shows the second route iterating from the start of the destination points buffer using its total point count. This is an observation of this OS implementation; Apple does not guarantee the same internals on every macOS or iOS version.

For N repeated shapes of fixed complexity, the scans visit the equivalent of `1 + 2 + … + N = N(N + 1) / 2` shapes. That produces quadratic total work. More complex templates make each scan more expensive: the [path bounding box](https://developer.apple.com/documentation/coregraphics/cgpath/boundingbox) includes curve control points as well as endpoints.

**The Release measurements match that mechanism.** The medium and large fixtures contain 3,863 and 14,173 active data modules, respectively: 3.67× as many. Quadratic growth predicts approximately 13.46× the work.

| Pixel path construction | Medium median | Large median | Growth |
| --- | ---: | ---: | ---: |
| Square | 46.746 ms | 633.481 ms | 13.55× |
| Gear | 1,389.511 ms | 19,038.339 ms | 13.70× |
| Rounded Rectangle | 2.230 ms | 8.332 ms | 3.74× |

Rounded Rectangle already creates each shape in its final coordinates and appends it with an identity transform. Its approximately linear growth is consistent with avoiding the full destination scan.

These [baseline results](/Users/chase/Documents/Code/iOS/dagronf-QRCode/Benchmarks/baseline-macos-arm64.json) use Release on an Apple M1 Pro with macOS 26.7.1 and Xcode 27.1 / Swift 6.4. Each median has five samples after one warm-up. Encoding is outside timing; pixel-path construction and complete image rendering are measured separately. The [benchmark notes](/Users/chase/Documents/Code/iOS/dagronf-QRCode/Benchmarks/README.md) describe the fixtures and timing boundaries.

**Batching limits the scans; transforming first avoids rescanning earlier modules.** Groups of 64 confine expensive scans to small temporary paths, which are then appended to the final path without a transform. For fixed batch size B, this bounds-scan work is approximately O(NB). There is no special threshold of 64 in the observed CoreGraphics implementation; it is an application choice. The [recorded batching run](/Users/chase/Documents/Code/iOS/dagronf-QRCode/Benchmarks/batched-macos-arm64.json) reduced the large Gear path from 19,038.339 ms to 101.803 ms.

The proposed replacement uses Apple's [`copy(using:)`](https://developer.apple.com/documentation/coregraphics/cgpath/copy%28using%3A%29) to transform one small path, then appends that copy with an identity transform. Bounds work remains local to the incoming shape. Its tradeoff is a temporary path allocation per module.

An exploratory native CoreGraphics comparison used 8,192 repeated closed paths, each with either 4 or 40 cubic segments, and a scale/rotation plus translation per shape. Medians of five alternating runs were:

| Template complexity | Batches of 64 | Transform then append |
| --- | ---: | ---: |
| 4 cubic segments | 9.777 ms | 9.600 ms |
| 40 cubic segments | 55.965 ms | 17.231 ms |

`CGPathEqualToPath` reported equal outputs for both approaches, also checked at 2,048 shapes. These exploratory timings include Python/ctypes overhead. They support testing the replacement, but do not establish its Swift Release or physical-iPhone speedup.

**The technique applies across pixel generators.** Of the 43 registered styles, 23 common-generator styles and 17 other styles use the transformed-append pattern. That includes neighbor-dependent templates, grids, drips, and paths with holes. Rounded Rectangle, Horizontal, and Vertical already append shapes in their final coordinates. One internal helper could serve the 40 candidates while preserving template selection, traversal, transforms, and subpath order.

The recommended next step is the [implementation and validation plan](/Users/chase/Documents/Code/iOS/dagronf-QRCode/Benchmarks/transform-before-append-plan.md): establish equivalence, compare against batching in Release, and adopt the simpler implementation if the results support it.

**Follow-up evaluation:** The proposed helper failed independent native-equivalence checks in both Debug and Release on this Mac. A move-only destination followed by a transformed native rectangle produced different elements and pixels; a mixed multi-subpath source produced different control-point bounds. The provisional common-generator migration was reverted to the preserved batching implementation before expanding to other styles. The [evaluation report](transform-before-append-evaluation/README.md) contains reproducible cases, exact candidate sources, test logs and the fresh batching reference. No library speedup or iOS performance claim is made for this candidate.
