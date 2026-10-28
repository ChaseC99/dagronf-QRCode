# Remaining pixel generators: macOS Release comparison

Collected October 27, 2026 (America/Los_Angeles), on Apple M1 Pro / MacBookPro18,1,
10 cores, 32 GiB RAM, macOS 26.7.1 (25G241), Xcode 27.1 (27A9275), Swift 6.4.
These are macOS results, not physical-iPhone results.

The final patch batches 64 emitted paths for Abstract, Rounded Path, Blob, Circuit,
Drip Horizontal, Drip Vertical, Crosshatch, Curve Pixel, Pointy, Razor, Rounded End
Indent, and Vortex. It returns one vector path and preserves geometry, transforms,
append order, closure, winding, complete neighborhood queries, and seeded random
values. Off cells may emit multiple paths; each append counts toward the batch.
Vortex's ring traversal and its existing repeated odd-center emissions are
preserved. There are no public API changes or geometry caches.

Horizontal and Vertical were trialed but restored byte for byte because batching
slowed their native merged-run construction. Together with the earlier work, 40
of the 43 registered styles use batching; Rounded Rectangle, Horizontal, and
Vertical retain their native implementations. The inventory was checked against
`QRCodePixelShapeFactory.registeredTypes`.

## Reports and method

- [BEFORE](remaining-before-macos-arm64.json): all 14 remaining generators unchanged.
- [All-batched trial](remaining-trial-macos-arm64.json): includes rejected Horizontal/Vertical changes.
- [Final AFTER](remaining-after-macos-arm64.json): the retained 12-style patch.
- [BEFORE repeat](remaining-before-repeat-macos-arm64.json): identical source contents,
  with late-run external build contention; see the limitations below.

Every report has a `.json.source-state.json` sidecar containing hashes, the dirty
tracked patch, and new source/test/script contents. Its hash is recorded in the
report. The earlier benchmark reports were not overwritten. An initial run with
only 13 new styles was interrupted when the factory inventory revealed Abstract;
no timing report completed. Its source snapshot is retained as
[the incomplete 13-style state](remaining-incomplete-13-styles.source-state.json).
No timing samples from that incomplete run are used here.

The harness has 25 styles: all 14 remaining styles plus the previous 11 controls.
The three existing payloads and all measurement boundaries are unchanged. Each
of 75 cases measures path construction and full-image rendering independently,
with one warm-up and five samples per operation (750 measured samples/report).
Encoding, generator/design setup, validation, object release, and file output
remain outside timing. The same Core Image encoder, high correction, colors,
quiet zone, and output sizing are used. The 31/91/171-module matrices contain
303/3,863/14,173 active data modules and produce 702/693/716-pixel square images.

Hardware, OS, Swift/Xcode, dependencies, harness SHA-256, method, fixtures, matrix
fingerprints, dimensions, case order, settings, and sample counts were compared
between reports. BEFORE and final AFTER measurement time was 488 and 38 seconds,
respectively, excluding builds.

## Primary results

Every value below is **median [minimum–maximum] milliseconds**, using all five
samples. Speedup = BEFORE median / AFTER median. JSON also retains every sample,
mean, and population standard deviation. Native Horizontal/Vertical remain in the
tables to show measurement variation rather than attributing gains to unchanged code.

### Pixel-path construction

