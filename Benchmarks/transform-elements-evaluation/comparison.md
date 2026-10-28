# Release comparison: original, batching, element-wise accumulation

Measurements on Apple M1 Pro / MacBookPro18,1, macOS 26.7.1 (25G241), Xcode 27.1 / Swift 6.4. These are macOS results; no physical-iPhone performance claim is made.

The unchanged 25-style harness covers three fixed fixtures, 75 cases and 750 measured samples per run. Each operation/case has one warm-up and five samples. Original medians use five samples; batching and final candidate medians pool ten samples from two separate alternating runs. Full images include context allocation, masking, paths, drawing and makeImage. Path timings include only the pixel generator on the prepared matrix. Encoding, fixture preparation, validation and destruction are outside timing.

## Recorded runs

| Started (Los Angeles) | Variant | Test duration | Raw samples and source state |
| --- | --- | ---: | --- |
| 2026-10-27 23:41 PDT | transform-original | 1419 s | [JSON](../transform-original-macos-arm64.json), [source](../transform-original-macos-arm64.json.source-state.json) |
| 2026-10-27 23:34 PDT | transform-batching-2 | 39 s | [JSON](../transform-batching-2-macos-arm64.json), [source](../transform-batching-2-macos-arm64.json.source-state.json) |
| 2026-10-27 23:36 PDT | transform-elements-3 | 33 s | [JSON](../transform-elements-3-macos-arm64.json), [source](../transform-elements-3-macos-arm64.json.source-state.json) |
| 2026-10-27 23:37 PDT | transform-batching-3 | 39 s | [JSON](../transform-batching-3-macos-arm64.json), [source](../transform-batching-3-macos-arm64.json.source-state.json) |
| 2026-10-27 23:38 PDT | transform-elements-4 | 33 s | [JSON](../transform-elements-4-macos-arm64.json), [source](../transform-elements-4-macos-arm64.json.source-state.json) |

The paired order was batching 2 → elements 3 → batching 3 → elements 4, followed by the original reference. All five reports have identical harness hashes, fixtures/matrix fingerprints, settings, dependency pins, hardware, OS and toolchain metadata. Runs were serial in the same temporary checkout; no other agent builds or tests ran during measurements. Build time is excluded above.

## Large fixture

Median milliseconds. Speedup is batching / elements, so values above 1 favor the replacement.

