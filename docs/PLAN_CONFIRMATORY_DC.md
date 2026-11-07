# Plan: confirmatory study "panel-calibrated difficulty vs a single-model rating" (E20)

Written 2026-11-06. Resume from this file; keep the status table updated.
Development evidence: FINDINGS #26 (offline AUC: panel b 0.764, Opus 5.5 rating 0.698) and #27
(DEV_RUN11: u40 vs R, PP16 +0.017 4/4, PJ +0.007; PP16 − PJ +0.010, CI includes 0 with 4 seeds).

## Status

| step | status | record |
|---|---|---|
| 1. Generate E2 candidates | done 11-06: four rounds, 2,131 generated, ≈$109 | `data/raw/heldout_e2/` |
| 2. Select E2 | done: 600 (60 per skill, 12 per label) | `data/raw/heldout_e2/e2_items.report.json` |
| 3. Import, recalibrate, check, map, lock | done: P/P+ and both difficulty tables identical to development; lock `d80feded…` | `data/processed/pool_v2_dc` |
| 4. Pre-registration → sign-off → freeze | done 11-06 (E21): FROZEN.json, tag `confirmatory-dc-frozen`, code `8f5cef2` | `PREREGISTRATION_CONFIRMATORY_DC.md` |
| 5. Runs: R, PP16, PJ × 24 seeds × 40 updates | done 11-07 12:03 UTC: 72/72, 0 failures | `results/olmo3sft_grpo_confirmatory_dc/queue.log` |
| 6. Analysis, results doc, FINDINGS, publish | done 11-07: H1 not supported; H2, H3 supported (FINDINGS #28) | `CONFIRMATORY_DC_RESULTS.md` |

## Design (to be fixed in the pre-registration)

- Student OLMo-3-7B-Instruct-SFT @ e1452fc, outcome GRPO, lr 2e-4 constant, KL 0.05, θ₀ 1.0, parser v2,
  slate 16, 40 updates; pool v2 (training splits P, P+), panel v2 calibration `pool-v2-wp` (joint fit).
- PJ: Claude Opus 5.5 rating (`data/raw/difficulty_ratings/opus55_v1.jsonl`, 81 refusals → skill median),
  quantile-mapped per skill onto the panel b distribution of P + P+.
- Seeds: new block, not used in development.
- H1 (primary): PP16 − PJ on final E2 accuracy > 0, paired by seed, two-sided paired t, α 0.05.
  Secondary (Holm with H1): PP16 − R, PJ − R. Exploratory: S accuracy, per-skill, selection diagnostics.
- Power: dev paired sd ≈ 0.015 at u40; 24 seeds give ≈ 85% power at a true +0.010.
