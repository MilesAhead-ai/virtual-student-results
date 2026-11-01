# Dev run 9: OLMo-3, 100 updates, slate 16 vs 64 (2026-11-01)

Plan: `PLAN_OLMO_LONG.md` (E12). Arms R (slate 16), PP16, PP64 × seeds 0–3,
100 updates, C1 settings otherwise (lr 2e-4 constant, KL 0.05, θ₀ 1.0,
parser v1). Evaluated on S (1,600) and D every 5 updates; E1 untouched.
Experiment: `artifacts/olmo3sft_grpo_long100/`; small results:
`results/olmo3sft_grpo_long100/`; analysis: `analysis/long100.txt`.
All 12 runs completed. Incident: a queue bug moved two run directories
for about a minute; no data was lost (FINDINGS #16).

## Main result: the advantage does not grow with longer training

Mean S accuracy (strict):

| update | 20 | 40 | 60 | 80 | 100 |
|---|---|---|---|---|---|
| R | 0.705 | 0.723 | 0.747 | 0.768 | 0.759 |
| PP16 | 0.705 | 0.742 | 0.758 | 0.773 | 0.779 |
| PP64 | 0.712 | 0.746 | 0.761 | 0.753 | 0.773 |

Contrasts (t-interval over 4 seeds):

| | u40 | u60 | u80 | u100 | AULC u0–100 |
|---|---|---|---|---|---|
| PP16 − R | **+0.019** [+0.004, +0.034], 4/4 | +0.011 [−0.008, +0.030] | +0.005 [−0.009, +0.020] | +0.020 [−0.013, +0.053] | +0.016 [−0.004, +0.037], 4/4 |
| PP64 − R | **+0.022** [+0.014, +0.030], 4/4 | +0.014 [−0.002, +0.031] | −0.015 [−0.048, +0.018] | +0.014 [−0.004, +0.031] | +0.013 [−0.007, +0.033], 4/4 |
| PP64 − PP16 | +0.004 | +0.003 | −0.021 [−0.044, +0.003] | −0.006 | — |

- **At u40 the dev result reproduces C1** (PP − R +0.019; C1 on E1: +0.019).
- **After u40 R catches up.** At u80 the gap is +0.005 (CI includes 0).
  The u100 gap (+0.020) is mostly an artefact of one R run (seed 1). It hit
  a format collapse at u90 (S 0.26, 65% unparseable; parser v1) and had not
  fully recovered by u100 (0.735). No PP run collapsed.
- **Slate 64 adds nothing beyond the first quarter.**

## Why: the pool runs out of items hard enough

Selected items by quarter of training: actual greedy success, share with
b > 0.5, predicted-in-band rate.

| arm | u1–25 | u26–50 | u51–75 | u76–100 |
|---|---|---|---|---|
| R | 0.700, 0.31, 0.23 | 0.732, 0.31, 0.19 | 0.766, 0.31, 0.18 | 0.742, 0.30, 0.18 |
| PP16 | **0.576**, 0.70, 0.75 | 0.640, 0.71, 0.55 | 0.703, 0.68, 0.40 | **0.749**, 0.57, 0.29 |
| PP64 | **0.559**, 0.71, 0.82 | 0.638, 0.73, 0.55 | 0.705, 0.76, 0.41 | **0.737**, 0.62, 0.22 |

As the student improves and PP uses up hard items (without replacement),
PP's chosen items get easier for the student. By the last quarter they are
answered as often as R's random items (0.75 vs 0.74), so targeting no longer
differs from random selection, and R catches up. A larger slate cannot fix
this: it helps only while hard items remain.

## Other observations

- Accuracy among parseable answers at u100: R 0.761, PP16 0.780, PP64 0.774.
  The R mean includes seed 1's collapse.
- Reasoning length at u100: 116–618 characters; no letter skew.
- **Training is not bit-reproducible.** With identical inputs (same history
  hash, same rollouts), the GRPO loss differs in 39 of 40 updates (R s0 vs
  the F10 run). "Replays" from the generation cache reproduce recorded
  *outputs* exactly, because outputs come from the cache. The LoRA weights
  underneath differ slightly, and a run diverges at its first cache miss
  (R s3 at u39; cause of the miss not identified). Each run is still a valid
  trajectory, so the comparisons are unaffected. But a same-seed re-run does
  not reproduce a run unless every generation is a cache hit.

## Implications

1. **The v1 result should be read as faster learning.** PP gets the student to
   a given level sooner. With this pool the advantage peaks around u40, and R
   catches up by about u80. v1's pre-registered claim (+0.019 at u40 on E1)
   stands as tested.
2. **The limiting factor is the item pool, not the selection method or the
   slate.** A larger or more durable effect needs more items that are hard
   *for the student* throughout training: a further hard-item top-up, or a
   pool or student pairing where hard items are plentiful.
3. Long horizons bring format collapses under parser v1 (R s1). Any longer
   run should use parser v2.