| Style | Payload | BEFORE ms [range] | Final AFTER ms [range] | Speedup |
| --- | --- | ---: | ---: | ---: |
| Abstract | small | 0.794 [0.769–0.832] | 0.246 [0.245–0.323] | 3.22× |
| Rounded Path | small | 1.273 [1.271–1.336] | 0.358 [0.353–0.358] | 3.56× |
| Blob | small | 2.350 [2.325–2.511] | 0.387 [0.380–0.395] | 6.08× |
| Circuit | small | 2.413 [2.365–2.468] | 0.642 [0.632–0.714] | 3.76× |
| Drip Horizontal | small | 1.750 [1.549–2.016] | 0.416 [0.407–0.420] | 4.20× |
| Drip Vertical | small | 1.724 [1.632–2.008] | 0.445 [0.427–0.473] | 3.88× |
| Crosshatch | small | 2.241 [2.228–2.318] | 0.652 [0.621–0.673] | 3.44× |
| Curve Pixel | small | 0.635 [0.633–0.735] | 0.206 [0.203–0.211] | 3.09× |
| Pointy | small | 0.341 [0.331–0.360] | 0.102 [0.098–0.105] | 3.34× |
| Razor | small | 1.418 [1.338–1.506] | 0.304 [0.299–0.307] | 4.66× |
| Rounded End Indent | small | 0.645 [0.644–0.658] | 0.231 [0.229–0.271] | 2.79× |
| Vortex | small | 0.773 [0.771–0.775] | 0.256 [0.255–0.260] | 3.02× |
| Horizontal (unchanged) | small | 0.104 [0.103–0.105] | 0.104 [0.103–0.106] | 1.00× |
| Vertical (unchanged) | small | 0.135 [0.104–0.142] | 0.104 [0.103–0.107] | 1.30× |
| Abstract | medium | 118.729 [115.389–121.283] | 3.397 [3.174–3.503] | 34.95× |
| Rounded Path | medium | 188.726 [188.080–193.732] | 4.405 [4.223–4.488] | 42.84× |
| Blob | medium | 339.869 [339.078–343.225] | 4.724 [4.606–4.889] | 71.95× |
| Circuit | medium | 423.660 [409.295–447.821] | 9.099 [9.014–9.390] | 46.56× |
| Drip Horizontal | medium | 272.744 [270.101–282.549] | 5.852 [5.815–5.902] | 46.61× |
| Drip Vertical | medium | 268.868 [268.136–269.834] | 5.819 [5.712–5.895] | 46.20× |
| Crosshatch | medium | 400.096 [390.991–429.076] | 8.409 [8.289–8.441] | 47.58× |
| Curve Pixel | medium | 85.556 [84.681–89.319] | 2.414 [2.405–2.447] | 35.44× |
| Pointy | medium | 51.055 [50.192–54.511] | 1.267 [1.246–1.309] | 40.31× |
| Razor | medium | 210.167 [208.327–238.390] | 3.628 [3.516–3.653] | 57.93× |
| Rounded End Indent | medium | 86.656 [83.271–141.457] | 2.682 [2.555–2.767] | 32.31× |
| Vortex | medium | 109.791 [107.437–111.679] | 3.172 [3.153–3.356] | 34.61× |
| Horizontal (unchanged) | medium | 1.124 [1.120–1.159] | 1.130 [1.118–1.182] | 0.99× |
| Vertical (unchanged) | medium | 1.181 [1.176–1.271] | 1.182 [1.166–1.197] | 1.00× |
| Abstract | large | 1545.057 [1538.112–1913.266] | 12.238 [12.041–12.415] | 126.25× |
| Rounded Path | large | 2471.726 [2426.575–2518.037] | 15.648 [15.000–17.856] | 157.96× |
| Blob | large | 4597.701 [4570.924–4604.940] | 16.767 [16.398–17.519] | 274.22× |
| Circuit | large | 5841.390 [5674.214–6598.895] | 33.980 [33.816–34.379] | 171.91× |
| Drip Horizontal | large | 3830.602 [3806.365–5914.635] | 22.866 [22.148–24.698] | 167.52× |
| Drip Vertical | large | 3847.119 [3681.140–4194.864] | 20.975 [20.887–21.321] | 183.42× |
| Crosshatch | large | 5362.837 [5214.989–5397.112] | 31.516 [30.746–31.748] | 170.16× |
| Curve Pixel | large | 1140.281 [1114.173–1233.586] | 9.023 [8.835–9.139] | 126.37× |
| Pointy | large | 670.591 [664.760–684.147] | 4.583 [4.556–4.604] | 146.31× |
| Razor | large | 2770.302 [2713.950–2936.287] | 12.890 [12.864–12.942] | 214.92× |
| Rounded End Indent | large | 1105.982 [1093.107–1126.514] | 9.607 [9.448–10.090] | 115.12× |
| Vortex | large | 1462.818 [1440.475–1617.889] | 12.050 [11.659–12.107] | 121.39× |
| Horizontal (unchanged) | large | 4.153 [4.150–4.195] | 4.026 [4.015–4.056] | 1.03× |
| Vertical (unchanged) | large | 4.393 [4.285–4.644] | 4.261 [4.241–4.422] | 1.03× |

### Complete-image rendering

