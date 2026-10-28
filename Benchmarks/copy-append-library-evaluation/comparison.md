# Release comparison: copy-and-append versus elements

Same unchanged harness, machine, software, dependency pins, fixtures and settings.
Fresh runs alternate elements/copy/elements/copy. Each run uses one warm-up and
five measured samples per operation. Tables pool ten samples per implementation.
Times are milliseconds; speedup is elements ÷ copy (greater than 1 is faster).

| Run | Started (Los Angeles) | Raw samples | Reconstructable source |
| --- | --- | --- | --- |
| elements-1 | 2026-10-28 04:37:47 PDT | [JSON](elements-1.json) | [Snapshot](elements-1.json.source-state.json) |
| copy-1 | 2026-10-28 04:38:57 PDT | [JSON](copy-1.json) | [Snapshot](copy-1.json.source-state.json) |
| elements-2 | 2026-10-28 04:40:07 PDT | [JSON](elements-2.json) | [Snapshot](elements-2.json.source-state.json) |
| copy-2 | 2026-10-28 04:41:17 PDT | [JSON](copy-2.json) | [Snapshot](copy-2.json.source-state.json) |

## Repeatability check

6 case/operation combinations were more than 5% slower for copy in both adjacent pairs.
This is a descriptive noise screen, not a statistical significance claim.
The three unchanged styles (roundedRect, horizontal, vertical) are controls.

| Fixture | Style | Operation | Pair 1 change | Pair 2 change | Pooled delta (ms) |
| --- | --- | --- | ---: | ---: | ---: |
| small | flower | path | +24.9% | +22.8% | +0.0444 |
| small | gear | path | +12.8% | +5.9% | +0.0364 |
| medium | flower | path | +26.2% | +21.5% | +0.6185 |
| large | flower | path | +22.1% | +24.0% | +2.1590 |
| large | gear | path | +6.1% | +13.1% | +1.3956 |
| large | vertical | image | +8.5% | +17.8% | +12.0952 |

## Small

| Style | Elements path | Copy path | Path speedup | Elements image | Copy image | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| square | 0.1065 | 0.0747 | 1.42× | 0.4637 | 0.4076 | 1.14× |
| circle | 0.1425 | 0.0834 | 1.71× | 1.0357 | 1.0025 | 1.03× |
| squircle | 0.1288 | 0.1191 | 1.08× | 1.9171 | 1.9874 | 0.96× |
| flower | 0.1924 | 0.2367 | 0.81× | 3.1803 | 3.3751 | 0.94× |
| gear | 0.3743 | 0.4107 | 0.91× | 3.2630 | 3.2370 | 1.01× |
| roundedRect | 0.1833 | 0.1866 | 0.98× | 1.2139 | 1.3468 | 0.90× |
| grid2x2 | 0.1707 | 0.0949 | 1.80× | 0.7197 | 0.6279 | 1.15× |
| grid3x3 | 0.2928 | 0.1571 | 1.86× | 1.1638 | 1.0366 | 1.12× |
| grid4x4 | 0.4105 | 0.2535 | 1.62× | 1.5599 | 1.3946 | 1.12× |
| donut | 0.1342 | 0.1292 | 1.04× | 2.0681 | 1.9841 | 1.04× |
| diagonalStripes | 0.2858 | 0.2725 | 1.05× | 3.6974 | 3.7115 | 1.00× |
| abstract | 0.1658 | 0.1438 | 1.15× | 1.5946 | 1.6089 | 0.99× |
| roundedPath | 0.2859 | 0.2508 | 1.14× | 1.4526 | 1.4522 | 1.00× |
| blob | 0.2848 | 0.2406 | 1.18× | 1.7821 | 1.8316 | 0.97× |
| circuit | 0.1993 | 0.2068 | 0.96× | 2.5107 | 2.5521 | 0.98× |
| dripHorizontal | 0.1394 | 0.1363 | 1.02× | 1.8703 | 1.8449 | 1.01× |
| dripVertical | 0.1356 | 0.1386 | 0.98× | 1.6624 | 1.7394 | 0.96× |
| crosshatch | 0.1959 | 0.1956 | 1.00× | 3.4882 | 3.3582 | 1.04× |
| curvePixel | 0.1633 | 0.1241 | 1.32× | 1.2227 | 1.1612 | 1.05× |
| pointy | 0.0989 | 0.0640 | 1.55× | 0.5645 | 0.5341 | 1.06× |
| razor | 0.2067 | 0.1632 | 1.27× | 1.7046 | 1.6984 | 1.00× |
| roundedEndIndent | 0.1902 | 0.1511 | 1.26× | 1.1863 | 1.1262 | 1.05× |
| vortex | 0.1879 | 0.1591 | 1.18× | 1.0221 | 0.9823 | 1.04× |
| horizontal | 0.1055 | 0.1079 | 0.98× | 0.8003 | 0.8120 | 0.99× |
| vertical | 0.1075 | 0.1073 | 1.00× | 0.9185 | 0.9179 | 1.00× |