| Style | Original path | Batched path | Element path | Path speedup | Original image | Batched image | Element image | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| square | 645.034 | 4.800 | 4.627 | 1.04× | 637.412 | 7.432 | 7.078 | 1.05× |
| circle | 1792.279 | 11.312 | 6.431 | 1.76× | 1862.359 | 64.969 | 64.098 | 1.01× |
| squircle | 3331.733 | 19.257 | 6.059 | 3.18× | 3608.131 | 305.983 | 291.804 | 1.05× |
| flower | 8930.229 | 50.219 | 9.383 | 5.35× | 9383.248 | 483.983 | 450.992 | 1.07× |
| gear | 19074.806 | 102.829 | 18.186 | 5.65× | 20088.497 | 881.308 | 800.960 | 1.10× |
| roundedRect | 8.083 | 9.302 | 7.791 | 1.19× | 91.536 | 88.331 | 87.898 | 1.00× |
| grid2x2 | 3067.314 | 17.421 | 7.541 | 2.31× | 3101.833 | 28.589 | 18.333 | 1.56× |
| grid3x3 | 7072.096 | 39.430 | 13.552 | 2.91× | 6971.985 | 86.444 | 58.004 | 1.49× |
| grid4x4 | 12484.787 | 65.800 | 20.954 | 3.14× | 12777.947 | 190.053 | 144.462 | 1.32× |
| donut | 4361.276 | 24.291 | 6.154 | 3.95× | 4875.411 | 382.498 | 364.587 | 1.05× |
| diagonalStripes | 12294.256 | 65.041 | 13.157 | 4.94× | 12906.573 | 782.692 | 738.476 | 1.06× |
| abstract | 1512.075 | 11.982 | 7.776 | 1.54× | 1600.446 | 66.309 | 60.927 | 1.09× |
| roundedPath | 2400.291 | 14.793 | 11.511 | 1.29× | 2449.491 | 43.291 | 40.129 | 1.08× |
| blob | 4635.114 | 16.454 | 11.853 | 1.39× | 4589.168 | 71.528 | 67.458 | 1.06× |
| circuit | 5788.951 | 34.932 | 8.848 | 3.95× | 5960.349 | 262.352 | 226.175 | 1.16× |
| dripHorizontal | 3921.791 | 24.133 | 6.768 | 3.57× | 3912.983 | 153.583 | 134.378 | 1.14× |
| dripVertical | 3649.562 | 22.278 | 6.416 | 3.47× | 3777.832 | 133.560 | 112.280 | 1.19× |
| crosshatch | 5320.349 | 31.870 | 8.665 | 3.68× | 5613.548 | 351.750 | 316.486 | 1.11× |
| curvePixel | 1100.280 | 8.980 | 6.925 | 1.30× | 1144.526 | 32.514 | 30.322 | 1.07× |
| pointy | 672.843 | 4.681 | 4.288 | 1.09× | 676.930 | 8.195 | 7.743 | 1.06× |
| razor | 2782.646 | 12.990 | 8.219 | 1.58× | 2856.414 | 57.074 | 52.113 | 1.10× |
| roundedEndIndent | 1101.150 | 9.699 | 7.399 | 1.31× | 1105.428 | 33.453 | 30.140 | 1.11× |
| vortex | 1431.165 | 12.175 | 8.297 | 1.47× | 1473.840 | 74.301 | 56.172 | 1.32× |
| horizontal | 4.114 | 4.319 | 4.188 | 1.03× | 21.043 | 22.480 | 22.168 | 1.01× |
| vertical | 4.282 | 4.522 | 4.282 | 1.06× | 52.770 | 83.492 | 53.405 | 1.56× |

## Repeats, small cases and limits

Across all 150 case/operation combinations, **0** had a median increase greater than 5% in both adjacent batching/candidate pairs. This is a practical noise screen, not a statistical confidence interval or a guarantee for unmeasured workloads.

Small Square path: pooled 0.1028 → 0.1090 ms (+6.1%, +0.0062 ms); individual-pair changes were +8.1% and -1.0%.

Small Square image: pooled 0.4116 → 0.4630 ms (+12.5%, +0.0514 ms); individual-pair changes were +13.3% and +3.9%.

The small Square increases are disclosed rather than described as universal speedups. Their absolute size is small; the >5% increase did not repeat in the second pair. Large Square also changed direction between pairs. Full-image measurements vary more than path measurements, including the unchanged Horizontal/Vertical controls. Rounded Rectangle retains its identity append but loses the incoming common-generator batching bookkeeping, so its improvement is not attributed to the new helper.

No material repeatable regression was identified in these measured workloads. More complex path construction improves substantially; complete-image gains are smaller where drawing dominates. Native transformed appends show much steeper size scaling on this installed OS. Memory, power and physical-iPhone performance were not measured.

## All cases

Cells are median [minimum–maximum] milliseconds, using five original or ten pooled comparison samples.

