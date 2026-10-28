# QRCode rendering performance: all 43 styles

The `addPixelPath` helper transforms a copy of each incoming pixel template, then
appends it with an identity transform. This avoids repeated scans of the growing
destination observed in native transformed appends on this Mac, without batching
or a per-element command switch.

**Large Gear complete-image generation: 19.83 seconds → 796.30 ms
(24.9× faster).** Its pixel-path construction falls from 19,030.615 ms to
19.655 ms (968.2× faster).

The tables below include **every registered style: 43 styles × three fixtures ×
two operations**, measured with the same expanded Release harness. These are new
43-style original/copy runs; no missing styles were filled in from the older
25-style reports. All medians are milliseconds. Speedup = original median ÷ copy
median; values below 1 are slower. † marks the three unchanged identity-append
styles used as controls.

The output investigation found exact image, SVG, PNG-pixel and rendered-PDF
agreement across all 43 styles and four designs; 46 selected tests passed in Debug
and Release. Cached control-point bounds and tiny coordinate rounding can still
differ. See [correctness and compatibility](copy-append-library-evaluation/README.md).

## Large QR codes — all 43 styles

1,123-byte vCard · high error correction ·
14,173 active data modules · 716 × 716 image.

| Style | Original path (ms) | Copy path (ms) | Path speedup | Original image (ms) | Copy image (ms) | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Abstract | 1,566.014 | 6.283 | 249.26× | 1,595.679 | 59.536 | 26.80× |
| Arrow | 1,022.563 | 3.664 | 279.06× | 1,034.612 | 12.784 | 80.93× |
| Blob | 4,579.591 | 9.433 | 485.51× | 4,630.177 | 65.875 | 70.29× |
| Circle | 1,810.246 | 3.534 | 512.31× | 1,857.610 | 58.357 | 31.83× |
| Circuit | 5,689.510 | 9.341 | 609.10× | 5,969.353 | 227.629 | 26.22× |
| Crosshatch | 5,287.628 | 8.774 | 602.64× | 5,589.186 | 314.479 | 17.77× |
| CRT | 3,327.121 | 5.986 | 555.83× | 3,670.512 | 296.219 | 12.39× |
| Curve pixel | 1,109.673 | 5.159 | 215.10× | 1,143.800 | 27.907 | 40.99× |
| Diagonal | 896.025 | 3.335 | 268.67× | 913.483 | 8.348 | 109.42× |
| DiagonalStripes | 12,215.538 | 12.246 | 997.50× | 12,991.664 | 732.114 | 17.75× |
| Diamond | 763.190 | 3.257 | 234.32× | 777.318 | 14.875 | 52.26× |
| Donut | 4,343.462 | 5.905 | 735.61× | 4,791.178 | 369.324 | 12.97× |
| Drip Horizontal | 3,774.646 | 6.454 | 584.87× | 3,908.270 | 127.088 | 30.75× |
| Drip Vertical | 3,670.360 | 6.513 | 563.59× | 3,725.193 | 115.660 | 32.21× |
| Flame | 2,306.856 | 4.922 | 468.67× | 2,363.141 | 48.283 | 48.94× |
| Flower | 9,007.167 | 10.914 | 825.28× | 9,565.552 | 446.557 | 21.42× |
| Gear | 19,030.615 | 19.655 | 968.21× | 19,832.167 | 796.300 | 24.91× |
| 2x2 Square Grid | 3,061.363 | 4.423 | 692.11× | 3,089.691 | 15.404 | 200.58× |
| 3x3 Square Grid | 6,950.979 | 7.640 | 909.87× | 7,081.471 | 53.406 | 132.60× |
| 4x4 Square Grid | 12,424.679 | 11.522 | 1,078.33× | 12,603.393 | 134.514 | 93.70× |
| Heart | 2,449.881 | 5.152 | 475.49× | 2,532.382 | 120.197 | 21.07× |
| Hexa | 1,016.194 | 3.726 | 272.76× | 1,028.693 | 9.323 | 110.34× |
| Hexagon | 1,314.921 | 3.984 | 330.08× | 1,309.138 | 19.442 | 67.34× |
| Horizontal bars† | 4.066 | 4.210 | 0.97× | 21.006 | 22.869 | 0.92× |
| Koala | 1,404.059 | 4.334 | 323.96× | 1,520.929 | 122.924 | 12.37× |
| Leaf | 2,055.181 | 4.651 | 441.88× | 2,156.359 | 57.329 | 37.61× |
| Pointy | 672.186 | 2.694 | 249.51× | 673.850 | 6.130 | 109.93× |
| Razor | 2,757.525 | 6.326 | 435.92× | 2,801.175 | 50.713 | 55.24× |
| Rounded end indent | 1,103.874 | 5.625 | 196.26× | 1,130.539 | 28.150 | 40.16× |
| Rounded path | 2,397.915 | 9.571 | 250.55× | 2,438.798 | 40.101 | 60.82× |
| Rounded rectangle† | 7.849 | 7.862 | 1.00× | 87.105 | 88.624 | 0.98× |
| RoundedTriangle | 5,640.159 | 7.687 | 733.77× | 5,818.207 | 90.596 | 64.22× |
| Sharp | 3,426.712 | 5.929 | 577.98× | 3,635.462 | 318.748 | 11.41× |
| Shiny | 2,834.691 | 5.815 | 487.49× | 3,156.440 | 313.523 | 10.07× |
| Spiky Circle | 8,060.643 | 10.888 | 740.34× | 9,489.971 | 1,520.924 | 6.24× |
| Square | 633.839 | 3.083 | 205.60× | 650.099 | 5.564 | 116.85× |
| Squircle | 3,348.716 | 5.475 | 611.66× | 3,622.830 | 296.501 | 12.22× |
| Star | 1,412.942 | 3.959 | 356.90× | 1,445.225 | 25.709 | 56.21× |
| Stitch | 5,254.830 | 7.678 | 684.36× | 5,914.282 | 783.935 | 7.54× |
| Vertical bars† | 4.258 | 4.433 | 0.96× | 48.416 | 67.925 | 0.71× |
| Vortex | 1,457.166 | 6.853 | 212.64× | 1,485.390 | 52.729 | 28.17× |
| Wave | 3,644.964 | 6.306 | 578.06× | 4,015.822 | 417.362 | 9.62× |
| Wex | 1,787.837 | 4.186 | 427.05× | 1,842.732 | 36.704 | 50.21× |