## Medium

| Style | Elements path | Copy path | Path speedup | Elements image | Copy image | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| square | 1.2479 | 0.8317 | 1.50× | 2.2463 | 1.7950 | 1.25× |
| circle | 1.6868 | 0.9932 | 1.70× | 22.1866 | 22.7590 | 0.97× |
| squircle | 1.6850 | 1.5064 | 1.12× | 25.5280 | 25.6600 | 0.99× |
| flower | 2.5235 | 3.1421 | 0.80× | 102.0422 | 104.3920 | 0.98× |
| gear | 4.9883 | 5.2801 | 0.94× | 122.4991 | 122.2058 | 1.00× |
| roundedRect | 2.2761 | 2.2419 | 1.02× | 11.9717 | 11.7809 | 1.02× |
| grid2x2 | 2.0635 | 1.2065 | 1.71× | 5.1512 | 4.4597 | 1.16× |
| grid3x3 | 3.8001 | 2.0983 | 1.81× | 13.0743 | 13.3252 | 0.98× |
| grid4x4 | 5.2461 | 3.1250 | 1.68× | 19.1506 | 17.5708 | 1.09× |
| donut | 1.6321 | 1.6130 | 1.01× | 51.5507 | 51.3344 | 1.00× |
| diagonalStripes | 3.4476 | 3.2660 | 1.06× | 85.6739 | 85.7624 | 1.00× |
| abstract | 2.0582 | 1.7314 | 1.19× | 12.9035 | 12.5638 | 1.03× |
| roundedPath | 3.2410 | 2.6409 | 1.23× | 13.0609 | 12.1479 | 1.08× |
| blob | 3.3201 | 2.6067 | 1.27× | 18.1063 | 17.1558 | 1.06× |
| circuit | 2.4200 | 2.5396 | 0.95× | 45.9326 | 46.7244 | 0.98× |
| dripHorizontal | 1.7360 | 1.6989 | 1.02× | 30.2969 | 30.0265 | 1.01× |
| dripVertical | 1.7712 | 1.7486 | 1.01× | 28.4483 | 29.1616 | 0.98× |
| crosshatch | 2.2929 | 2.4004 | 0.96× | 52.8436 | 52.9716 | 1.00× |
| curvePixel | 1.8540 | 1.4005 | 1.32× | 8.6060 | 8.1673 | 1.05× |
| pointy | 1.1957 | 0.7580 | 1.58× | 2.7130 | 2.2291 | 1.22× |
| razor | 2.3257 | 1.7746 | 1.31× | 15.2571 | 14.7070 | 1.04× |
| roundedEndIndent | 2.1048 | 1.6255 | 1.29× | 9.2044 | 8.8098 | 1.04× |
| vortex | 2.2212 | 1.9003 | 1.17× | 11.8967 | 11.9544 | 1.00× |
| horizontal | 1.1350 | 1.1665 | 0.97× | 8.5940 | 8.8093 | 0.98× |
| vertical | 1.2081 | 1.2126 | 1.00× | 15.0501 | 15.7007 | 0.96× |

