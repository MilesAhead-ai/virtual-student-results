# Plan: does panel calibration beat a single model's difficulty rating? (E19)

Written 2026-11-04. PanelProbe's claim is that difficulty calibrated from a
panel of models (15 members, IRT) selects better training items than cheaper
estimates. This control replaces the calibrated b with one strong model's
judgement and keeps everything else fixed.

## Status

| step | status | record |
|---|---|---|
| 1. Opus 5.5 rates every item (P, P+, plus W and S for validity checks) | todo | — |
| 2. Quantile-map ratings to the panel b scale; data root `pool_v2_opus` | todo | — |
| 3. Offline validity: which difficulty predicts the student's actual greedy outcomes in DEV_RUN10's R runs | todo | — |
| 4. Train: PP16 on the Opus difficulty (arm "PJ") and L (generator labels), seeds 0–3, 100 updates | todo | — |
| 5. Compare with DEV_RUN10 R and PP16 | todo | — |

## Design

- **Rater:** Claude Opus 5.5 (Bedrock Mantle), adaptive thinking at its default effort. It sees passage,
  question, choices and the key, and estimates the percentage of SAT test takers who answer correctly.
  One rating per item; cached; spend logged to `artifacts/api_spend/difficulty_rating_ledger.jsonl`.
- **Scale:** within each skill, items of P + P+ are ranked by the rating (lower predicted percent correct =
  harder; ties share their mean quantile) and given the panel b values of the same skill in the same rank
  order. The arm therefore has exactly the panel's difficulty distribution; only the ordering differs.
  Rows are written under calibration id `pool-v2-opus55q`.
- **Training:** identical to DEV_RUN10 PP16 (OLMo-3, outcome GRPO, lr 2e-4, KL 0.05, θ₀ 1.0, parser v2,
  slate 16, 100 updates, S and D every 5 updates). The tracker uses the mapped difficulty too.
- **L arm:** the spec's staircase over generator labels (D1–D5 asked of the generator); no API cost.
  70% of training items are labelled D5, so L is expected to be weak.

## Outcomes

S accuracy curves and contrasts PJ − R, PP16 − PJ, L − R (paired by seed, t-intervals), plus what each
arm selected (greedy success and panel b by quarter).