| Style | Payload | BEFORE ms [range] | Final AFTER ms [range] | Speedup |
| --- | --- | ---: | ---: | ---: |
| Abstract | small | 2.228 [2.150–2.455] | 1.644 [1.639–1.835] | 1.36× |
| Rounded Path | small | 2.420 [2.390–2.678] | 1.527 [1.493–1.629] | 1.59× |
| Blob | small | 4.046 [3.781–4.648] | 1.812 [1.794–1.843] | 2.23× |
| Circuit | small | 4.812 [4.609–5.273] | 2.938 [2.906–3.076] | 1.64× |
| Drip Horizontal | small | 3.258 [3.189–3.923] | 2.119 [2.068–2.229] | 1.54× |
| Drip Vertical | small | 3.171 [3.101–3.356] | 2.215 [2.015–2.569] | 1.43× |
| Crosshatch | small | 5.606 [5.518–5.796] | 4.071 [3.877–4.272] | 1.38× |
| Curve Pixel | small | 1.661 [1.647–2.036] | 1.239 [1.196–1.257] | 1.34× |
| Pointy | small | 0.805 [0.764–0.908] | 0.555 [0.527–0.630] | 1.45× |
| Razor | small | 3.268 [2.871–3.556] | 1.744 [1.736–1.773] | 1.87× |
| Rounded End Indent | small | 1.626 [1.598–1.693] | 1.232 [1.216–1.389] | 1.32× |
| Vortex | small | 1.609 [1.582–1.793] | 1.076 [1.054–1.115] | 1.50× |
| Horizontal (unchanged) | small | 0.763 [0.754–0.852] | 0.754 [0.745–0.780] | 1.01× |
| Vertical (unchanged) | small | 1.169 [1.039–1.245] | 0.880 [0.867–0.882] | 1.33× |
| Abstract | medium | 131.587 [128.137–134.872] | 14.716 [14.653–16.105] | 8.94× |
| Rounded Path | medium | 198.613 [196.542–200.956] | 14.412 [14.286–14.971] | 13.78× |
| Blob | medium | 356.090 [354.219–366.420] | 19.807 [19.036–19.881] | 17.98× |
| Circuit | medium | 463.214 [450.183–486.808] | 53.199 [51.262–53.891] | 8.71× |
| Drip Horizontal | medium | 302.083 [299.014–330.444] | 33.799 [33.463–34.185] | 8.94× |
| Drip Vertical | medium | 298.993 [291.792–330.758] | 32.569 [31.863–33.734] | 9.18× |
| Crosshatch | medium | 474.682 [439.959–717.700] | 57.193 [56.771–59.059] | 8.30× |
| Curve Pixel | medium | 92.845 [91.825–95.931] | 8.895 [8.874–8.983] | 10.44× |
| Pointy | medium | 53.924 [51.374–54.965] | 2.707 [2.640–2.899] | 19.92× |
| Razor | medium | 229.225 [224.121–246.653] | 16.417 [15.988–17.497] | 13.96× |
| Rounded End Indent | medium | 94.497 [90.267–110.020] | 9.947 [9.589–10.035] | 9.50× |
| Vortex | medium | 117.912 [116.753–121.213] | 13.490 [12.339–13.749] | 8.74× |
| Horizontal (unchanged) | medium | 8.012 [7.937–8.087] | 8.455 [7.995–8.787] | 0.95× |
| Vertical (unchanged) | medium | 13.461 [13.424–14.929] | 13.814 [13.544–15.323] | 0.97× |
| Abstract | large | 1609.583 [1596.128–1764.194] | 66.829 [65.522–67.760] | 24.09× |
| Rounded Path | large | 2479.019 [2430.161–2653.420] | 47.894 [45.019–49.703] | 51.76× |
| Blob | large | 4647.082 [4617.128–4670.273] | 73.503 [71.680–76.918] | 63.22× |
| Circuit | large | 6042.497 [5858.990–6087.185] | 255.114 [252.994–283.959] | 23.69× |
| Drip Horizontal | large | 3966.034 [3915.740–4219.659] | 144.049 [141.775–152.529] | 27.53× |
| Drip Vertical | large | 3998.463 [3811.782–4252.428] | 124.707 [124.334–125.893] | 32.06× |
| Crosshatch | large | 5667.521 [5595.423–5740.707] | 331.118 [330.075–336.093] | 17.12× |
| Curve Pixel | large | 1162.335 [1134.266–1231.498] | 32.798 [31.263–33.037] | 35.44× |
| Pointy | large | 680.651 [666.324–688.635] | 7.902 [7.839–7.960] | 86.14× |
| Razor | large | 2817.654 [2805.595–2889.621] | 56.571 [56.385–58.349] | 49.81× |
| Rounded End Indent | large | 1146.891 [1111.432–1232.976] | 32.406 [32.155–32.829] | 35.39× |
| Vortex | large | 1619.128 [1545.514–1763.123] | 60.315 [57.150–63.538] | 26.84× |
| Horizontal (unchanged) | large | 21.047 [20.988–21.062] | 20.613 [20.525–22.515] | 1.02× |
| Vertical (unchanged) | large | 52.346 [50.272–85.768] | 61.958 [58.774–67.512] | 0.84× |