## Large

| Style | Elements path | Copy path | Path speedup | Elements image | Copy image | Image speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| square | 4.5181 | 3.1022 | 1.46× | 6.9016 | 5.6202 | 1.23× |
| circle | 6.2464 | 3.4999 | 1.78× | 61.2942 | 58.1949 | 1.05× |
| squircle | 5.8351 | 5.1994 | 1.12× | 293.5687 | 288.6877 | 1.02× |
| flower | 9.1738 | 11.3328 | 0.81× | 447.7824 | 456.2876 | 0.98× |
| gear | 18.1195 | 19.5151 | 0.93× | 791.7806 | 802.9986 | 0.99× |
| roundedRect | 7.9602 | 7.8231 | 1.02× | 89.9253 | 88.5494 | 1.02× |
| grid2x2 | 7.5588 | 4.2585 | 1.77× | 18.3197 | 14.9727 | 1.22× |
| grid3x3 | 13.6240 | 7.6035 | 1.79× | 58.0728 | 51.7082 | 1.12× |
| grid4x4 | 19.0705 | 11.7580 | 1.62× | 144.0775 | 134.3509 | 1.07× |
| donut | 6.0165 | 5.9236 | 1.02× | 373.4993 | 365.2331 | 1.02× |
| diagonalStripes | 12.9984 | 12.2072 | 1.06× | 740.1817 | 737.8597 | 1.00× |
| abstract | 7.4252 | 6.3038 | 1.18× | 59.7288 | 59.0489 | 1.01× |
| roundedPath | 11.5133 | 9.4825 | 1.21× | 40.4964 | 39.3558 | 1.03× |
| blob | 12.1300 | 9.5635 | 1.27× | 68.3302 | 66.5935 | 1.03× |
| circuit | 8.6709 | 9.1176 | 0.95× | 222.8647 | 223.8189 | 1.00× |
| dripHorizontal | 6.4927 | 6.4274 | 1.01× | 125.8892 | 128.9891 | 0.98× |
| dripVertical | 6.5045 | 6.6636 | 0.98× | 116.9845 | 116.3575 | 1.01× |
| crosshatch | 8.7961 | 8.8539 | 0.99× | 316.9378 | 316.2339 | 1.00× |
| curvePixel | 6.6587 | 5.3914 | 1.24× | 29.7352 | 30.0742 | 0.99× |
| pointy | 4.3281 | 2.9790 | 1.45× | 7.6698 | 6.5853 | 1.16× |
| razor | 8.6517 | 6.5648 | 1.32× | 55.3559 | 51.4931 | 1.08× |
| roundedEndIndent | 7.6315 | 5.8031 | 1.32× | 31.3076 | 27.7764 | 1.13× |
| vortex | 8.0810 | 6.8459 | 1.18× | 53.4902 | 49.7285 | 1.08× |
| horizontal | 4.1243 | 4.0801 | 1.01× | 21.3017 | 21.4865 | 0.99× |
| vertical | 4.3018 | 4.3739 | 0.98× | 52.3373 | 64.4325 | 0.81× |

## Historical original and batching references

These original and batching measurements were retained from the earlier investigation,
not rerun in this alternating experiment. Metadata/harness/fixtures/settings match, but
the time separation means small differences must not be treated as causal evidence.

