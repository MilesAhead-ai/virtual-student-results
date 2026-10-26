# PT ceiling diagnostic: R vs PP vs PT, slate 16, 40 updates × 3 seeds (2026-10-14)

Setup as in `DEV_RUN3_SHORT40_POOLV1.md` (OLMo 3 7B Instruct-SFT, outcome-only
GRPO, final pool_v1, primary metric = final accuracy on S at update 40), but
every arm draws from a 16-item candidate slate. PT estimates each candidate's
success from 4 temperature-1 rollouts of the current checkpoint; its tracker
uses PanelProbe difficulty. Artifacts: `artifacts/olmo3sft_grpo_pt16/`.

## Primary result (final accuracy on S, 1,600 items)

| arm | seed 0 | seed 1 | seed 2 | mean |
|---|---|---|---|---|
| R | 0.6875 | 0.6887 | 0.6906 | 0.6889 |
| PP | 0.6994 | 0.6919 | 0.6881 | 0.6931 |
| PT | 0.6913 | 0.6956 | 0.6944 | 0.6938 |

- **PT − R = +0.0048** (per seed +0.004, +0.007, +0.004). All 3 seeds are
  positive; the bootstrap CI is [0.0037, 0.0069].
- **PP − R = +0.0042**, CI [−0.0025, +0.0119] (per seed +0.012, +0.003, −0.003).
- Targeting ratio (PP − R)/(PT − R) = 0.87, but its numerator is not resolved.
- AULC (secondary): R 0.680–0.684, PP 0.683–0.686, PT 0.682–0.683.

Caveat: a percentile bootstrap over 3 pairs understates uncertainty. "3 of 3
seeds positive" is the honest statement for PT (two-sided sign test p = 0.25).

## What the arms selected

| arm | updates | panel b of selected | in band (own estimate) | measured greedy acc | gradient-bearing groups |
|---|---|---|---|---|---|
| R | 1–10 / 31–40 | 0.06 / 0.00 | 28% / 18% | 0.67 / 0.72 | 0.69 |
| PP | 1–10 / 31–40 | 0.67 / 0.70 | 85% / 72% | 0.58 / 0.57 | 0.85 |
| PT | 1–10 / 31–40 | 0.21 / 0.34 | 91% / 74% | 0.67 / 0.62 | 0.89 |

PT picks items that are only moderately hard on the panel scale, yet are at
p ≈ 0.5 for the student's own *sampled* answers. Its greedy measured
accuracy is 0.62–0.67 because temperature-1 sampling is less accurate than
greedy decoding. PP picks harder items on the panel scale.

Gain by S difficulty tertile, update 0 → 40, is nearly identical across arms:
R +0.011/+0.021/+0.018, PP +0.017/+0.022/+0.024, PT +0.015/+0.024/+0.025
(easy/mid/hard).

## Reading

1. **Targeting helps, but very little, under outcome-only GRPO.** Even the
   oracle-like PT gains about 0.5 points over random in 40 updates, while all
   arms gain about 2 points. Selection is worth roughly a fifth of the
   learning, and that learning is small.
2. **PP's point estimate is close to PT's**, and its mean selection is at
   least as gradient-rich. With 3 seeds its effect is not resolved: one seed
   carries most of it. The earlier slate-64 comparison
   (`DEV_RUN3`) gave PP − R = 0.000.
3. **Resolving differences of ~0.4 points needs many more seeds.** With a
   per-pair SD of ~0.006, detecting +0.004 at 80% power takes roughly 18
   paired seeds per contrast.
4. The larger lever is probably **how much the student learns at all**:
   lr 2e-5, 40 updates, outcome-only reward. If learning grows, any targeting
   effect may grow with it.

## Options

- **Strengthen the training signal first**: higher learning rate, longer runs,
  and/or the SFT feedback arms (F0–F5, which need tutor and judge API
  decisions and budget). Then re-test R vs PP vs PT.
- **Power up the current comparison**: about 15–20 seeds per arm at 40
  updates (R/PP ~2.5 h per run, PT ~6 h per run on 1 GPU).