## Rejected native-run batching

Both run generators already merge adjacent modules before adding native rounded
rectangles. The trial preserved that merging and batched the resulting runs, but
large path construction got 26% slower for Horizontal and 23% slower for Vertical.
Medium paths also slowed, by 19% and 27%. All native trial data is retained below;
the unchanged final implementations were not selected merely from a faster sample.

| Style | Payload | Operation | BEFORE ms [range] | Trial ms [range] | BEFORE / trial |
| --- | --- | --- | ---: | ---: | ---: |
| horizontal | small | path | 0.104 [0.103–0.105] | 0.118 [0.117–0.122] | 0.88× |
| horizontal | small | image | 0.763 [0.754–0.852] | 0.781 [0.772–0.893] | 0.98× |
| vertical | small | path | 0.135 [0.104–0.142] | 0.124 [0.123–0.127] | 1.09× |
| vertical | small | image | 1.169 [1.039–1.245] | 0.950 [0.923–0.983] | 1.23× |
| horizontal | medium | path | 1.124 [1.120–1.159] | 1.335 [1.324–1.360] | 0.84× |
| horizontal | medium | image | 8.012 [7.937–8.087] | 8.884 [8.641–9.341] | 0.90× |
| vertical | medium | path | 1.181 [1.176–1.271] | 1.496 [1.395–1.628] | 0.79× |
| vertical | medium | image | 13.461 [13.424–14.929] | 15.562 [15.249–15.843] | 0.87× |
| horizontal | large | path | 4.153 [4.150–4.195] | 5.234 [5.128–5.275] | 0.79× |
| horizontal | large | image | 21.047 [20.988–21.062] | 23.877 [23.745–24.393] | 0.88× |
| vertical | large | path | 4.393 [4.285–4.644] | 5.401 [5.230–5.686] | 0.81× |
| vertical | large | image | 52.346 [50.272–85.768] | 72.190 [64.031–75.024] | 0.73× |

## Controls, noise and repeats

The final AFTER improves every retained style at every payload size: 2.79–6.08×
for small paths and 1.32–2.23× for small images; 32.31–71.95× for medium paths and
8.30–19.92× for medium images; 115.12–274.22× for large paths and 17.12–86.14× for
large images. These ranges use the first complete BEFORE/final-AFTER pair, not the
most favorable report or sample.

The initial baseline contained several outliers. CV here means population standard
deviation divided by mean. Repeating the baseline with **all 306 input file hashes
identical** helped investigate them (Git staging/untracked classification changed,
so sidecar JSON hashes differ even though source contents match):

| Case | First BEFORE median / CV | Repeat BEFORE median / CV | Final AFTER median / CV |
| --- | ---: | ---: | ---: |
| Medium Crosshatch image | 474.682 ms / 19.5% | 434.585 ms / 1.1% | 57.193 ms / 1.5% |
| Medium Rounded End Indent path | 86.656 ms / 22.6% | 83.269 ms / 1.9% | 2.682 ms / 3.2% |
| Large Drip Horizontal path | 3830.602 ms / 19.0% | 3862.998 ms / 2.6% | 22.866 ms / 4.4% |
| Large Squircle image (control) | 304.793 ms / 17.2% | 299.744 ms / 0.5% | 302.383 ms / 1.8% |
| Large Vertical image (unchanged) | 52.346 ms / 22.9% | 89.082 ms / 14.4% | 61.958 ms / 4.9% |

