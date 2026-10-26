# 40-update runs on the topped-up pool: R vs PP × 3 seeds (2026-10-13)

Setup as in `DEV_RUN2_SHORT40.md`, but on the final pool_v1 (≥ ~300 items
with b > 0.5 per skill in P+P+). Evaluation is on **S (1,600 items) as the
primary set** and D as a secondary set. The pre-registered primary metric is
**final accuracy on S at update 40** (OPEN_DECISIONS E7).
Artifacts: `artifacts/olmo3sft_grpo_short40_v2/`.

## Primary result

**PP − R final accuracy on S = 0.0000, 95% CI [−0.0025, +0.0044]**
(3 pairs; per seed +0.0044, −0.0019, −0.0025). No difference. AULC on S,
the secondary metric: PP 0.681/0.683/0.680 vs R 0.683/0.685/0.681.

Both arms improved by about 2 points on S over 40 updates (0.67 → 0.69).

## Targeting now works as designed

| updates | PP selected b | PP in band [.35, .65] | PP measured acc | R selected b | R in band | R acc |
|---|---|---|---|---|---|---|
| 1–10 | 0.83 | **94%** | 0.53 | 0.04 | 25% | 0.68 |
| 11–20 | 0.90 | 89% | 0.53 | 0.02 | 21% | 0.68 |
| 21–30 | 0.83 | 78% | 0.56 | 0.03 | 21% | 0.69 |
| 31–40 | 0.78 | 73% | 0.58 | 0.03 | 19% | 0.73 |

Gradient-bearing GRPO groups: **PP 0.87 vs R 0.69**. The depletion seen in
`DEV_RUN1`/`DEV_RUN2` is gone. PP holds measured success near 0.55 for the
whole run.

S accuracy by difficulty tertile, update 0 → 40 (mean of 3 seeds):

| | easy | mid | hard |
|---|---|---|---|
| PP | 0.877 → 0.890 | 0.655 → 0.677 | 0.484 → 0.505 |
| R | 0.876 → 0.888 | 0.667 → 0.672 | 0.481 → 0.513 |

## Reading

The selection mechanism does exactly what it is supposed to: it keeps the
student at p ≈ 0.5 and gives GRPO more gradient-bearing groups. **It does not
turn that into faster learning in this setting.** The earlier hint of PP
gaining more on mid/hard items (DEV_RUN2, D tertiles of 66 items) does not
replicate on S.

Candidate explanations, none tested yet:

1. **The learning signal is small overall.** +2 points in 40 updates at
   lr 2e-5. With effects this size, selection differences may be below
   what 3 seeds resolve. A larger learning rate or longer runs would test it.
2. **Outcome-only GRPO learns something item-agnostic** (answer format,
   general care) that does not depend on which items it sees.
3. **Hard generated items may be hard partly because they are flawed or
   ambiguous.** The blind key check passes 99%, but agreeing on a key is not
   the same as being a clean item. Training on such items may teach little.
4. **R already has many gradient-bearing groups** (0.69) on the harder pool,
   so PP's extra 0.18 buys little.

## The decisive next diagnostic

**PT (privileged targeting)** selects using the student's own rollouts. It is
the ceiling for any difficulty proxy. If PT ≈ R, no targeting helps this
student under outcome-only GRPO, and PanelProbe cannot either. If PT > R,
the gap is PanelProbe's targeting error. PT is expensive: slate × rollouts
generations per presentation. 64 × 4 is ~8k generations per update; a
reduced slate of 16 × 4 is ~2k, roughly 15 min per update with vLLM, or
about 10 h for a 40-update run.
