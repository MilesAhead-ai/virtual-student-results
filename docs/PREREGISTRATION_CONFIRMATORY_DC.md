# Pre-registration: panel-calibrated difficulty vs a single model's rating (confirmatory DC)

**Status: FROZEN 2026-11-06**, signed off by the owner (24 seeds per arm, as drafted). Frozen configs and
hashes: `configs/confirmatory/dc/FROZEN.json`; git tag `confirmatory-dc-frozen`. E2 had never been accessed
before this point (no `data/locks/pool_v2_dc/access_log.jsonl` existed).

## 1. Question

PanelProbe estimates item difficulty by having a panel of models answer each item and fitting an IRT
model (panel v2: 15 members, calibration `pool-v2-wp`). Is that worth it? Does choosing training items
by the panel's calibrated difficulty make an LLM student learn more than choosing them, with the same
targeting rule, by a single strong model's judgement of difficulty?

Development evidence (pool v2, evaluated on S, never on E2):
- Offline (FINDINGS #26): on 12,739 random presentations, the panel's b predicts the student's wrong
  answers better than Claude Opus 5.5's rating on all 10 skills (AUC 0.764 vs 0.698).
- Training (FINDINGS #27, DEV_RUN11, seeds 0–3): after 40 updates, PP16 − R +0.017 [+0.002, +0.032]
  4/4; PJ − R +0.007 [−0.008, +0.023]; PP16 − PJ +0.010 [−0.015, +0.034] 3/4.

## 2. Hypotheses

- **H1 (primary).** After 40 updates, final E2 accuracy is higher with the panel's difficulty (PP16)
  than with the single-model rating (PJ). Estimand: mean over seeds of the paired difference
  PP16 − PJ in final E2 accuracy (all 600 items).
- **H2 (secondary).** PP16 − R > 0 on the same metric.
- **H3 (secondary).** PJ − R > 0 on the same metric.
- **Exploratory, no confirmatory claim:** final S accuracy; accuracy among parseable answers; per skill;
  answer length; gradient-bearing groups; panel b of the items each arm selected.

## 3. Design

| component | value |
|---|---|
| Student | `allenai/Olmo-3-7B-Instruct-SFT` @ `e1452fc572d51966ff4aaeb25118b891eb93e549` |
| Data | pool v2 (FINDINGS #19) + held-out E2 (§3.1); data root `data/processed/pool_v2_dc` for every arm (both difficulty tables in one `item_difficulties.parquet`), split file `data/splits/pool_v2_dc.json`, split lock `d80feded…` |
| Training pool | splits P (16,070) and P+ (640), unchanged from development |
| Arms | **R** (random); **PP16** (PanelProbe, panel b, calibration `pool-v2-wp`); **PJ** (PanelProbe rule on Claude Opus 5.5's rating, quantile-mapped per skill onto the panel b distribution of P + P+, calibration `pool-v2-opus55q`) |
| Seeds | root seeds **200–223** (24) for every arm, paired by seed; none used in development |
| Training | outcome-only Dr. GRPO, 8 rollouts at T 1.0, ≤ 512 tokens; LoRA r16/α32/dropout 0.05; AdamW lr 2e-4 constant (5 warmup), wd 0, clip 1.0; KL 0.05; 32 items per update; **40 updates** |
| Selection | slate 16; target success 0.5; tracker θ₀ 1.0, initial variance 2.0, process variance 0.05; the tracker uses the arm's own difficulty |
| Evaluation | greedy, ≤ 512 tokens, every 5 updates, batch-invariant vLLM; dense sets E2 (primary, 600 items) and S (1,600, secondary) |
| Prompt / parser | `prompts/student_answer.txt`; `answer-line-v2` |
| Configs | `configs/confirmatory/dc/{r,pp16,pj}_s200…223.yaml` (72) |

### 3.1 The held-out set E2

Generated for this study (E14, E20) and never used before. Claude Opus 5.5, standard generation prompt
(PROMPT_VERSION 6), all D1–D5 levels; keys balanced; kept only if both blind verifiers (Sonnet 5.5 and
Opus 5.5) agree with the key; dropped if its passage + question has cosine ≥ 0.88 (bge-small-en-v1.5 @
5c38ec7c, the v1 topic-twin definition) to any of the 19,816 items already in pool v2 (any split) or to
an E2 item kept before it (fixed hash order); then 12 per asked label per skill: **600 items, 60 per
skill, 12 per label per skill.** The strict dedup removed most candidates, so generation ran in four
rounds (E2, E2b, E2c, E2d; the last two only for the strata still short): 2,131 generated, 8 failed the
key check, 1,228 twinned an existing item, 78 twinned another E2 item, 217 were surplus. Largest
similarity of a selected item to an existing one: 0.880. Cost ≈ $109. Report:
`data/raw/heldout_e2/e2_items.report.json`. Selection read no student or panel output, and E2 has never
been read by any run (no access log exists). E2 has no panel scores; none are needed to evaluate.

### 3.2 The PJ difficulty

Ratings: `data/raw/difficulty_ratings/opus55_v1.jsonl` (18,935 items; prompt `difficulty-rating-v1`:
the percentage of SAT test takers who answer correctly, with passage, question, choices and key
shown). 81 refusals (biomedical passages) take the skill's median rating. Mapping:
`scripts/build_rating_calibration.py`. PJ thus has exactly PP16's difficulty distribution per skill;
only which items count as hard differs.

## 4. Analysis plan

`scripts/confirmatory_dc_analysis.py`, committed before any run (commit recorded in FROZEN.json); dry-run on the
development data (S standing in for E2) reproduced DEV_RUN11's numbers.

1. For each seed s and hypothesis, d_s = final E2 accuracy(arm A, s) − final E2 accuracy(arm B, s) at
   update 40.
2. Two-sided one-sample t-test of {d_s}, α 0.05; report mean, t-interval, p. **Holm across H1–H3.**
   A hypothesis is supported if its interval lies above 0 and its Holm p < 0.05.
3. Secondary, not decisive: item bootstrap of H1 with seeds fixed.
4. **No interim look at E2.** Monitoring during the runs uses only S, training signals and run health.
   E2 metrics are read once, after the queue logs END. Commands that print E2 metrics (`analyze`,
   `report`, `build_registry.py`, `analyze_dev_long.py`) are not run on these runs before then.

## 5. Sample size

The paired seed SD of PP16 − PJ for a 600-item set was estimated from DEV_RUN11 by resampling 60 items
per skill from S: **0.0176** (PP16 − R 0.0148, PJ − R 0.0143). Power of the two-sided paired t-test
with 24 seeds, before Holm: **H1 0.57 at δ 0.008, 0.76 at δ 0.010, 0.98 at δ 0.015**; H2 0.89 and
H3 0.91 at δ 0.010. The development estimate of H1 (+0.0095) is from 4 seeds and may be optimistic.

## 6. Runs, failures and exclusions

- Every run that completes 40 updates is analysed; no exclusion based on outcomes.
- A technical failure is re-run with the same seed, up to 2 retries (`scripts/run_queue.py`). Training
  is not bit-reproducible (FINDINGS #16), so a re-run is a valid trajectory, not a copy. A failed run's
  directory is moved aside, never deleted.
- A seed that still cannot complete in some arm is reported as missing; each hypothesis then uses the
  seeds complete in both of its arms.
- No code or config schema change while runs are in flight (CLAUDE.md, FINDINGS #25).
- Before launch, every vLLM server must pass a real `/v1/completions` check.

## 7. Frozen values

| item | value |
|---|---|
| E2 items (`data/raw/heldout_e2/e2_items.jsonl`) | sha256 `8e0351f60f1c9c78…` |
| E2 selection report | sha256 `cd52818ea16dc158…` |
| Split file `data/splits/pool_v2_dc.json` | sha256 `3625758146997575…` |
| Split lock `data/locks/pool_v2_dc/splits_v1.json` | `d80feded0000a38bc652c6677fac6b3ff69f3a12ebf2dd102d2ded6228edf2ee` |
| Panel difficulties `pool-v2-wp` (19,816 rows; identical to development) | `1b960965f9992807…` (sha256 of sorted item_id/b) |
| Opus-rating difficulties `pool-v2-opus55q` (19,008 rows; identical to DEV_RUN11) | `a98f22020f89d81e…` |
| Ratings file `data/raw/difficulty_ratings/opus55_v1.jsonl` | sha256 `d9048de212ff3a3c…` |
| Configs, code commit, git tag | `configs/confirmatory/dc/FROZEN.json` (written at freezing), tag `confirmatory-dc-frozen` |

## 8. Spec interpretations

1. As confirmatory v1 §8: preflight's tutor/judge/taxonomy checks apply only to feedback conditions;
   single stage.
2. **The difficulty estimate is a treatment.** The spec's pairing check treats only the policy and the
   feedback condition as treatments, so PP16 and PJ (same policy, different calibration id) would count
   as unpaired. Preflight now takes declared treatment fields (`--treatment-field`); this study declares
   `experiment.calibration_id` and nothing else. With it, all 72 configs pass confirmatory preflight and
   pair by seed.

## 9. Cost and schedule (estimate)

72 runs × 40 updates. About 3.5–4 h per run; up to 12 at a time (two per training GPU on six GPUs,
two vLLM servers): roughly 1–1.5 days. No paid API calls (ratings and E2 are already paid for).

## 10. Known limitations

- One student model (OLMo-3-7B), outcome-only GRPO, settings tuned on S with pool v1/v2.
- One rater (Opus 5.5) with one prompt; another prompt or model might rate better. The comparison is
  "panel calibration vs one strong model asked directly", not vs every single-model method.
- The quantile mapping gives PJ the panel's difficulty distribution, which is information the rater
  alone would not have; this favours PJ, if anything.
- E2 is generated by the same model family as the rater (Claude). It is used only for evaluation.

## 11. Changes after freezing

None yet.