| Large style | Original path | Batching path | Copy path | Original image | Batching image | Copy image |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| square | 645.0341 | 4.8004 | 3.1022 | 637.4118 | 7.4321 | 5.6202 |
| circle | 1792.2789 | 11.3125 | 3.4999 | 1862.3595 | 64.9692 | 58.1949 |
| squircle | 3331.7329 | 19.2571 | 5.1994 | 3608.1315 | 305.9827 | 288.6877 |
| flower | 8930.2294 | 50.2188 | 11.3328 | 9383.2485 | 483.9834 | 456.2876 |
| gear | 19074.8065 | 102.8287 | 19.5151 | 20088.4975 | 881.3076 | 802.9986 |
| roundedRect | 8.0832 | 9.3022 | 7.8231 | 91.5365 | 88.3313 | 88.5494 |
| grid2x2 | 3067.3138 | 17.4205 | 4.2585 | 3101.8333 | 28.5895 | 14.9727 |
| grid3x3 | 7072.0960 | 39.4300 | 7.6035 | 6971.9847 | 86.4444 | 51.7082 |
| grid4x4 | 12484.7868 | 65.8004 | 11.7580 | 12777.9474 | 190.0533 | 134.3509 |
| donut | 4361.2759 | 24.2915 | 5.9236 | 4875.4113 | 382.4979 | 365.2331 |
| diagonalStripes | 12294.2559 | 65.0414 | 12.2072 | 12906.5726 | 782.6917 | 737.8597 |
| abstract | 1512.0749 | 11.9823 | 6.3038 | 1600.4462 | 66.3088 | 59.0489 |
| roundedPath | 2400.2913 | 14.7928 | 9.4825 | 2449.4909 | 43.2909 | 39.3558 |
| blob | 4635.1144 | 16.4536 | 9.5635 | 4589.1679 | 71.5276 | 66.5935 |
| circuit | 5788.9510 | 34.9317 | 9.1176 | 5960.3485 | 262.3525 | 223.8189 |
| dripHorizontal | 3921.7907 | 24.1332 | 6.4274 | 3912.9833 | 153.5834 | 128.9891 |
| dripVertical | 3649.5617 | 22.2782 | 6.6636 | 3777.8317 | 133.5602 | 116.3575 |
| crosshatch | 5320.3493 | 31.8703 | 8.8539 | 5613.5485 | 351.7497 | 316.2339 |
| curvePixel | 1100.2802 | 8.9801 | 5.3914 | 1144.5263 | 32.5143 | 30.0742 |
| pointy | 672.8432 | 4.6808 | 2.9790 | 676.9297 | 8.1948 | 6.5853 |
| razor | 2782.6458 | 12.9898 | 6.5648 | 2856.4142 | 57.0736 | 51.4931 |
| roundedEndIndent | 1101.1501 | 9.6993 | 5.8031 | 1105.4278 | 33.4532 | 27.7764 |
| vortex | 1431.1652 | 12.1748 | 6.8459 | 1473.8404 | 74.3009 | 49.7285 |
| horizontal | 4.1139 | 4.3188 | 4.0801 | 21.0433 | 22.4798 | 21.4865 |
| vertical | 4.2815 | 4.5219 | 4.3739 | 52.7700 | 83.4915 | 64.4325 |

## Sample ranges

