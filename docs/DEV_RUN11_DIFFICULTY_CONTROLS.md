# Dev run 11: panel-calibrated difficulty vs a single model's rating (2026-11-05)

Plan: `PLAN_SINGLE_MODEL_CONTROL.md` (E19). Two new arms on pool v2, seeds 0–3, 100 updates, otherwise
identical to DEV_RUN10 (OLMo-3, outcome GRPO, lr 2e-4, KL 0.05, θ₀ 1.0, parser v2, S and D every 5 updates):
- **PJ:** PP16 on Claude Opus 5.5's difficulty rating, quantile-mapped onto the panel b distribution within
  each skill (calibration `pool-v2-opus55q`). Only the ordering of items differs from PP16.
- **L:** the spec's staircase over generator labels (the difficulty the generator was asked to write).

Compared with DEV_RUN10's R and PP16 (same seeds). All 8 runs completed (0 failures).
Analysis: `results/olmo3sft_grpo_pool_v2_controls/analysis/controls_vs_r_pp16.txt`.

## Offline first (FINDINGS #26)

On R's random picks (12,739 presentations), AUC for predicting a wrong answer within skill × quarter:
panel b **0.764**, Opus rating 0.698, generator label 0.614. The panel leads on all 10 skills.

## Training result

Mean S accuracy (parser v2):

| update | 20 | 40 | 60 | 80 | 100 |
|---|---|---|---|---|---|
| R | 0.711 | 0.724 | 0.750 | 0.761 | 0.761 |
| L | 0.709 | 0.725 | 0.740 | 0.764 | 0.770 |
| PJ (Opus rating) | 0.712 | 0.731 | 0.745 | 0.756 | 0.771 |
| **PP16 (panel b)** | 0.716 | **0.741** | 0.757 | 0.772 | 0.772 |

Contrasts (t-interval over 4 seeds, positive seeds):

| | u40 | u80 | u100 | AULC |
|---|---|---|---|---|
| **PP16 − R** | **+0.017** [+0.002, +0.032] 4/4 | +0.011 [−0.010, +0.032] | +0.012 | +0.006 [−0.011, +0.022] |
| PJ − R | +0.007 [−0.008, +0.023] 3/4 | −0.005 [−0.036, +0.026] | +0.010 | +0.001 [−0.012, +0.014] |
| L − R | +0.001 [−0.026, +0.028] 3/4 | +0.003 | +0.009 | +0.001 [−0.014, +0.015] |
| PP16 − PJ | +0.010 [−0.015, +0.034] 3/4 | +0.016 [−0.011, +0.044] 3/4 | +0.001 | +0.005 [−0.014, +0.024] 2/4 |

- **Only the panel-calibrated arm has a clear early advantage over random** (u40 +0.017, 4/4 seeds, CI
  above 0). With Opus's rating the u40 gain is less than half (+0.007, CI includes 0); with generator
  labels there is none.
- **PP16 − PJ is positive at every checkpoint (3/4 seeds) but not significant with 4 seeds.** The
  direction matches the offline result; establishing it would need more seeds (a pre-registered study).
- By u100 all arms are within about one point of each other, as in DEV_RUN9/10.

## What the arms picked

Panel b of chosen items (mean, by quarter): PP16 +0.72 / +0.73 / +0.77 / +0.76; PJ +0.54 / +0.47 / +0.50
/ +0.45. PJ targets the same predicted success on its own scale, but the items it believes are in band
are, by the panel's measure, easier: its last-quarter greedy success is 0.704 (PP16 0.698), and the
share of picks predicted within ±0.1 of target (on its own scale) 0.61 → 0.26.

## Conclusion

Panel calibration predicts the student's outcomes better than a single strong model's judgement (offline,
all skills), and in training it is the only difficulty estimate whose early advantage over random
selection is clear. The head-to-head difference in training (PP16 − PJ) points the same way but is within
noise at 4 seeds.
