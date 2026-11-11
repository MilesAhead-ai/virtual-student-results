# Pre-registration: does the small-model panel measure difficulty better than a single strong model? (confirmatory MV)

**Status: DRAFT 2026-11-11, awaiting owner sign-off.** Nothing in §3.2 exists yet: the estimates are
produced only after freezing.

## 1. Question

PanelProbe's panel of small open models calibrates item difficulty from their answers. A single strong
model can instead be asked directly how hard an item is. **On held-out items, which estimate better
predicts the items that trained LLM students get wrong?**

Development evidence (never on E1 or E2):
- AUC for a wrong answer on R's random training picks: 8 small models 0.763 / 0.762, Claude Opus 5.5
  rating 0.698 / 0.706 (DEV_RUN10 and confirmatory DC R runs; FINDINGS #26, #29).
- On S (1,593 items; per-item error over confirmatory DC's 72 students at update 40), mean within-skill
  Spearman: small panel 0.472, Opus 0.408; difference +0.063, stratified item bootstrap 95% [+0.025, +0.103].

## 2. Hypotheses

- **H1 (primary).** The mean within-skill Spearman correlation between an item's difficulty estimate and
  its error rate among trained students is higher for the 8-small-model panel than for the Opus 5.5
  rating, over E1 and E2 together (1,200 items, 20 set × skill cells).
- **Secondary** (reported, not decisive): H1 on E1 alone and on E2 alone; the 15-member panel v2 vs Opus
  on E2; presentation-level AUC; H1 with the base model's errors (update 0).
- **Exploratory:** per set × skill.

## 3. Design

### 3.1 Outcomes (exist; they were produced by earlier pre-registered studies)

| set | items | students | data |
|---|---|---|---|
| E1 | 600 (60 per skill) | confirmatory v1: 40 runs (R, PP × 16 seeds, PT × 8), OLMo-3 trained 40 updates on pool v1 | `artifacts/olmo3sft_grpo_confirmatory_v1` |
| E2 | 600 (60 per skill) | confirmatory DC: 72 runs (R, PP16, PJ × 24 seeds), OLMo-3 trained 40 updates on pool v2 | `artifacts/olmo3sft_grpo_confirmatory_dc` |

Outcome per item: error rate over all runs of its study at update 40 (greedy, parser of that study).
Both sets were read once, by their own studies. **Neither the relation of any difficulty estimate to these
outcomes nor the per-item error rates have been looked at.**

### 3.2 Estimates (produced after freezing, blind to the outcomes)

- **Small panel.** The 8 local models of panel v1 (gemma2:2b, llama3.2:3b, phi3:3.8b, qwen2:7b,
  llama3.1:8b, qwen3:8b, deepseek-r1:8b, qwen3:14b), 3 passes, `repeat_weighting: mean`, MAP IRT.
  - E1: the existing calibration `pool-v1-gpu3` (computed 2026-10-06, before confirmatory v1; these 8 models,
    abilities fit on W). Not recomputed.
  - E2: new panel passes on E2 (`scripts/run_repeat_models.sh`, 3 passes), probed with the abilities of
    `pool-v2-small8` (the same 8 models, joint W + P + P+ fit, FINDINGS #29), data root `pool_v2_mv`.
- **Opus rating.** Claude Opus 5.5, prompt `difficulty-rating-v1` (unchanged), one rating per item, E1 and
  E2, file `data/raw/difficulty_ratings/opus55_mv_e1e2.jsonl`. Refused items are excluded from both
  estimates' comparison (reported).
- **Panel v2 (secondary, E2 only).** The 7 API members score E2 once; probed with `pool-v2-wp` abilities.

## 4. Analysis plan

`scripts/confirmatory_mv_analysis.py`, committed before freezing (hash in FROZEN.json); dry-run on S.

1. For each set × skill cell (20), Spearman ρ between the estimate (higher = harder; for the rating,
   −percent correct) and the item error rate. Statistic: mean ρ over cells.
2. **H1:** difference small − Opus; 95% percentile CI from 10,000 bootstrap replicates resampling items
   with replacement within each cell (seed 0). **Supported if the CI lies above 0.**
3. Secondary as §2; same bootstrap where applicable. Exploratory per cell.
4. Run once, after the estimates exist.

## 5. Sample size

From S, resampling 60 items per skill: with E2 alone (10 cells) the difference's bootstrap SD is about
0.033 (power ≈ 0.5 at +0.063); with E1 + E2 (20 cells) about 0.023 (power ≈ 0.8).

Dry run (2026-11-11, S standing in for both sets, 1,593 items; 7 Opus refusals excluded): mean ρ small
0.478 vs Opus 0.408, difference +0.070 [+0.042, +0.098]; with pool v1's students and calibration alone
+0.076 [+0.036, +0.115], with DC's alone +0.063 [+0.023, +0.103]; panel v2 − Opus +0.071; presentation AUC
0.752 vs 0.711; base model +0.061. (The dry run's two "sets" share their items, so its 20-cell interval is
narrower than E1 + E2's will be.) Runtime 46 min.

## 6. Exclusions and failures

- Items without both estimates (rater refusal, panel failure) are excluded and reported; no other
  exclusion.
- Panel passes follow the usual canary and retry rules (`rescore_with_canary.py`).

## 7. Frozen values

To be filled at freezing: analysis script hash, code commit, E1/E2 item-list hashes, `pool-v1-gpu3` and
`pool-v2-small8` ability tables (hashes), configs, git tag `confirmatory-mv-frozen`.

## 8. Known limitations

- One student model (OLMo-3-7B), trained by outcome-only GRPO; one rater prompt.
- E1 and E2 students differ (pool v1 vs pool v2 training); each set's outcome comes from its own study.
- The panel is fit to LLM answers, the rater asked about human test takers (as in development). The study
  asks which works better for LLM students, not which is "right".
- E2 was generated by Claude Opus 5.5, the same model as the rater.