| Fixture | Style | Operation | Original | Batching | Elements |
| --- | --- | --- | ---: | ---: | ---: |
| small | square | path | 0.320 [0.319–0.324] | 0.103 [0.101–0.109] | 0.109 [0.106–0.120] |
| small | square | image | 0.635 [0.629–0.672] | 0.412 [0.387–0.430] | 0.463 [0.417–0.588] |
| small | circle | path | 0.842 [0.839–0.848] | 0.231 [0.229–0.373] | 0.149 [0.139–0.155] |
| small | circle | image | 1.714 [1.688–1.727] | 1.104 [1.079–1.315] | 1.099 [1.019–1.196] |
| small | squircle | path | 1.535 [1.532–1.536] | 0.381 [0.378–0.446] | 0.153 [0.130–0.175] |
| small | squircle | image | 3.314 [3.276–3.392] | 2.199 [2.124–2.707] | 2.168 [1.914–2.511] |
| small | flower | path | 4.016 [4.002–4.066] | 1.055 [0.983–1.152] | 0.206 [0.193–0.281] |
| small | flower | image | 6.918 [6.871–7.077] | 4.144 [3.786–4.546] | 3.156 [3.016–3.375] |
| small | gear | path | 8.480 [8.457–8.483] | 2.179 [2.027–2.273] | 0.378 [0.372–0.416] |
| small | gear | image | 11.261 [11.235–11.552] | 4.903 [4.761–5.609] | 3.235 [3.116–3.512] |
| small | roundedRect | path | 0.180 [0.180–0.187] | 0.207 [0.205–0.243] | 0.180 [0.177–0.189] |
| small | roundedRect | image | 1.139 [1.120–1.181] | 1.191 [1.169–1.261] | 1.174 [1.131–1.255] |
| small | grid2x2 | path | 1.391 [1.390–1.413] | 0.345 [0.337–0.390] | 0.167 [0.161–0.169] |
| small | grid2x2 | image | 1.909 [1.901–1.961] | 0.927 [0.852–1.105] | 0.708 [0.676–0.887] |
| small | grid3x3 | path | 3.135 [3.128–3.150] | 0.756 [0.743–0.918] | 0.294 [0.284–0.306] |
| small | grid3x3 | image | 3.952 [3.927–4.007] | 1.583 [1.549–2.090] | 1.182 [1.131–1.291] |
| small | grid4x4 | path | 5.580 [5.558–5.731] | 1.354 [1.334–1.646] | 0.459 [0.430–0.478] |
| small | grid4x4 | image | 6.680 [6.661–6.732] | 2.516 [2.457–2.799] | 1.597 [1.527–1.688] |
| small | donut | path | 1.972 [1.965–2.035] | 0.496 [0.480–0.620] | 0.135 [0.130–0.150] |
| small | donut | image | 3.756 [3.749–3.783] | 2.353 [2.243–2.595] | 1.980 [1.906–2.279] |
| small | diagonalStripes | path | 5.446 [5.420–5.497] | 1.340 [1.295–1.636] | 0.294 [0.282–0.331] |
| small | diagonalStripes | image | 8.836 [8.797–8.877] | 5.007 [4.728–5.991] | 3.715 [3.572–4.023] |
| small | abstract | path | 0.769 [0.766–0.795] | 0.248 [0.243–0.338] | 0.169 [0.165–0.179] |
| small | abstract | image | 2.158 [2.146–2.203] | 1.697 [1.614–2.117] | 1.581 [1.546–1.644] |
| small | roundedPath | path | 1.269 [1.267–1.283] | 0.367 [0.359–0.482] | 0.286 [0.279–0.299] |
| small | roundedPath | image | 2.408 [2.404–2.458] | 1.509 [1.461–1.676] | 1.430 [1.395–1.529] |
| small | blob | path | 2.379 [2.330–2.492] | 0.385 [0.380–0.489] | 0.292 [0.283–0.343] |
| small | blob | image | 3.987 [3.735–4.142] | 1.911 [1.771–2.455] | 1.777 [1.706–1.834] |
| small | circuit | path | 2.430 [2.409–2.478] | 0.645 [0.630–0.927] | 0.199 [0.195–0.209] |
| small | circuit | image | 4.856 [4.697–4.943] | 3.110 [2.846–3.834] | 2.505 [2.470–2.652] |
| small | dripHorizontal | path | 1.586 [1.545–1.592] | 0.415 [0.406–0.558] | 0.140 [0.134–0.147] |
| small | dripHorizontal | image | 3.319 [3.216–3.451] | 2.159 [2.021–2.903] | 1.901 [1.786–2.002] |
| small | dripVertical | path | 1.582 [1.579–1.652] | 0.450 [0.412–0.528] | 0.138 [0.135–0.155] |
| small | dripVertical | image | 3.259 [3.175–3.359] | 2.110 [2.014–2.356] | 1.677 [1.601–1.709] |
| small | crosshatch | path | 2.291 [2.259–2.312] | 0.610 [0.600–0.791] | 0.194 [0.190–0.206] |
| small | crosshatch | image | 5.608 [5.568–5.821] | 4.001 [3.769–4.623] | 3.366 [3.290–3.615] |
| small | curvePixel | path | 0.655 [0.653–0.675] | 0.207 [0.204–0.356] | 0.159 [0.158–0.164] |
| small | curvePixel | image | 1.766 [1.693–1.799] | 1.231 [1.196–1.592] | 1.168 [1.140–1.218] |
| small | pointy | path | 0.349 [0.340–0.353] | 0.099 [0.098–0.107] | 0.096 [0.095–0.099] |
| small | pointy | image | 0.804 [0.781–0.859] | 0.526 [0.510–0.577] | 0.532 [0.512–0.561] |
| small | razor | path | 1.353 [1.334–1.399] | 0.330 [0.299–0.449] | 0.202 [0.197–0.206] |
| small | razor | image | 2.826 [2.774–2.988] | 2.021 [1.737–2.281] | 1.651 [1.621–1.714] |
| small | roundedEndIndent | path | 0.647 [0.643–0.647] | 0.231 [0.229–0.347] | 0.189 [0.184–0.198] |
| small | roundedEndIndent | image | 1.585 [1.575–1.619] | 1.228 [1.165–1.798] | 1.172 [1.124–1.345] |
| small | vortex | path | 0.772 [0.770–0.807] | 0.258 [0.254–0.290] | 0.181 [0.180–0.213] |
| small | vortex | image | 1.558 [1.541–1.608] | 1.062 [1.037–1.463] | 1.019 [0.963–1.137] |
| small | horizontal | path | 0.104 [0.103–0.109] | 0.119 [0.103–0.156] | 0.105 [0.103–0.111] |
| small | horizontal | image | 0.746 [0.738–0.758] | 0.856 [0.738–1.039] | 0.763 [0.742–0.790] |
| small | vertical | path | 0.104 [0.103–0.107] | 0.104 [0.104–0.130] | 0.106 [0.104–0.118] |
| small | vertical | image | 0.867 [0.859–0.877] | 0.878 [0.862–0.984] | 0.902 [0.867–1.035] |
| medium | square | path | 47.686 [46.974–48.773] | 1.300 [1.289–1.517] | 1.249 [1.213–1.369] |
| medium | square | image | 48.365 [48.004–48.915] | 2.341 [2.194–2.808] | 2.196 [2.131–2.340] |
| medium | circle | path | 133.528 [131.072–136.871] | 3.057 [3.038–3.264] | 1.779 [1.731–1.822] |
| medium | circle | image | 153.667 [151.817–157.666] | 23.925 [22.983–25.133] | 23.019 [22.711–23.983] |
| medium | squircle | path | 249.158 [245.178–251.762] | 5.265 [5.138–5.595] | 1.703 [1.610–1.856] |
| medium | squircle | image | 269.109 [266.627–282.569] | 28.869 [27.197–29.930] | 25.288 [24.705–25.962] |
| medium | flower | path | 648.690 [643.385–681.929] | 13.336 [13.238–13.486] | 2.509 [2.486–2.746] |
| medium | flower | image | 769.327 [752.484–775.271] | 110.628 [109.224–111.967] | 100.483 [98.658–104.594] |
| medium | gear | path | 1399.374 [1391.551–1467.967] | 27.885 [27.407–28.622] | 4.884 [4.815–5.132] |
| medium | gear | image | 1499.572 [1492.222–1517.342] | 142.403 [140.013–150.121] | 119.817 [118.874–142.306] |
| medium | roundedRect | path | 2.274 [2.261–2.428] | 2.676 [2.642–3.437] | 2.253 [2.223–2.281] |
| medium | roundedRect | image | 11.279 [11.228–11.487] | 12.335 [11.600–14.896] | 11.387 [11.121–11.801] |
| medium | grid2x2 | path | 229.350 [226.220–243.075] | 4.520 [4.450–5.373] | 2.021 [1.987–2.185] |
| medium | grid2x2 | image | 232.839 [228.363–250.816] | 7.763 [7.504–9.245] | 5.191 [5.079–5.423] |
| medium | grid3x3 | path | 510.990 [504.671–515.946] | 10.120 [10.031–12.569] | 3.697 [3.657–3.852] |
| medium | grid3x3 | image | 518.326 [513.467–538.233] | 19.750 [18.567–22.384] | 12.658 [12.477–13.759] |
| medium | grid4x4 | path | 909.546 [896.802–919.605] | 18.107 [17.599–20.312] | 5.767 [5.564–5.878] |
| medium | grid4x4 | image | 920.774 [916.439–931.620] | 31.594 [30.814–36.084] | 20.079 [19.208–20.945] |
| medium | donut | path | 319.507 [317.883–337.097] | 6.551 [6.444–6.914] | 1.670 [1.611–1.763] |
| medium | donut | image | 377.999 [369.025–379.311] | 55.951 [54.407–57.160] | 52.020 [50.291–53.411] |
| medium | diagonalStripes | path | 906.632 [887.630–938.148] | 17.523 [17.329–19.149] | 3.621 [3.465–3.850] |
| medium | diagonalStripes | image | 1000.037 [970.741–1013.163] | 101.105 [97.066–105.046] | 87.834 [84.757–133.008] |
| medium | abstract | path | 113.815 [113.415–114.651] | 3.111 [3.088–3.638] | 2.114 [2.049–2.244] |
| medium | abstract | image | 125.744 [123.334–129.447] | 13.548 [13.466–17.520] | 13.458 [12.722–15.705] |
| medium | roundedPath | path | 191.579 [185.877–195.671] | 4.148 [4.080–4.586] | 3.243 [3.187–3.341] |
| medium | roundedPath | image | 201.247 [196.644–203.081] | 13.618 [13.020–16.365] | 12.544 [12.163–12.903] |
| medium | blob | path | 340.508 [338.486–350.554] | 4.543 [4.506–5.309] | 3.284 [3.255–3.421] |
| medium | blob | image | 357.523 [354.709–362.812] | 19.083 [18.480–22.259] | 17.827 [17.233–18.454] |
| medium | circuit | path | 413.618 [407.878–456.462] | 9.192 [8.887–9.356] | 2.496 [2.380–2.619] |
| medium | circuit | image | 456.127 [448.702–462.830] | 53.435 [51.699–53.957] | 47.724 [47.162–51.032] |
| medium | dripHorizontal | path | 280.769 [271.130–485.443] | 6.074 [5.817–6.282] | 1.823 [1.728–2.035] |
| medium | dripHorizontal | image | 321.925 [299.140–464.153] | 35.098 [34.009–37.058] | 31.171 [30.261–31.884] |
| medium | dripVertical | path | 269.870 [263.540–270.281] | 5.771 [5.713–6.261] | 1.759 [1.714–1.803] |
| medium | dripVertical | image | 295.765 [291.816–305.916] | 33.431 [31.802–38.222] | 28.143 [27.635–29.227] |
| medium | crosshatch | path | 384.278 [381.707–396.707] | 8.728 [8.270–9.505] | 2.321 [2.279–2.429] |
| medium | crosshatch | image | 431.332 [431.072–437.885] | 60.998 [56.845–67.693] | 52.134 [50.458–54.779] |
| medium | curvePixel | path | 87.647 [85.104–88.498] | 2.595 [2.438–2.805] | 1.819 [1.802–1.856] |
| medium | curvePixel | image | 95.344 [92.749–97.578] | 9.420 [8.888–9.720] | 8.273 [8.202–8.502] |
| medium | pointy | path | 49.506 [49.068–51.942] | 1.320 [1.250–1.346] | 1.171 [1.150–1.200] |
| medium | pointy | image | 52.044 [50.520–52.651] | 2.792 [2.577–2.921] | 2.529 [2.484–2.614] |
| medium | razor | path | 210.380 [207.854–215.827] | 3.638 [3.502–3.893] | 2.264 [2.226–2.280] |
| medium | razor | image | 223.625 [220.528–229.746] | 16.831 [16.032–17.327] | 14.623 [14.400–15.174] |
| medium | roundedEndIndent | path | 82.113 [81.919–85.052] | 2.644 [2.554–2.764] | 2.047 [1.986–2.211] |
| medium | roundedEndIndent | image | 89.653 [88.437–92.306] | 9.622 [9.408–10.090] | 9.482 [8.792–9.611] |
| medium | vortex | path | 107.853 [107.422–109.274] | 3.257 [3.169–3.298] | 2.244 [2.183–2.342] |
| medium | vortex | image | 117.404 [116.327–119.278] | 13.057 [12.334–13.821] | 11.901 [11.051–12.707] |
| medium | horizontal | path | 1.119 [1.114–1.125] | 1.160 [1.123–1.247] | 1.136 [1.113–1.192] |
| medium | horizontal | image | 7.915 [7.889–8.275] | 8.441 [8.046–8.893] | 8.646 [8.471–9.440] |
| medium | vertical | path | 1.169 [1.164–1.169] | 1.205 [1.166–1.345] | 1.212 [1.175–1.331] |
| medium | vertical | image | 13.348 [13.316–14.650] | 14.858 [13.935–16.000] | 14.144 [13.654–17.337] |
| large | square | path | 645.034 [634.293–657.162] | 4.800 [4.728–5.262] | 4.627 [4.428–5.647] |
| large | square | image | 637.412 [630.738–663.519] | 7.432 [7.143–7.670] | 7.078 [6.866–8.310] |
| large | circle | path | 1792.279 [1777.650–1854.061] | 11.312 [11.142–11.914] | 6.431 [6.153–7.501] |
| large | circle | image | 1862.359 [1834.410–1882.548] | 64.969 [63.325–68.833] | 64.098 [58.293–68.744] |
| large | squircle | path | 3331.733 [3318.249–3480.700] | 19.257 [18.601–20.322] | 6.059 [5.840–7.365] |
| large | squircle | image | 3608.131 [3596.663–3648.974] | 305.983 [298.430–340.079] | 291.804 [285.245–318.224] |
| large | flower | path | 8930.229 [8892.435–8989.918] | 50.219 [48.666–51.873] | 9.383 [9.161–10.848] |
| large | flower | image | 9383.248 [9373.361–9389.145] | 483.983 [475.948–708.870] | 450.992 [440.688–482.950] |
| large | gear | path | 19074.806 [18871.340–19935.228] | 102.829 [100.889–112.629] | 18.186 [17.852–19.701] |
| large | gear | image | 20088.497 [19753.949–21132.842] | 881.308 [859.629–949.926] | 800.960 [785.310–853.175] |
| large | roundedRect | path | 8.083 [7.857–9.836] | 9.302 [9.250–9.813] | 7.791 [7.688–8.633] |
| large | roundedRect | image | 91.536 [89.057–95.706] | 88.331 [87.166–91.937] | 87.898 [86.336–99.503] |
| large | grid2x2 | path | 3067.314 [3023.706–3297.984] | 17.421 [16.748–17.614] | 7.541 [7.409–7.964] |
| large | grid2x2 | image | 3101.833 [3051.700–3175.225] | 28.589 [27.690–28.828] | 18.333 [17.740–19.054] |
| large | grid3x3 | path | 7072.096 [6896.443–7134.729] | 39.430 [36.909–42.599] | 13.552 [13.249–14.307] |
| large | grid3x3 | image | 6971.985 [6949.491–7306.749] | 86.444 [82.204–93.642] | 58.004 [56.803–59.298] |
| large | grid4x4 | path | 12484.787 [12380.238–12568.370] | 65.800 [65.129–80.353] | 20.954 [20.184–21.798] |
| large | grid4x4 | image | 12777.947 [12534.434–12937.324] | 190.053 [185.844–230.549] | 144.462 [140.892–146.449] |
| large | donut | path | 4361.276 [4300.282–4375.830] | 24.291 [23.683–25.139] | 6.154 [5.926–11.131] |
| large | donut | image | 4875.411 [4763.440–4993.131] | 382.498 [371.347–462.578] | 364.587 [358.756–374.138] |
| large | diagonalStripes | path | 12294.256 [12075.579–12379.623] | 65.041 [63.709–78.034] | 13.157 [12.695–13.315] |
| large | diagonalStripes | image | 12906.573 [12850.701–13090.738] | 782.692 [774.571–898.521] | 738.476 [723.166–781.769] |
| large | abstract | path | 1512.075 [1501.155–1615.610] | 11.982 [11.445–12.247] | 7.776 [7.441–9.283] |
| large | abstract | image | 1600.446 [1565.916–1704.336] | 66.309 [63.241–68.195] | 60.927 [59.096–70.143] |
| large | roundedPath | path | 2400.291 [2390.901–2489.575] | 14.793 [14.700–15.033] | 11.511 [11.371–11.870] |
| large | roundedPath | image | 2449.491 [2404.289–2541.048] | 43.291 [42.986–43.831] | 40.129 [39.681–41.413] |
| large | blob | path | 4635.114 [4522.652–4791.508] | 16.454 [16.299–17.924] | 11.853 [11.797–12.157] |
| large | blob | image | 4589.168 [4570.893–4879.375] | 71.528 [70.878–72.779] | 67.458 [66.540–71.617] |
| large | circuit | path | 5788.951 [5632.224–6097.949] | 34.932 [32.771–37.309] | 8.848 [8.637–9.702] |
| large | circuit | image | 5960.349 [5794.517–6288.530] | 262.352 [243.402–284.216] | 226.175 [220.808–242.238] |
| large | dripHorizontal | path | 3921.791 [3837.693–3993.874] | 24.133 [21.604–31.770] | 6.768 [6.450–8.116] |
| large | dripHorizontal | image | 3912.983 [3862.125–4208.693] | 153.583 [137.732–177.077] | 134.378 [123.702–141.125] |
| large | dripVertical | path | 3649.562 [3575.549–3696.397] | 22.278 [20.926–23.988] | 6.416 [6.342–6.722] |
| large | dripVertical | image | 3777.832 [3750.291–3807.653] | 133.560 [124.819–157.092] | 112.280 [109.995–126.270] |
| large | crosshatch | path | 5320.349 [5240.646–5363.109] | 31.870 [30.683–37.992] | 8.665 [8.343–9.000] |
| large | crosshatch | image | 5613.548 [5471.942–5685.649] | 351.750 [323.059–391.996] | 316.486 [309.946–321.057] |
| large | curvePixel | path | 1100.280 [1092.922–1145.934] | 8.980 [8.828–9.845] | 6.925 [6.660–7.377] |
| large | curvePixel | image | 1144.526 [1116.138–1247.682] | 32.514 [31.195–34.782] | 30.322 [29.220–31.608] |
| large | pointy | path | 672.843 [655.615–777.751] | 4.681 [4.565–4.919] | 4.288 [4.211–4.665] |
| large | pointy | image | 676.930 [660.548–778.602] | 8.195 [7.906–8.349] | 7.743 [7.541–8.140] |
| large | razor | path | 2782.646 [2737.922–2950.187] | 12.990 [12.795–14.031] | 8.219 [8.070–8.803] |
| large | razor | image | 2856.414 [2799.995–2984.590] | 57.074 [56.040–61.051] | 52.113 [51.681–58.518] |
| large | roundedEndIndent | path | 1101.150 [1063.876–1165.023] | 9.699 [9.393–15.840] | 7.399 [7.271–9.174] |
| large | roundedEndIndent | image | 1105.428 [1090.641–1198.801] | 33.453 [30.819–44.549] | 30.140 [28.796–32.907] |
| large | vortex | path | 1431.165 [1405.072–1580.581] | 12.175 [11.540–17.015] | 8.297 [8.088–9.153] |
| large | vortex | image | 1473.840 [1442.216–1539.555] | 74.301 [50.636–118.248] | 56.172 [48.853–62.509] |
| large | horizontal | path | 4.114 [4.085–4.134] | 4.319 [4.064–4.482] | 4.188 [4.020–4.243] |
| large | horizontal | image | 21.043 [20.875–21.236] | 22.480 [20.573–24.245] | 22.168 [21.426–23.005] |
| large | vertical | path | 4.282 [4.261–4.347] | 4.522 [4.273–4.622] | 4.282 [4.245–4.325] |
| large | vertical | image | 52.770 [49.760–62.316] | 83.492 [51.356–128.896] | 53.405 [50.706–61.022] |