## Medium QR codes — all 43 styles

298-byte vCard · high error correction ·
3,863 active data modules · 693 × 693 image.

| Style | Original path (ms) | Copy path (ms) | Path speedup | Original image (ms) | Copy image (ms) | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Abstract | 116.650 | 1.720 | 67.81× | 126.269 | 13.033 | 9.69× |
| Arrow | 78.454 | 1.007 | 77.93× | 82.524 | 3.099 | 26.63× |
| Blob | 347.112 | 2.620 | 132.51× | 363.947 | 17.674 | 20.59× |
| Circle | 134.667 | 0.950 | 141.70× | 155.729 | 22.452 | 6.94× |
| Circuit | 409.569 | 2.619 | 156.36× | 452.237 | 46.142 | 9.80× |
| Crosshatch | 391.475 | 2.382 | 164.35× | 440.283 | 53.462 | 8.24× |
| CRT | 248.612 | 1.664 | 149.38× | 305.808 | 59.794 | 5.11× |
| Curve pixel | 85.049 | 1.422 | 59.79× | 91.569 | 8.085 | 11.33× |
| Diagonal | 68.160 | 0.910 | 74.86× | 70.893 | 2.629 | 26.96× |
| DiagonalStripes | 890.025 | 3.321 | 267.97× | 982.912 | 86.096 | 11.42× |
| Diamond | 57.710 | 0.870 | 66.36× | 59.801 | 2.961 | 20.20× |
| Donut | 321.746 | 1.595 | 201.70× | 382.930 | 51.327 | 7.46× |
| Drip Horizontal | 273.527 | 1.758 | 155.58× | 302.956 | 30.958 | 9.79× |
| Drip Vertical | 267.601 | 1.779 | 150.43× | 293.303 | 29.688 | 9.88× |
| Flame | 173.425 | 1.378 | 125.87× | 191.238 | 18.413 | 10.39× |
| Flower | 655.547 | 3.068 | 213.65× | 762.007 | 107.586 | 7.08× |
| Gear | 1,394.574 | 5.449 | 255.96× | 1,530.584 | 122.742 | 12.47× |
| 2x2 Square Grid | 226.552 | 1.134 | 199.73× | 230.648 | 4.455 | 51.78× |
| 3x3 Square Grid | 512.869 | 2.082 | 246.28× | 521.960 | 11.837 | 44.09× |
| 4x4 Square Grid | 911.739 | 3.127 | 291.56× | 931.220 | 17.579 | 52.97× |
| Heart | 184.505 | 1.397 | 132.06× | 197.047 | 15.865 | 12.42× |
| Hexa | 77.068 | 0.995 | 77.42× | 79.829 | 2.701 | 29.56× |
| Hexagon | 98.486 | 1.030 | 95.62× | 100.237 | 3.378 | 29.67× |
| Horizontal bars† | 1.123 | 1.200 | 0.94× | 8.939 | 8.488 | 1.05× |
| Koala | 105.910 | 1.194 | 88.67× | 120.229 | 16.428 | 7.32× |
| Leaf | 154.015 | 1.267 | 121.55× | 169.440 | 15.714 | 10.78× |
| Pointy | 50.701 | 0.730 | 69.50× | 52.157 | 2.183 | 23.89× |
| Razor | 211.805 | 1.832 | 115.62× | 227.425 | 14.900 | 15.26× |
| Rounded end indent | 83.899 | 1.588 | 52.85× | 91.872 | 8.861 | 10.37× |
| Rounded path | 191.069 | 2.649 | 72.12× | 201.784 | 11.963 | 16.87× |
| Rounded rectangle† | 2.514 | 2.299 | 1.09× | 12.829 | 11.551 | 1.11× |
| RoundedTriangle | 417.713 | 2.107 | 198.21× | 425.185 | 12.867 | 33.04× |
| Sharp | 249.624 | 1.697 | 147.11× | 314.022 | 69.249 | 4.53× |
| Shiny | 211.141 | 1.572 | 134.35× | 270.824 | 58.182 | 4.65× |
| Spiky Circle | 586.694 | 2.993 | 196.05× | 704.478 | 116.622 | 6.04× |
| Square | 49.088 | 0.832 | 59.02× | 49.975 | 1.831 | 27.29× |
| Squircle | 247.335 | 1.469 | 168.38× | 268.776 | 24.182 | 11.11× |
| Star | 105.909 | 1.068 | 99.21× | 109.532 | 4.903 | 22.34× |
| Stitch | 382.069 | 2.075 | 184.16× | 541.876 | 159.864 | 3.39× |
| Vertical bars† | 1.218 | 1.199 | 1.02× | 14.970 | 14.468 | 1.03× |
| Vortex | 112.458 | 1.912 | 58.81× | 124.442 | 11.507 | 10.81× |
| Wave | 265.222 | 1.728 | 153.46× | 294.435 | 31.464 | 9.36× |
| Wex | 134.113 | 1.154 | 116.24× | 137.365 | 5.656 | 24.29× |

