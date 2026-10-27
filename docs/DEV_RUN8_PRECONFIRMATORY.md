# Dev run 8: pre-confirmatory fixes, KL strength and tracker start (2026-10-27)

Before freezing a confirmatory configuration, the owner asked to settle the
two open issues from F10 (DEV_RUN7):

1. KL 0.05 does not reliably keep the reasoning (E8): 6 of 17 F10 runs
   shortened their answers below about 350 characters.
2. The ability tracker under-predicts the student, so PP's chosen items are
   answered about 60% correctly instead of the targeted 50%.

All runs: lr 2e-4 constant, slate 16, 40 updates, batch-invariant vLLM,
pool-v1-final; S is the primary set. One factor differs from F10 per
experiment. Experiments: `artifacts/olmo3sft_grpo_kl_strength/`,
`artifacts/olmo3sft_grpo_tracker_theta0/`, offline analysis in
`results/tracker_diagnosis/`.

## 1. KL strength (R, KL 0.1 and 0.2, seeds 3–6)

R only, because R's item stream does not depend on the tracker, which was
being changed at the same time. Seeds 3–6 pair with F10's KL 0.05 R runs,
two of which shortened (s5, s6). Table:
`results/olmo3sft_grpo_kl_strength/analysis/kl_comparison.txt`.

| KL | final S (mean) | Δ accuracy among parseable answers | answer length at u40 | runs < 350 chars at u40 | lowest mean length at any checkpoint | answers < 100 chars at u40 | gradient groups, last 10 | wall time |
|---|---|---|---|---|---|---|---|---|
| 0.05 (F10) | **0.7212** | **+0.027** | 510, 599, 335, 283 | **2/4** | 151–506 | 16.0% | 0.50 | ~198 min |
| 0.1 | 0.7103 | +0.017 | 533, 442, 441, 522 | **0/4** | 408–468 | 9.2% | 0.55 | ~210 min |
| 0.2 | 0.7048 | +0.014 | 559, 520, 517, 540 | 0/4 | 457–512 | 2.5% | 0.61 | ~219 min |

Paired by seed: KL 0.1 − KL 0.05 = −0.011 (t-CI df 3 [−0.024, +0.002]);
KL 0.2 − KL 0.05 = −0.016 ([−0.029, −0.003]).

- **KL 0.1 keeps the reasoning in all four seeds** (no checkpoint below 408
  characters) and keeps about 60% of KL 0.05's skill gain.
- **KL 0.2** is the most stable but learns about half as much. Final 0.705
  is barely above the untrained direct-answer baseline (0.687).
- A stronger KL keeps the policy more diverse (more gradient-bearing groups).
- Implication: a weaker learning signal shrinks the room for targeting
  (FINDINGS #6/#10). At KL 0.1 the PP − R effect is probably smaller than
  F10's +0.019. That is a guess; it was not measured.

## 2. Tracker start (θ₀)

### Offline diagnosis (no new runs)

`scripts/tracker_replay.py` replays the logged (skill, item, greedy outcome)
sequences of F10's R and PP runs through tracker variants and scores
one-step-ahead predictions. Results are in `results/tracker_diagnosis/`.

- **Main cause: the prior θ₀ = 0 is far below the student.** The first five
  observations of each skill are under-predicted by about 0.10, decaying to
  about 0.015 after 60 observations. θ₀ = 1.0 removes most of it (PP, first 20
  observations: +0.060 → +0.016), with slightly better predictive likelihood.
  This is a config value inside spec §12.
- Process variance 0.05 is a reasonable trade-off. Smaller values predict
  slightly better but lag the improving student.
- Shrinking the panel difficulties lowers PP's in-band gap but clearly
  worsens prediction. A fitted scale factor λ on b̂ has its likelihood
  optimum at λ = 1, so the panel's difficulty scale suits this student.
  Rejected.
- A guessing floor (4-option items: p = 0.25 + 0.75·σ) removes another
  ~1 point of in-band gap. It changes the spec §12 formula, so it would be
  a spec deviation.

### Validation (PP, θ₀ = 1.0, seeds 0–3, KL 0.05)

Compared with F10's PP (θ₀ = 0) and R on the same seeds. Table:
`results/olmo3sft_grpo_tracker_theta0/analysis/theta0_comparison.txt`.

| | predicted → actual, first 5 obs per skill | 5–19 | 20–59 | 60+ | PP actual success, updates 1–10 / 31–40 | final S | Δ parsed | PP − R |
|---|---|---|---|---|---|---|---|---|
| PP θ₀ = 0 | 0.522 → 0.605 | 0.528 → 0.578 | 0.559 → 0.583 | 0.607 → 0.617 | 0.576 / 0.623 | 0.7428 | +0.049 | +0.0194 [+0.007, +0.032] |
| PP θ₀ = 1.0 | **0.532 → 0.540** | **0.539 → 0.548** | 0.553 → 0.565 | 0.602 → 0.620 | **0.550** / 0.637 | 0.7425 | +0.049 | +0.0191 [+0.006, +0.032] |

PP θ₀ = 1 − PP θ₀ = 0, paired: −0.0003 (t-CI [−0.023, +0.022]).

- **The fix works as a calibration fix:** early predictions are now
  accurate, and PP's items in the first 10 updates are answered 55% correctly
  instead of 58%.
- **It does not change learning.** Final S, the skill gain, gradient-bearing
  groups (0.75 vs 0.74) and PP − R are unchanged.
- **Late targeting is limited by the pool, not the tracker.** After 60
  observations the tracker predicts PP's chosen items at about 0.60. PP
  cannot find items it expects at 0.5, because the improved student has
  outgrown most of the pool's items in each slate. Actual success climbs to
  0.62–0.64 in the last quarter under either θ₀; predicted-in-band stays at
  0.69. Harder items (another top-up) would be the lever here, not the
  tracker.
- Answer lengths at u40 for θ₀ = 1.0 were 281, 424, 431, 300 (KL 0.05),
  consistent with item 1.

## Recommendations for the confirmatory configuration

| setting | recommendation | why |
|---|---|---|
| `grpo.kl_coefficient` | **0.1** (owner's decision) | Meets E8 in 4/4 seeds and keeps ~60% of the learning. 0.05 learns more but shortens ~1/3 of runs; 0.2 learns too little. |
| `tracker.theta_initial` | **1.0** | Calibrated start at no cost. A dev-fitted value, pre-specified like `process_variance`. |
| `tracker.process_variance` | 0.05 | Unchanged; confirmed by replay. |
| guessing floor | **do not adopt** | It would be a spec §12 deviation for ~1 point of calibration, and calibration does not move learning (above). |
| item pool | note as a limitation | Late-phase targeting is pool-limited; a further hard-item top-up would be a separate decision. |

If KL 0.1 is chosen, plan for ~10–12 seeds per arm in the confirmatory run,
because the effect is expected to be smaller than F10's.