| Fixture | Style | Operation | Elements min–max | Copy min–max |
| --- | --- | --- | ---: | ---: |
| small | square | path | 0.1008–0.1118 | 0.0723–0.0783 |
| small | square | image | 0.4075–0.5036 | 0.3927–0.4413 |
| small | circle | path | 0.1348–0.1496 | 0.0797–0.0923 |
| small | circle | image | 0.9772–1.2155 | 0.9322–1.3991 |
| small | squircle | path | 0.1282–0.1550 | 0.1165–0.1518 |
| small | squircle | image | 1.8810–2.1139 | 1.8633–2.2098 |
| small | flower | path | 0.1907–0.2057 | 0.2320–0.3057 |
| small | flower | image | 3.0091–3.3626 | 3.0356–3.8242 |
| small | gear | path | 0.3637–0.3916 | 0.4010–0.4346 |
| small | gear | image | 3.1153–3.4196 | 3.1549–3.6705 |
| small | roundedRect | path | 0.1775–0.2144 | 0.1770–0.2588 |
| small | roundedRect | image | 1.1803–1.5573 | 1.1583–1.4109 |
| small | grid2x2 | path | 0.1620–0.1958 | 0.0932–0.0962 |
| small | grid2x2 | image | 0.6972–0.9394 | 0.6019–0.6553 |
| small | grid3x3 | path | 0.2862–0.3025 | 0.1557–0.1661 |
| small | grid3x3 | image | 1.1251–1.2403 | 0.9799–1.1973 |
| small | grid4x4 | path | 0.3980–0.4233 | 0.2443–0.2794 |
| small | grid4x4 | image | 1.4820–1.8035 | 1.3290–1.6867 |
| small | donut | path | 0.1265–0.1573 | 0.1247–0.1560 |
| small | donut | image | 1.8993–2.2751 | 1.9392–2.3056 |
| small | diagonalStripes | path | 0.2767–0.3338 | 0.2605–0.2916 |
| small | diagonalStripes | image | 3.6116–4.0445 | 3.6145–4.2005 |
| small | abstract | path | 0.1636–0.1744 | 0.1350–0.1480 |
| small | abstract | image | 1.5263–1.9158 | 1.5240–1.7870 |
| small | roundedPath | path | 0.2777–0.3020 | 0.2344–0.2945 |
| small | roundedPath | image | 1.4105–1.6250 | 1.3805–1.5732 |
| small | blob | path | 0.2815–0.3159 | 0.2260–0.2542 |
| small | blob | image | 1.6901–2.0023 | 1.6496–1.9919 |
| small | circuit | path | 0.1945–0.2102 | 0.2002–0.2815 |
| small | circuit | image | 2.4278–2.8702 | 2.4231–2.7878 |
| small | dripHorizontal | path | 0.1345–0.1748 | 0.1320–0.1439 |
| small | dripHorizontal | image | 1.7683–2.0154 | 1.8140–1.9071 |
| small | dripVertical | path | 0.1340–0.1631 | 0.1330–0.1591 |
| small | dripVertical | image | 1.6134–1.8602 | 1.6390–1.9136 |
| small | crosshatch | path | 0.1898–0.2096 | 0.1878–0.2507 |
| small | crosshatch | image | 3.3254–3.6591 | 3.3078–3.7784 |
| small | curvePixel | path | 0.1547–0.1688 | 0.1204–0.1289 |
| small | curvePixel | image | 1.1614–1.3513 | 1.1160–1.3027 |
| small | pointy | path | 0.0960–0.1046 | 0.0627–0.0667 |
| small | pointy | image | 0.5329–0.7100 | 0.5052–0.6020 |
| small | razor | path | 0.2037–0.2818 | 0.1577–0.1789 |
| small | razor | image | 1.6565–1.8476 | 1.5962–1.8682 |
| small | roundedEndIndent | path | 0.1832–0.2365 | 0.1468–0.1581 |
| small | roundedEndIndent | image | 1.1358–1.2845 | 1.1019–1.1904 |
| small | vortex | path | 0.1779–0.2058 | 0.1551–0.1740 |
| small | vortex | image | 0.9840–1.1530 | 0.9529–1.0779 |
| small | horizontal | path | 0.1030–0.1122 | 0.1045–0.1291 |
| small | horizontal | image | 0.7494–0.9796 | 0.7699–1.0055 |
| small | vertical | path | 0.1038–0.1219 | 0.1033–0.1180 |
| small | vertical | image | 0.8763–1.0751 | 0.8583–1.1635 |
| medium | square | path | 1.2075–1.2977 | 0.8117–0.9299 |
| medium | square | image | 2.1659–2.4088 | 1.7461–1.9756 |
| medium | circle | path | 1.6534–1.8567 | 0.9225–1.0821 |
| medium | circle | image | 21.7824–23.4290 | 22.3082–23.4156 |
| medium | squircle | path | 1.6097–1.7766 | 1.4513–1.5837 |
| medium | squircle | image | 24.3860–26.3148 | 24.4009–26.7490 |
| medium | flower | path | 2.4535–2.7572 | 2.9395–3.3835 |
| medium | flower | image | 100.7689–105.3397 | 101.2274–106.2600 |
| medium | gear | path | 4.7647–5.8013 | 5.1490–5.7589 |
| medium | gear | image | 119.8535–126.3508 | 119.9827–126.7517 |
| medium | roundedRect | path | 2.2132–2.4070 | 2.2160–2.5964 |
| medium | roundedRect | image | 11.5379–12.9825 | 11.1889–12.6110 |
| medium | grid2x2 | path | 1.9852–2.1694 | 1.1129–1.4965 |
| medium | grid2x2 | image | 5.0220–5.5106 | 4.2105–5.6444 |
| medium | grid3x3 | path | 3.7200–3.9467 | 1.9926–2.3581 |
| medium | grid3x3 | image | 12.3466–14.4815 | 11.1120–21.6365 |
| medium | grid4x4 | path | 5.0244–5.4324 | 3.0310–3.2930 |
| medium | grid4x4 | image | 18.3923–19.9383 | 16.2277–22.7151 |
| medium | donut | path | 1.5958–1.7064 | 1.5625–1.7493 |
| medium | donut | image | 50.2993–52.7775 | 50.5551–54.7043 |
| medium | diagonalStripes | path | 3.3833–3.7012 | 3.2100–3.6431 |
| medium | diagonalStripes | image | 84.6240–88.8881 | 84.5658–89.0392 |
| medium | abstract | path | 2.0035–2.1641 | 1.6864–1.8632 |
| medium | abstract | image | 12.5100–13.8082 | 12.1268–14.0970 |
| medium | roundedPath | path | 3.1516–3.3468 | 2.6065–2.8323 |
| medium | roundedPath | image | 12.2832–13.7325 | 11.7913–12.4395 |
| medium | blob | path | 3.2620–3.4635 | 2.5451–2.7719 |
| medium | blob | image | 17.3557–18.9745 | 16.6594–17.8631 |
| medium | circuit | path | 2.3385–2.5499 | 2.4578–2.6165 |
| medium | circuit | image | 44.7653–46.7385 | 45.1820–49.4072 |
| medium | dripHorizontal | path | 1.7134–1.8476 | 1.6786–2.0812 |
| medium | dripHorizontal | image | 29.8035–31.9471 | 29.6695–30.4835 |
| medium | dripVertical | path | 1.7094–1.8147 | 1.6958–1.8425 |
| medium | dripVertical | image | 27.8643–29.8193 | 27.9866–29.9503 |
| medium | crosshatch | path | 2.2593–2.3777 | 2.3420–2.4678 |
| medium | crosshatch | image | 51.4077–53.8847 | 52.1482–54.9023 |
| medium | curvePixel | path | 1.7967–2.0622 | 1.3741–1.6159 |
| medium | curvePixel | image | 8.3086–8.8730 | 7.8362–8.6028 |
| medium | pointy | path | 1.1565–1.2814 | 0.7333–0.7959 |
| medium | pointy | image | 2.5538–2.9514 | 2.1800–2.3195 |
| medium | razor | path | 2.2398–2.4060 | 1.7288–1.8948 |
| medium | razor | image | 14.8583–15.5272 | 14.2193–15.1013 |
| medium | roundedEndIndent | path | 1.9841–2.1822 | 1.5601–1.7453 |
| medium | roundedEndIndent | image | 8.8655–9.4188 | 8.5597–8.9940 |
| medium | vortex | path | 2.1669–2.4854 | 1.8555–2.0481 |
| medium | vortex | image | 11.6990–12.8693 | 11.0183–12.7268 |
| medium | horizontal | path | 1.1166–1.1918 | 1.1162–1.1936 |
| medium | horizontal | image | 8.0035–8.7899 | 8.0220–9.2437 |
| medium | vertical | path | 1.1683–1.3292 | 1.1714–1.2427 |
| medium | vertical | image | 13.5986–16.3628 | 13.9420–17.2022 |
| large | square | path | 4.4182–4.6946 | 2.9703–3.1256 |
| large | square | image | 6.7663–7.0977 | 5.4223–5.8818 |
| large | circle | path | 6.1830–6.5479 | 3.4130–3.6344 |
| large | circle | image | 60.2266–63.4093 | 57.5688–59.9994 |
| large | squircle | path | 5.7202–6.1968 | 5.1422–5.6425 |
| large | squircle | image | 290.1596–302.7261 | 287.1135–296.1161 |
| large | flower | path | 9.0469–9.9071 | 10.9313–12.0936 |
| large | flower | image | 441.5647–462.8337 | 450.1398–469.3865 |
| large | gear | path | 17.4607–28.4006 | 19.3754–21.1040 |
| large | gear | image | 785.7211–876.3181 | 789.9877–818.5555 |
| large | roundedRect | path | 7.7429–8.3376 | 7.7360–8.1114 |
| large | roundedRect | image | 86.6770–94.8297 | 87.4845–91.3337 |
| large | grid2x2 | path | 7.3183–7.7630 | 4.1015–4.3925 |
| large | grid2x2 | image | 17.4927–19.1359 | 14.4772–15.4802 |
| large | grid3x3 | path | 13.1443–13.9663 | 7.3903–7.7137 |
| large | grid3x3 | image | 56.1676–59.5042 | 50.5980–53.5040 |
| large | grid4x4 | path | 18.4629–20.5842 | 11.3088–12.2637 |
| large | grid4x4 | image | 141.9731–161.3735 | 130.4853–141.2973 |
| large | donut | path | 5.8823–6.9259 | 5.7862–6.4705 |
| large | donut | image | 361.6301–395.8302 | 362.1157–380.9730 |
| large | diagonalStripes | path | 12.6240–13.5981 | 11.9413–14.4223 |
| large | diagonalStripes | image | 710.7623–752.2131 | 726.1733–773.7075 |
| large | abstract | path | 7.3803–7.8761 | 6.1307–6.5195 |
| large | abstract | image | 58.8796–61.7132 | 57.8267–61.5737 |
| large | roundedPath | path | 11.2592–12.0975 | 9.2624–9.8689 |
| large | roundedPath | image | 39.4200–42.0811 | 38.1130–40.5666 |
| large | blob | path | 11.8587–12.6617 | 9.3129–9.9679 |
| large | blob | image | 66.0831–71.5240 | 65.8480–69.0640 |
| large | circuit | path | 8.5817–9.4008 | 8.9862–10.0516 |
| large | circuit | image | 220.2055–225.2358 | 221.3056–230.9182 |
| large | dripHorizontal | path | 6.3330–6.8100 | 6.2380–7.1061 |
| large | dripHorizontal | image | 122.3576–130.3724 | 124.6170–140.1325 |
| large | dripVertical | path | 6.3561–6.7714 | 6.3043–6.8441 |
| large | dripVertical | image | 113.4436–120.6158 | 114.4488–120.4163 |
| large | crosshatch | path | 8.4252–9.4754 | 8.6001–9.3183 |
| large | crosshatch | image | 309.0778–335.2813 | 309.8112–331.1043 |
| large | curvePixel | path | 6.5741–6.9141 | 5.2240–5.6482 |
| large | curvePixel | image | 28.6026–31.6340 | 29.4712–30.8570 |
| large | pointy | path | 4.2248–4.5230 | 2.7933–3.0550 |
| large | pointy | image | 7.4678–8.7363 | 6.1813–6.8396 |
| large | razor | path | 8.1245–8.9653 | 6.2701–6.8350 |
| large | razor | image | 54.1642–57.2587 | 51.0627–53.1315 |
| large | roundedEndIndent | path | 7.2593–7.9586 | 5.6823–5.9843 |
| large | roundedEndIndent | image | 30.3942–32.4282 | 27.5474–29.3240 |
| large | vortex | path | 7.9289–8.2882 | 6.7302–6.8980 |
| large | vortex | image | 45.9992–70.2358 | 47.7327–58.5391 |
| large | horizontal | path | 4.0085–4.3889 | 4.0390–4.2465 |
| large | horizontal | image | 20.4220–22.8065 | 20.9814–23.5672 |
| large | vertical | path | 4.2482–4.3946 | 4.2761–4.5424 |
| large | vertical | image | 48.1058–63.4661 | 55.2285–75.6411 |