## Small QR codes — all 43 styles

20-byte URL · high error correction ·
303 active data modules · 702 × 702 image.

| Style | Original path (ms) | Copy path (ms) | Path speedup | Original image (ms) | Copy image (ms) | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Abstract | 0.773 | 0.148 | 5.21× | 2.182 | 1.594 | 1.37× |
| Arrow | 0.501 | 0.084 | 5.99× | 1.053 | 0.590 | 1.78× |
| Blob | 2.336 | 0.245 | 9.53× | 3.880 | 1.797 | 2.16× |
| Circle | 0.851 | 0.084 | 10.08× | 1.711 | 1.065 | 1.61× |
| Circuit | 2.349 | 0.217 | 10.80× | 4.762 | 2.715 | 1.75× |
| Crosshatch | 2.542 | 0.200 | 12.70× | 7.304 | 3.524 | 2.07× |
| CRT | 1.622 | 0.132 | 12.30× | 3.579 | 2.056 | 1.74× |
| Curve pixel | 0.659 | 0.126 | 5.24× | 1.728 | 1.188 | 1.46× |
| Diagonal | 0.446 | 0.075 | 5.94× | 0.917 | 0.583 | 1.57× |
| DiagonalStripes | 5.664 | 0.274 | 20.68× | 9.026 | 3.741 | 2.41× |
| Diamond | 0.399 | 0.075 | 5.32× | 0.885 | 0.591 | 1.50× |
| Donut | 2.094 | 0.129 | 16.25× | 4.087 | 2.020 | 2.02× |
| Drip Horizontal | 1.640 | 0.135 | 12.14× | 3.430 | 1.847 | 1.86× |
| Drip Vertical | 1.683 | 0.139 | 12.07× | 3.295 | 1.766 | 1.87× |
| Flame | 1.144 | 0.106 | 10.80× | 2.060 | 0.905 | 2.28× |
| Flower | 4.218 | 0.240 | 17.60× | 7.535 | 3.285 | 2.29× |
| Gear | 8.796 | 0.439 | 20.05× | 11.738 | 3.329 | 3.53× |
| 2x2 Square Grid | 1.399 | 0.095 | 14.74× | 2.011 | 0.633 | 3.18× |
| 3x3 Square Grid | 3.191 | 0.165 | 19.31× | 4.023 | 1.119 | 3.59× |
| 4x4 Square Grid | 5.737 | 0.256 | 22.39× | 7.118 | 1.417 | 5.02× |
| Heart | 1.155 | 0.117 | 9.86× | 2.322 | 1.349 | 1.72× |
| Hexa | 0.490 | 0.082 | 6.00× | 0.998 | 0.544 | 1.84× |
| Hexagon | 0.604 | 0.087 | 6.93× | 1.119 | 0.579 | 1.93× |
| Horizontal bars† | 0.104 | 0.110 | 0.94× | 0.766 | 0.816 | 0.94× |
| Koala | 0.670 | 0.100 | 6.73× | 1.884 | 1.441 | 1.31× |
| Leaf | 1.006 | 0.103 | 9.72× | 2.129 | 1.094 | 1.95× |
| Pointy | 0.342 | 0.065 | 5.26× | 0.819 | 0.536 | 1.53× |
| Razor | 1.394 | 0.163 | 8.53× | 2.933 | 1.694 | 1.73× |
| Rounded end indent | 0.690 | 0.151 | 4.57× | 1.719 | 1.185 | 1.45× |
| Rounded path | 1.284 | 0.242 | 5.31× | 2.567 | 1.457 | 1.76× |
| Rounded rectangle† | 0.179 | 0.182 | 0.98× | 1.216 | 1.168 | 1.04× |
| RoundedTriangle | 2.669 | 0.171 | 15.64× | 3.746 | 1.138 | 3.29× |
| Sharp | 1.552 | 0.136 | 11.45× | 4.581 | 3.014 | 1.52× |
| Shiny | 1.366 | 0.135 | 10.14× | 4.571 | 3.357 | 1.36× |
| Spiky Circle | 3.760 | 0.245 | 15.33× | 9.280 | 5.805 | 1.60× |
| Square | 0.331 | 0.071 | 4.67× | 0.703 | 0.415 | 1.69× |
| Squircle | 1.529 | 0.117 | 13.05× | 3.489 | 1.973 | 1.77× |
| Star | 0.670 | 0.088 | 7.59× | 1.300 | 0.661 | 1.96× |
| Stitch | 2.390 | 0.163 | 14.64× | 5.943 | 3.573 | 1.66× |
| Vertical bars† | 0.107 | 0.106 | 1.01× | 0.945 | 0.951 | 0.99× |
| Vortex | 0.773 | 0.158 | 4.90× | 1.629 | 0.969 | 1.68× |
| Wave | 1.644 | 0.135 | 12.21× | 4.033 | 2.270 | 1.78× |
| Wex | 0.834 | 0.096 | 8.71× | 1.407 | 0.692 | 2.03× |