**The repeat baseline is contended, not a second quiet comparison.** At about
7 minutes 43 seconds, a process check found an external Xcode build and asset
compilation alongside the benchmark. Simulator startup and QR Contact UI tests
followed. This particularly limits interpretation of late cases, including the
unchanged Horizontal and Vertical styles. Their variation is not credited to
batching. The first complete baseline and final AFTER had already finished before
this observed external build activity. No other builds/tests were launched by this
task during those timed runs; background desktop activity was not fully controlled.

At the user's request, work finished with the existing four completed reports;
**no additional AFTER repeat was collected**. The primary comparison is complete,
and all trial/repeat data is retained. Precise small percentage differences, and
especially Vertical image timing, remain uncertain. The retained styles' large
improvements are much larger than the observed noise, but these runs do not provide
formal confidence intervals or isolated-device performance guarantees.

Control ratios below use the complete primary pair. No speedup is attributed to
these unchanged implementations. Maximum CV is the largest of their BEFORE/AFTER
path/image CVs; all individual samples remain in JSON.

| Control | Payload | Path speedup | Image speedup | Maximum CV |
| --- | --- | ---: | ---: | ---: |
| Square | small | 0.93× | 0.82× | 9.0% |
| Circle | small | 0.96× | 0.90× | 9.0% |
| Squircle | small | 1.00× | 1.01× | 5.8% |
| Flower | small | 1.01× | 1.08× | 12.1% |
| Gear | small | 0.99× | 1.02× | 9.8% |
| Rounded Rectangle | small | 0.79× | 1.07× | 16.5% |
| Grid 2×2 | small | 1.00× | 0.83× | 12.6% |
| Grid 3×3 | small | 1.00× | 1.01× | 9.8% |
| Grid 4×4 | small | 0.92× | 0.91× | 11.4% |
| Donut | small | 1.00× | 0.91× | 11.7% |
| Diagonal Stripes | small | 0.98× | 1.07× | 7.3% |
| Horizontal | small | 1.00× | 1.01× | 4.7% |
| Vertical | small | 1.30× | 1.33× | 10.5% |
| Square | medium | 1.04× | 1.09× | 9.4% |
| Circle | medium | 1.06× | 1.05× | 6.6% |
| Squircle | medium | 1.03× | 1.03× | 3.9% |
| Flower | medium | 1.00× | 1.00× | 9.2% |
| Gear | medium | 1.04× | 1.05× | 14.0% |
| Rounded Rectangle | medium | 1.01× | 0.99× | 3.9% |
| Grid 2×2 | medium | 1.00× | 0.99× | 2.6% |
| Grid 3×3 | medium | 1.01× | 1.02× | 2.4% |
| Grid 4×4 | medium | 1.02× | 1.03× | 1.1% |
| Donut | medium | 1.05× | 1.07× | 2.7% |
| Diagonal Stripes | medium | 1.02× | 1.00× | 1.4% |
| Horizontal | medium | 0.99× | 0.95× | 3.2% |
| Vertical | medium | 1.00× | 0.97× | 4.5% |
| Square | large | 0.96× | 0.97× | 2.4% |
| Circle | large | 1.00× | 0.99× | 3.5% |
| Squircle | large | 1.03× | 1.01× | 17.2% |
| Flower | large | 0.98× | 0.99× | 3.3% |
| Gear | large | 1.00× | 0.94× | 2.6% |
| Rounded Rectangle | large | 0.98× | 0.96× | 1.3% |
| Grid 2×2 | large | 0.97× | 0.96× | 1.6% |
| Grid 3×3 | large | 0.99× | 0.97× | 3.6% |
| Grid 4×4 | large | 1.06× | 1.03× | 3.0% |
| Donut | large | 1.05× | 1.03× | 2.4% |
| Diagonal Stripes | large | 0.99× | 0.99× | 3.3% |
| Horizontal | large | 1.03× | 1.02× | 3.6% |
| Vertical | large | 1.03× | 0.84× | 22.9% |

<details>
<summary>All remaining-style repeat-baseline medians and min–max ranges (milliseconds; contended)</summary>

