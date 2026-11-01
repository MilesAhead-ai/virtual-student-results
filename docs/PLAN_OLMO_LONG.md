# Plan: OLMo-3, longer training and a larger slate

Written 2026-10-31 (E12) so the work can be resumed from this file alone.
Update the status table as steps finish; record results in FINDINGS/registry.

## Why

- Confirmatory v1 (OLMo-3-7B-Instruct-SFT, 40 updates): PP − R +0.019 on E1.
  OLMo had **not** plateaued by u40.
- On Ministral-8B (F15), which plateaus near 0.78 well before u40, PP showed
  no advantage, although its targeting worked as on OLMo.
- So two questions matter for OLMo:
  1. **Does the advantage grow with longer training, or does R catch up once
     OLMo plateaus?** If R catches up, the v1 claim has to be stated as
     "learns faster" rather than "ends higher".
  2. **Does a larger candidate slate (64 instead of 16) let PP target better?**
     Late in v1, PP's best items were predicted at ~0.60, not 0.5
     (DEV_RUN8), and PT − R was larger than PP − R (targeting ratio 0.67).

## Status

| step | status | record |
|---|---|---|
| 1. Configs, preflight, servers back to OLMo | done 10-31 | 12 configs in `artifacts/olmo3sft_grpo_long100/configs/` |
| 2. Run: 3 arms × 4 seeds × 100 updates | done 11-01 (12/12; queue incident 10-31 23:22, no data lost) | `artifacts/olmo3sft_grpo_long100/` |
| 3. Analyse and report | done 11-01 | `DEV_RUN9_OLMO_LONG100.md`, FINDINGS #16, F16 |
| 4. Owner decides: confirmatory v3 or not | done 11-01: option A, a harder pool first → `PLAN_HARD_POOL.md` | — |

## Design (development; S and D only, E1 untouched)

| setting | value |
|---|---|
| Student | Olmo-3-7B-Instruct-SFT @ `e1452fc` (text prompts; tokenization verified 200/200) |
| Training | as C1: lr 2e-4 constant (5 warmup), KL 0.05, Dr. GRPO 8 rollouts, LoRA r16, 32 items per update, **100 updates** |
| Tracker | θ₀ 1.0, process variance 0.05 |
| Parser | answer-line-v1, as C1. A lenient v2 rescoring is reported as a diagnostic only |
| Arms | **R** (slate 16), **PP16** (slate 16, = C1's PP), **PP64** (slate 64) |
| Seeds | 0–3 per arm (12 runs) |
| Evaluation | S + D every 5 updates (21 checkpoints), batch-invariant vLLM |

Notes:
- With a constant schedule the run length is not part of the optimiser
  identity. R runs at seeds 0–3 replay the matching F10 runs' first 40
  updates exactly (same settings; R ignores the tracker), so they start fast.
  PP16 differs from F10 PP (θ₀ 1.0 vs 0).
- Pool use: 100 × 32 = 3,200 presentations per run, about 320 per skill out of
  ~1,100 pool items per skill. PP draws from the ~300–500 hard items per skill
  (b > 0.5) without replacement, so hard-item depletion late in PP runs is
  expected and will be measured.
- Estimated time: about 10–12 h (≤ 10 runs at once on GPUs 3–7, three vLLM
  servers on GPUs 0–2).

## What to report (step 3)

- PP − R (and PP64 − R, PP64 − PP16) at u40, u60, u80 and u100, plus AULC
  over u0…u100, all with t-intervals over 4 seeds.
- Whether R's curve flattens and catches up (plateau check: slope over the
  last 20 updates per arm).
- Targeting quality over time: predicted and actual success of selected
  items, in-band rate, mean b; hard-item depletion per skill.
- Accuracy among parseable answers, format-collapse incidence, answer length,
  gradient-bearing groups, letter skew.

## Decision rules (step 4, owner)

- **The gap holds or grows at u100** (especially for PP64): candidate for a
  pre-registered confirmatory v3 on OLMo with the longer horizon and the
  better slate. It would need fresh E1-like held-out items or an explicit
  argument for reusing E1, decided then.
- **R catches up by u100**: v1 stands as tested (+0.019 at u40), but its
  interpretation becomes "faster learning, same plateau". Record this in
  FINDINGS and in the v1 results document.
- **Instability at long horizons** (collapses, format drift): report it, and
  consider parser v2 for any v3.

## Operational notes

- Servers: `scripts/start_vllm.sh <GPU> <PORT>` (default STUDENT=olmo3sft).
- Base config: `results/olmo3sft_grpo_kl05_seeds/configs/r_s0.yaml`, plus
  `tracker.theta_initial: 1.0`, `training.updates: 100`,
  `selection.candidate_slate_size: 16|64`.
- Launch with `scripts/run_queue.py` (health checks, retries).
