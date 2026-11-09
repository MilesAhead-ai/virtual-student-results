# Plan: does panel calibration beat a single model's difficulty rating? (E19)

Written 2026-11-04. PanelProbe's claim is that difficulty calibrated from a
panel of models (15 members, IRT) selects better training items than cheaper
estimates. This control replaces the calibrated b with one strong model's
judgement and keeps everything else fixed.

## Status

| step | status | record |
|---|---|---|
| 1. Opus 5.5 rates every item (P, P+, plus W and S for validity checks) | done 11-05: 18,935 rated, 81 refused (biomedical), $93 | `data/raw/difficulty_ratings/opus55_v1.jsonl` |
| 2. Quantile-map ratings to the panel b scale; data root `pool_v2_opus` | done (refused items get the skill median rating) | `scripts/build_rating_calibration.py` |
| 3. Offline validity: which difficulty predicts the student's actual greedy outcomes in DEV_RUN10's R runs | done: AUC panel 0.764, Opus 0.698, label 0.614 (FINDINGS #26) | `scripts/difficulty_validity.py` |
| 4. Train: PP16 on the Opus difficulty (arm "PJ") and L (generator labels), seeds 0–3, 100 updates | done 11-05 (8/8) | `artifacts/olmo3sft_grpo_pool_v2_controls/` |
| 5. Compare with DEV_RUN10 R and PP16 | done (FINDINGS #27) | `DEV_RUN11_DIFFICULTY_CONTROLS.md` |

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

## Phase 2 (2026-11-08, after confirmatory DC and FINDINGS #29): two development arms

Owner: "we need stronger evidence". Written before any run; results are reported whatever they are.

| arm | difficulty | data root / calibration |
|---|---|---|
| **PS** | panel of the **8 small local models only** (panel v1 members), joint W+P+P+ fit | `pool_v2_small8` / `pool-v2-small8` |
| **PJ-raw** | Opus 5.5 rating, **no panel information**: b = ln((100 − p)/p), p clipped to 1–99; refusals get the skill median | `pool_v2_opusraw` / `opus55-logit` |

Both: PP16 rule, pool v2, OLMo-3 outcome GRPO, 100 updates, seeds 0–3, S and D every 5 updates
(as DEV_RUN10/11), compared with the existing R, PP16 and PJ dev runs at the same seeds.

What would count as evidence (pre-specified reading, development level):
- **Small panel is enough:** PS − R at u40 similar to PP16 − R (+0.017), and PS − PJ-raw > 0.
- **The panel supplies the scale:** PJ-raw − R clearly below PJ − R (+0.007), i.e. the single-model rating
  needs the panel's distribution to work.
- With 4 seeds these are indications only (DEV_RUN11's +0.0095 did not replicate); anything worth claiming
  goes to a pre-registered study.

| step | status |
|---|---|
| PS and PJ-raw runs (8) | done 11-09 (8/8). Small panel ≈ full panel: supported. Panel supplies the scale: not supported (FINDINGS #30) |