| Style | Payload | Repeat path ms [range] | Repeat image ms [range] |
| --- | --- | ---: | ---: |
| Abstract | small | 0.785 [0.766–0.843] | 2.263 [2.172–2.390] |
| Rounded Path | small | 1.279 [1.273–1.300] | 2.475 [2.422–2.654] |
| Blob | small | 2.338 [2.334–2.516] | 3.785 [3.744–3.907] |
| Circuit | small | 2.352 [2.333–2.394] | 4.708 [4.655–4.940] |
| Drip Horizontal | small | 1.571 [1.562–1.597] | 3.285 [3.227–3.399] |
| Drip Vertical | small | 1.591 [1.583–1.627] | 3.096 [3.071–3.164] |
| Crosshatch | small | 2.230 [2.221–2.256] | 5.410 [5.376–5.420] |
| Curve Pixel | small | 0.637 [0.635–0.675] | 1.643 [1.620–1.710] |
| Pointy | small | 0.330 [0.330–0.337] | 0.740 [0.735–0.746] |
| Razor | small | 1.339 [1.334–1.354] | 2.892 [2.787–2.955] |
| Rounded End Indent | small | 0.645 [0.643–0.647] | 1.628 [1.589–1.674] |
| Vortex | small | 0.774 [0.770–0.804] | 1.593 [1.566–1.645] |
| Horizontal | small | 0.103 [0.103–0.105] | 0.756 [0.741–0.806] |
| Vertical | small | 0.104 [0.103–0.107] | 0.876 [0.872–0.883] |
| Abstract | medium | 114.696 [112.800–118.777] | 126.848 [123.484–128.584] |
| Rounded Path | medium | 185.222 [184.649–186.840] | 193.787 [193.411–198.037] |
| Blob | medium | 347.718 [340.654–348.344] | 363.179 [356.786–369.465] |
| Circuit | medium | 421.300 [403.115–429.121] | 464.076 [445.516–508.254] |
| Drip Horizontal | medium | 272.198 [271.697–280.595] | 303.864 [297.449–304.796] |
| Drip Vertical | medium | 267.822 [265.984–276.907] | 293.521 [290.552–298.757] |
| Crosshatch | medium | 387.670 [380.956–389.798] | 434.585 [429.454–443.378] |
| Curve Pixel | medium | 86.182 [85.729–90.912] | 95.472 [92.562–99.092] |
| Pointy | medium | 54.295 [52.566–56.539] | 56.365 [56.295–57.734] |
| Razor | medium | 213.446 [207.552–226.799] | 225.410 [221.534–239.469] |
| Rounded End Indent | medium | 83.269 [81.284–85.339] | 89.163 [88.132–96.250] |
| Vortex | medium | 107.927 [107.014–111.820] | 119.634 [116.073–120.769] |
| Horizontal | medium | 1.142 [1.134–1.171] | 8.125 [7.939–8.739] |
| Vertical | medium | 1.181 [1.170–1.199] | 13.478 [13.431–13.682] |
| Abstract | large | 1538.957 [1515.253–1590.085] | 1597.032 [1576.666–1645.881] |
| Rounded Path | large | 2408.957 [2381.741–2474.296] | 2433.031 [2391.728–2453.683] |
| Blob | large | 4577.074 [4557.001–4668.645] | 4579.681 [4546.780–5028.454] |
| Circuit | large | 5664.829 [5641.960–5949.337] | 5887.122 [5799.264–6008.759] |
| Drip Horizontal | large | 3862.998 [3769.211–4050.998] | 4123.271 [3971.913–4408.160] |
| Drip Vertical | large | 3659.882 [3642.731–3771.754] | 3744.961 [3707.150–3807.576] |
| Crosshatch | large | 5316.876 [5218.674–5994.011] | 5645.427 [5520.012–5883.691] |
| Curve Pixel | large | 1138.158 [1109.611–1243.750] | 1173.011 [1129.765–1267.702] |
| Pointy | large | 673.571 [668.393–680.655] | 672.321 [665.391–703.039] |
| Razor | large | 2758.433 [2736.195–2814.461] | 2804.295 [2775.454–2846.572] |
| Rounded End Indent | large | 1116.680 [1112.053–1262.921] | 1143.014 [1119.371–1179.413] |
| Vortex | large | 1437.210 [1421.185–1726.141] | 1565.321 [1507.155–1876.947] |
| Horizontal | large | 4.375 [4.223–4.440] | 23.878 [23.198–35.325] |
| Vertical | large | 4.473 [4.398–4.531] | 89.082 [70.468–107.207] |

</details>

## Correctness

`QRCodeNeighborBatchingTests` passed on the original production code in Release
before changing any of these 14 generators. On the final patch, **35 selected tests
passed in Debug and 35 in Release**, including existing shared/standalone batching,
path, SVG, masking, image export, and QR detection tests. The new suite performs
**50,353 ordered-path/raster comparisons**:

