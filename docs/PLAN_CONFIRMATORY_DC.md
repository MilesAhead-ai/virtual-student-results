# Plan: confirmatory study "panel-calibrated difficulty vs a single-model rating" (E20)

Written 2026-11-06. Resume from this file; keep the status table updated.
Development evidence: FINDINGS #26 (offline AUC: panel b 0.764, Opus 5.5 rating 0.698) and #27
(DEV_RUN11: u40 vs R, PP16 +0.017 4/4, PJ +0.007; PP16 − PJ +0.010, CI includes 0 with 4 seeds).

## Status

| step | status | record |
|---|---|---|
| 1. Generate E2 candidates (Opus 5.5, D1–D5 × 15 per skill, double key check) | running since 11-06 | `data/raw/heldout_e2/`, `scripts/run_heldout_stream.sh` |
| 2. Select E2: key agreement, topic-twin dedup vs everything, 12 per label per skill | todo | `scripts/select_heldout.py` |
| 3. Import pool v2 + E2 (data root `pool_v2_dc`), recalibrate, check P/P+ difficulties unchanged, map the Opus rating, lock | todo | — |
| 4. Pre-registration draft → owner sign-off → freeze (FROZEN.json, tag), analysis script committed before the runs | todo | — |
| 5. Runs: R, PP16, PJ × 24 seeds × 40 updates; E2 blackout until the queue logs END | todo | — |
| 6. Analysis, results doc, FINDINGS, publish | todo | — |

## Design (to be fixed in the pre-registration)

- Student OLMo-3-7B-Instruct-SFT @ e1452fc, outcome GRPO, lr 2e-4 constant, KL 0.05, θ₀ 1.0, parser v2,
  slate 16, 40 updates; pool v2 (training splits P, P+), panel v2 calibration `pool-v2-wp` (joint fit).
- PJ: Claude Opus 5.5 rating (`data/raw/difficulty_ratings/opus55_v1.jsonl`, 81 refusals → skill median),
  quantile-mapped per skill onto the panel b distribution of P + P+.
- Seeds: new block, not used in development.
- H1 (primary): PP16 − PJ on final E2 accuracy > 0, paired by seed, two-sided paired t, α 0.05.
  Secondary (Holm with H1): PP16 − R, PJ − R. Exploratory: S accuracy, per-skill, selection diagnostics.
- Power: dev paired sd ≈ 0.015 at u40; 24 seeds give ≈ 85% power at a true +0.010.
