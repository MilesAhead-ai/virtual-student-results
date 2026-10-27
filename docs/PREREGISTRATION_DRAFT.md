# Pre-registration (DRAFT, not frozen): PanelProbe item selection for an LLM student

**Status:** draft for the owner's review, 2026-10-27. Nothing here is frozen
until the owner signs off. Freezing means recording the confirmatory config's
hash in `OPEN_DECISIONS.md`. E1 has never been accessed (no
`data/locks/pool_v1/access_log.jsonl` exists).

There is no scientific design document (OPEN_DECISIONS A1). For this study,
this pre-registration takes its place: it states the estimand, the arms and
the analysis before any held-out data is seen.

## 1. Question

Does choosing training items by PanelProbe difficulty (PP) make an LLM
student learn more than choosing them at random (R) under outcome-only GRPO?

Development evidence (pool-v1-final, evaluated on S, not E1):
- PP − R = +0.019 final S accuracy over 7 seeds (t-CI [+0.008, +0.031]).
- PT − R = +0.021 over 3 seeds; targeting ratio 0.98.
- The gain is in accuracy among parseable answers, not format (FINDINGS #10).
- The settings were chosen on S during development (FINDINGS #6–#11). The
  confirmatory run tests them on held-out items with fresh seeds.

## 2. Hypotheses

- **H1 (primary, confirmatory).** After 40 updates, PP's final accuracy on
  E1 is higher than R's. Estimand: the mean over seeds of the paired
  difference PP − R in final E1 accuracy.
- **H2 (secondary, confirmatory if PT is included).** PT − R > 0 on the same
  metric.
- **Exploratory, no confirmatory claim:** targeting ratio (PP − R)/(PT − R);
  final S accuracy; accuracy among parseable answers; AULC; per-skill
  results; answer length; gradient-bearing groups; tracker calibration.

## 3. Design

| component | value |
|---|---|
| Student | `allenai/Olmo-3-7B-Instruct-SFT` @ `e1452fc572d51966ff4aaeb25118b891eb93e549` |
| Data | pool-v1-final: items `b4e060d6…`, split lock `6147da9a…`, split file `data/splits/pool_v1_dev.json`, calibration `pool-v1-gpu3` |
| Arms | R and PP (required); PT (owner's decision, §8) |
| Seeds | **fresh root seeds 100 … 100+n−1**, the same n for every arm, paired by seed; n per §5 |
| Training | outcome-only Dr. GRPO, 8 rollouts at T 1.0, ≤ 512 tokens; LoRA r16/α32/dropout 0.05; AdamW lr **2e-4** constant (5 warmup), wd 0, clip 1.0; **KL 0.05** to the base policy (E9); 32 items per update; **40 updates** |
| Selection | slate 16; PP target success 0.5, band ±0.15; PT 4 rollouts per candidate |
| Tracker | θ₀ **1.0** (E9), initial variance 2.0, process variance 0.05; spec §12 formula, no guessing floor |
| Evaluation | greedy, ≤ 512 tokens, every 5 updates, **batch-invariant vLLM**; dense sets **E1 (primary, 600 items, 60 per skill)** and S (secondary) |
| Prompt / parser | `prompts/student_answer.txt`; parser `answer-line-v1` (strict) |
| Draft config | `configs/confirmatory/DRAFT_r_s100.yaml` (preflight: 2 failures, both in §7) |

E1 and S have the same difficulty profile (mean b̂ +0.024 vs +0.030; 30% of
items with b̂ > 0.5 in both). All items in both are generated.

## 4. Analysis plan

1. For each seed s, compute d_s = final E1 accuracy(PP, s) − final E1
   accuracy(R, s) at update 40.
2. **H1 test:** two-sided one-sample t-test of {d_s}, α = 0.05. Report the
   mean, the t-interval and p. H1 is supported if the interval lies above 0.
3. H2 is tested the same way on PT − R. If both H1 and H2 are declared,
   Holm-correct across the two.
4. Secondary (not decisive): an item bootstrap with seeds fixed, the
   built-in `virtual-student analyze` report, and all exploratory measures
   in §2. The built-in seed-bootstrap CI is not quoted as the test: with few
   seeds it reduces to min–max (registry §4).
5. No interim look at E1. During the runs, monitoring uses only S,
   training signals and run health. E1 metrics are read once, after every
   run has completed.

## 5. Sample size

The per-seed SD of d on a 600-item set was estimated from the 7 F10 seed
pairs by resampling 60 items per skill from S: **0.0165**. That covers both
the training trajectory and the item sample. Power of the two-sided paired
t-test:

| seeds | δ = 0.010 | δ = 0.012 | δ = 0.015 | δ = 0.019 (dev estimate) |
|---|---|---|---|---|
| 8 | 0.32 | 0.43 | 0.60 | 0.80 |
| 10 | 0.40 | 0.54 | 0.73 | 0.90 |
| **12** | 0.48 | 0.63 | **0.82** | **0.95** |
| **16** | 0.62 | 0.78 | **0.93** | 0.99 |
| 20 | 0.73 | 0.87 | 0.97 | 1.00 |

Confirmatory effects are usually smaller than development estimates.
**Proposal: 16 seeds** (93% power at δ = 0.015). The minimum acceptable is
12 seeds (82% at δ = 0.015).

## 6. Runs, failures and exclusions

- Every run that completes 40 updates is analysed. **No exclusion based on
  outcomes:** answer shortening, letter skew or poor learning are reported,
  never filtered.
- A technical failure (crash, server fault such as an Xid, OOM) is re-run
  from scratch with the same seed. Generation is deterministic, so a clean
  re-run reproduces the intended run. Up to 2 retries.
- A seed that still cannot complete is reported as missing. The primary
  analysis then uses complete pairs, with a sensitivity note.
- Before launch, every vLLM server must pass a real `/v1/completions` check
  and the student's batch-invariance probe.

## 7. Spec interpretations needing approval

1. **Preflight `config.no_dummy_backends` and `taxonomy.frozen`.** The draft
   fails only these two checks. They concern the tutor, the four judges and
   the misconception taxonomy, which only feedback arms (F0–F5) use. R, PP
   and PT never call them. Proposal: scope both checks to runs whose
   feedback condition uses them, matching the spec's own rule that
   confirmatory configs must resolve every field "used by that run" (spec
   §5). The alternative, configuring real tutor and judge models and
   freezing a taxonomy just to pass the check, would misstate what the study
   uses.
2. **Single stage.** Spec stages 1–3 are undefined (A2). This study is one
   stage with the arms above.

## 8. Owner decisions before freezing

| # | decision | proposal |
|---|---|---|
| 1 | Seeds per arm | 16 (minimum 12) |
| 2 | Include PT? | Optional. PT is resolved in development and costs ~9.5 h per run. Proposal: PT with 8 seeds as a secondary arm (H2, exploratory ratio), or leave it out. |
| 3 | Spec interpretation §7.1 | approve |
| 4 | Sign-off on §2–§6 | — |

## 9. Cost and schedule (estimate)

R and PP: about 3.5–4.5 h per run with 8 runs in parallel on the three
servers. Evaluating E1 and S adds ~20% evaluation time. 16 seeds → 32 runs →
about 18–20 h. PT × 8 runs in parallel → about 10–13 h more. Total about
1–1.5 days on this machine. No paid API calls.

## 10. Known limitations

- One student model; outcome-only training (no tutor feedback arms).
- All settings were tuned on S during development; E1 is the held-out test.
- Under KL 0.05 about 1/3 of runs shorten their reasoning (E9 accepts this).
- Late in training PP is limited by the pool's supply of hard items: its
  best items are predicted at about 0.60 after 60 observations per skill
  (DEV_RUN8).
- The strict parser counts markdown answers as wrong. It is applied the same
  way in every arm.