- All 512 binary 3×3 neighborhoods for all 14 styles, plus Rounded Path without
  inner corners and Rounded End Indent with them enabled. Each pattern appears
  in a 3×3 matrix (real edges/corners), an even interior matrix, and four odd
  interior placements that exercise every Vortex quadrant: 49,152 comparisons.
- Empty, single-cell, sparse, and dense odd/even matrices; corner/edge cells;
  active counts 63/64/65 and 127/128/129; fractional rectangular output sizes.
- Exact **emitted-path** counts 63/64/65 and 127/128/129 for every style and both
  odd/even dimensions, with repeated calls to catch state leaking between renders.
- Separate off-cell fixtures for Rounded Path, Blob, Razor, and Rounded End
  Indent: rings with off centers emit four extra paths each. Their emission
  counts reach the same exact boundaries while active counts are smaller.
- Corner radii 0/0.43/1, inset fractions 0/0.27/1 where supported, inner-corner
  switches, and exact/partial batches. Abstract's seed and sequence are preserved
  across batches and reset on repeated calls. Vortex's odd-center behavior is
  intentionally retained, not repaired as part of this performance change.

Expected output comes from frozen, test-only unbatched implementations in
`Tests/QRCodeTests/UnbatchedNeighbors`. Their headers identify each original source
and SHA-256. They copy the original private geometry and traversal into a separate
namespace, remove explicit Objective-C attributes, public modifiers and unused conveniences, and count
outer `addPath` calls while appending directly to one CGMutablePath. This avoids
masking neighbors or routing the reference through the optimized accumulator.
Shared math/neighbor utilities are reused and unchanged. The snapshots are
independent of production template edits, but are not an independent specification
of whether the original artwork itself was correct.

Checks require identical ordered element types and point counts, coordinates
within 1e-10, and byte-for-byte RGBA rasters using a translucent nonzero fill.
There are no per-batch drawing calls. The coordinate tolerance follows the earlier
Core Graphics native-path expansion findings; raster equality remains exact.

## Reproduction

Use the same Mac/toolchain, a quiet machine, and five samples. Runs were serial;
no other builds or tests were launched during measurements. Source states, including
untracked reference files and the accumulator, can be restored using the executable
Python recipe in [README](README.md#exact-source-states-and-reproduction), selecting
one of this report's JSON files. All four completed report restoration recipes were
verified against every recorded file hash. Resolved dependencies come from the
report's `metadata.packageResolved`.

```sh
# Original remaining generators, complete expanded harness:
swift test -c release --filter QRCodeNeighborBatchingTests
bash scripts/benchmark-render.sh Benchmarks/remaining-before-macos-arm64.json

# All 14 batched, including the subsequently rejected native changes:
bash scripts/benchmark-render.sh Benchmarks/remaining-trial-macos-arm64.json

# Restore Horizontal/Vertical; validate and measure the retained patch:
swift test --filter 'QRCodeNeighborBatchingTests|QRCodeStandaloneBatchingTests|QRCodePixelBatchingTests|QRCodePathTests|QRCodeSVGTests|QRCodeMaskingTests|QRCodeTests.testBasicDocumentionationCode|QRCodeDetectionTests.testBasicDetection'
swift test -c release --filter 'QRCodeNeighborBatchingTests|QRCodeStandaloneBatchingTests|QRCodePixelBatchingTests|QRCodePathTests|QRCodeSVGTests|QRCodeMaskingTests|QRCodeTests.testBasicDocumentionationCode|QRCodeDetectionTests.testBasicDetection'
bash scripts/benchmark-render.sh Benchmarks/remaining-after-macos-arm64.json

# Restore recorded BEFORE inputs and repeat; restore final AFTER sources afterward:
bash scripts/benchmark-render.sh Benchmarks/remaining-before-repeat-macos-arm64.json
# A further AFTER repeat was not collected, per the user's request.
```

Existing report names are protected against overwrites; use new names when
reproducing. The method has no performance threshold and reports five observations,
not statistical confidence intervals. Memory, encoding, vector export, and actual
iPhone performance were not measured. Batch size 64 is not claimed optimal.
Further geometry caching is deferred until profiling establishes that repeated
template construction remains significant; this patch changes accumulation only.