## Methodology

| Setting | Value |
| --- | --- |
| Hardware | Apple M1 Pro, MacBookPro18,1; 10 cores; 32 GiB RAM; arm64 |
| Software | macOS 26.7.1 (25G241), Xcode 27.1 (27A9275), Swift 6.4 |
| Build | Release |
| Coverage | All 43 registered default pixel styles; three fixed payloads; path and image separately |
| Sampling | One warm-up, then five measured samples per operation/case/run |
| Run order | Copy 1 → original → copy 2, serially in one temporary checkout |
| Aggregation | Median of five original samples versus ten pooled copy samples |
| Clock | DispatchTime.uptimeNanoseconds |

All runs use the same harness hash, style settings, payloads, prepared matrix
fingerprints, dependencies, hardware, OS and toolchain. The Core Image encoder uses
high error correction; rendering uses black foreground, white background, square
eyes, no logo and four additional quiet-zone modules. A target dimension of 720
is rounded down to whole pixels per module, producing the image sizes above.
No agent builds or tests run concurrently with timed measurements.

- **Path** times only pixel-generator construction on a prepared, eye-masked matrix.
- **Image** times `QRCode.cgImage`, including context allocation, masking, all paths,
  drawing and `makeImage`.
- QR encoding, fixture/design preparation, validation, destruction, PNG conversion
  and scanning are outside the timing boundaries.

