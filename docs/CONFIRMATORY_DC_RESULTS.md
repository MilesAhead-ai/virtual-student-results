# Confirmatory DC: results (2026-11-07)

Pre-registration: `PREREGISTRATION_CONFIRMATORY_DC.md`, frozen 2026-11-06 (tag `confirmatory-dc-frozen`,
code `8f5cef2`). All 72 runs completed: 0 failures, 0 retries, no server faults (queue log
`results/olmo3sft_grpo_confirmatory_dc/queue.log`; 05:55 on 11-06 to 12:03 on 11-07 UTC). E2 metrics
were not read until the queue logged `END done=72`. The analysis is `scripts/confirmatory_dc_analysis.py`
(sha256 `43365d48…`, as frozen), run once. Output:
`results/olmo3sft_grpo_confirmatory_dc/analysis/confirmatory_dc_analysis.json`.

## Hypotheses (final E2 accuracy after 40 updates, 600 items, seeds 200–223)

Initial E2 accuracy (same base model in every run): 0.775. Final, mean over seeds: **R 0.8099, PP16
0.8203, PJ 0.8189.**

| hypothesis | mean Δ | seed sd | 95% t-interval | p | p (Holm) | positive seeds | result |
|---|---|---|---|---|---|---|---|
| **H1: PP16 − PJ** (panel b vs Opus rating) | **+0.0014** | 0.0139 | **[−0.0045, +0.0073]** | 0.63 | 0.63 | 10/24 | **not supported** |
| H2: PP16 − R | **+0.0104** | 0.0126 | **[+0.0051, +0.0157]** | 0.0005 | 0.0014 | 20/24 | **supported** |
| H3: PJ − R | **+0.0090** | 0.0123 | **[+0.0038, +0.0142]** | 0.0015 | 0.0030 | 20/24 | **supported** |

Secondary (not decisive): item bootstrap of H1 with seeds fixed [−0.0036, +0.0065].

## Exploratory (no confirmatory claim)

- **Final S** agrees: PP16 − PJ −0.0009 [−0.006, +0.004]; PP16 − R +0.0146 [+0.009, +0.020];
  PJ − R +0.0155 [+0.009, +0.022].
- **What was selected.** Panel b of chosen items by quarter: PP16 +0.73 / +0.67 / +0.68 / +0.73;
  PJ +0.54 / +0.47 / +0.49 / +0.50; R ≈ 0. By the panel's measure PJ trains on easier items, as in
  development, and it does not matter for the outcome.
- **Arms.** Accuracy among parseable answers on E2 rises +0.033 (PP16), +0.032 (PJ), +0.023 (R).
  Gradient-bearing groups in the last 10 updates: PP16 0.66, PJ 0.61, R 0.53. Runs with final answers
  under 350 characters: PP16 8/24, PJ 9/24, R 3/24.
- **Per skill** (60 items each, noisy): PP16 − PJ ranges from −0.023 (form_structure_sense) to +0.014
  (boundaries), with no consistent pattern.

## Conclusion

In this setting (OLMo-3-7B, outcome-only GRPO, 40 updates, pool v2), **targeting training items to the
student's level helps, whichever of the two difficulty estimates is used**: both PanelProbe's calibrated
panel difficulty (+1.0 point over random, CI +0.5 to +1.6) and a single strong model's direct rating
mapped to the same scale (+0.9, CI +0.4 to +1.4) beat random selection. **The panel's calibration did
not add measurably to training**: PP16 − PJ is +0.1 point, and the interval rules out an advantage larger
than about +0.7 point. This holds even though the panel's difficulty predicts the student's wrong answers
clearly better than the rating does (offline AUC 0.764 vs 0.698, FINDINGS #26).

What the result does and does not say:
- It does not show that the single-model rating is as good a difficulty measure: it is not, offline.
  It shows that, for choosing items under this targeting rule, the ranking errors of the rating cost
  little learning.
- PJ borrowed the panel's difficulty distribution through the quantile mapping (§10 of the
  pre-registration): the rating supplied only the order of items within a skill. A single-model rating
  without a panel would need its own way to place items on the student's scale.
- The development estimate (+0.0095 on S with 4 seeds) did not replicate; it was within its wide
  interval. The confirmed PP16 − R effect (+0.010) is about half of confirmatory v1's PP − R (+0.019 on
  E1, pool v1); E2 starts easier for the student (0.775 initial accuracy vs 0.69 on E1).

## Notes added after the study (not part of the pre-registered analysis)

- **2026-11-08, exploratory (FINDINGS #29).** Recalibrating pool v2 with only the 8 small local models of
  panel v1 gives practically the same difficulty as panel v2 (within-skill rank correlation 0.964) and
  the same offline validity (AUC 0.762–0.763 vs 0.764), better than the Opus 5.5 rating on every skill.
  This suggests, but does not show, that the PP16 arm behaved like a small-model panel: the study tested
  panel v2, and the small-panel reading rests on an exploratory rank correlation. *(Wording corrected
  2026-11-11 after the audit, FINDINGS #31.)*
- **2026-11-09, development follow-up (FINDINGS #30; criteria written before the runs).** Two more arms
  on S, seeds 0–3, 100 updates: PP16 on the 8-small-model panel alone (PS), and on the Opus rating with
  no panel information at all (PJ-raw, b = ln((100 − p)/p)). vs R at u40: PS +0.020, PP16 +0.017, PJ-raw
  +0.011, PJ +0.007; AULC +0.004 / +0.006 / +0.005 / +0.001. The small panel alone does about as well as
  the full panel; the panel-free rating is not worse than the mapped one, so there is no evidence that the
  panel's scale is what makes the rating work (a 4-seed null). All four targeting arms are within noise of
  each other. Two of the four PJ-raw runs stopped writing reasoning (FINDINGS #30, corrected).