Path and image are measured independently; their medians are not additive. A
separate path median can exceed an image median because of measurement variation.
Every raw sample is retained without outlier removal. The original has one run,
so its between-run variability is not established; these are descriptive timings,
not statistical significance claims.

The unchanged large Vertical control measures 48.416 → 67.925 ms
(+40.3%) for complete images. Its generator is unchanged. This substantial
control variation limits attributing modest render-time differences to the helper;
the slower values remain in the tables and raw samples.

The earlier alternating element-wise/copy comparison found path-only copying
costs for Flower and Gear alongside gains for Square and grids. Those
[tradeoffs](copy-append-library-evaluation/comparison.md) remain documented; the
simpler implementation is not claimed to beat element-wise construction in every
workload. That older experiment has 25 styles and is separate from this table.

No physical-iPhone performance, other OS versions, allocation/memory use or power
consumption has been measured. The CoreGraphics behavior is an observation of the
installed implementation, not a cross-platform complexity guarantee.

## Raw samples and source states

| Run | Started (Los Angeles) | Test duration | Samples | Reconstructable source |
| --- | --- | ---: | --- | --- |
| copy-1 | 2026-10-28 05:14:18 PDT | 61 s | [JSON](all-styles-copy-evaluation/copy-1.json) | [Snapshot](all-styles-copy-evaluation/copy-1.json.source-state.json) |
| original | 2026-10-28 05:15:57 PDT | 2,070 s | [JSON](all-styles-copy-evaluation/original.json) | [Snapshot](all-styles-copy-evaluation/original.json.source-state.json) |
| copy-2 | 2026-10-28 05:51:10 PDT | 61 s | [JSON](all-styles-copy-evaluation/copy-2.json) | [Snapshot](all-styles-copy-evaluation/copy-2.json.source-state.json) |

Durations exclude build time and include fixture setup and warm-ups. Each report
contains 129 cases, with five path samples and five image samples per case,
including medians, minima, maxima and standard deviations. Source snapshots record
the exact measured files, not merely the branch name after publication.

Regenerate this README and verify the retained source states:

```sh
python3 Benchmarks/all-styles-copy-evaluation/render-readme.py
python3 Benchmarks/all-styles-copy-evaluation/verify-sources.py
```

Use the [harness guide](HARNESS.md) for fresh measurements, always with a new output
filename. The older [element-wise comparison](transform-elements-evaluation/comparison.md)
is retained unchanged as historical evidence and does not describe the current helper.

## Branches and implementation

| Branch | Contents |
| --- | --- |
| [pixel-path-performance](https://github.com/ChaseC99/dagronf-QRCode/tree/pixel-path-performance) | One commit above main: copy-and-append helper, mechanical accumulation updates and focused correctness tests |
| [render-benchmarks](https://github.com/ChaseC99/dagronf-QRCode/tree/render-benchmarks) | Performance branch plus a separate opt-in, all-43-style benchmark commit |
| [pixel-path-research](https://github.com/ChaseC99/dagronf-QRCode/tree/pixel-path-research) | Benchmarks plus full output/native-reference tests, investigations, reports and source snapshots |
| [codex/pixel-path-elements](https://github.com/ChaseC99/dagronf-QRCode/tree/codex/pixel-path-elements) | Preserved previous element-wise implementation, its benchmark harness and all prior research at ce204d0 |

The benchmark-only commit can be cherry-picked onto another implementation for a
matched comparison. [CoreGraphics findings](cgmutablepath-findings.md), the
[copy-and-append evaluation](copy-append-library-evaluation/README.md), and the
[historical investigation](history.md) explain the implementation and its limits.
