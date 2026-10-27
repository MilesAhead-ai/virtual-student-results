# Dev run 7: R vs PP vs PT with a stronger learning signal (3 seeds 2026-10-20; R/PP extended to 7 seeds 2026-10-27)

**Question.** In #5 (lr 2e-5) targeting was worth about half a point, and
FINDINGS #6 showed that run's learning was nearly all format. With a learning
signal that teaches real skill (lr 2e-4) and keeps the reasoning (KL 0.05,
decision E8), does targeting by PanelProbe difficulty (PP) beat random
selection (R), and how close does it get to the oracle (PT)?

**Design.** R, PP, PT × seeds 0–2. lr 2e-4 constant (5 warmup), KL 0.05 to the
base policy, outcome-only Dr. GRPO, 8 rollouts, slate 16, 40 updates.
Batch-invariant vLLM (FINDINGS #8): the u0 evaluation is identical in all nine
runs (S 0.6763), so the only noise left is the training trajectory (seed) and
the choice of evaluation items. Primary metric: final accuracy on S (1,600
items, E7). Experiment `artifacts/olmo3sft_grpo_kl05_seeds/`, small results in
`results/olmo3sft_grpo_kl05_seeds/`. Built-in analysis in `analysis/report.md`;
the extra statistics below are in `analysis/extra_stats.{txt,json}`. R seed 0
has the same scientific config as the stability run's lr 2e-4 KL 0.05 arm
(run id `354a61dc`) and replayed it from cache. Under deterministic
generation that is an exact reproduction, not a shortcut.

## Results

Final S accuracy (u40):

| seed | R | PP | PT | PP − R | PT − R | PP − PT |
|---|---|---|---|---|---|---|
| 0 | 0.7294 | 0.7400 | 0.7469 | +0.0106 | +0.0175 | −0.0069 |
| 1 | 0.7231 | 0.7525 | 0.7431 | +0.0294 | +0.0200 | +0.0094 |
| 2 | 0.7244 | 0.7450 | 0.7488 | +0.0206 | +0.0244 | −0.0037 |
| **mean** | 0.7256 | 0.7458 | 0.7462 | **+0.0202** | **+0.0206** | −0.0004 |

Uncertainty. **With 3 seeds the built-in bootstrap is not informative.** It
resamples the 3 seed differences, so its "95% CI" is just their min–max and
its p of 0.000 is an artefact. Two more honest views:

| contrast | seed sd | t-interval over seeds (df 2) | two-sided p | item bootstrap (seeds fixed, items resampled) |
|---|---|---|---|---|
| PP − R | 0.0094 | [−0.003, +0.044] | 0.065 | [+0.008, +0.032] |
| PT − R | 0.0035 | [+0.012, +0.029] | 0.009 | [+0.009, +0.032] |
| PP − PT | 0.0086 | [−0.022, +0.021] | 0.94 | [−0.011, +0.010] |

Targeting ratio (PP−R)/(PT−R) = **0.98** (built-in, CI [0.61, 1.47] over 3
triples). AULC agrees in direction: R 0.705, PP 0.713, PT 0.716.

Per arm (means over seeds, per-seed values in brackets):

| arm | final S | Δ accuracy among parseable answers | unparseable at u40 | answer length u40 (chars) | max letter share | gradient groups, last 10 updates |
|---|---|---|---|---|---|---|
| R | 0.7256 | +0.032 [0.035, 0.029, 0.031] | 0.2% | 546 / 446 / 516 | 0.26–0.27 | 0.47 / 0.51 / 0.45 |
| PP | 0.7458 | **+0.053** [0.047, 0.058, 0.053] | 0.3% | 628 / 495 / 466 | 0.28–0.29 | 0.68 / 0.66 / 0.61 |
| PT | 0.7462 | **+0.053** [0.055, 0.048, 0.054] | 0.2% | 478 / **175** / 450 | 0.27–0.29 | 0.74 / 0.71 / 0.68 |

## What this shows

1. **With a real learning signal, targeting helps, and PanelProbe targeting
   matches the oracle.** PT − R = +0.021 (CI excludes 0), and PP − R = +0.020
   with PP − PT ≈ 0 (targeting ratio 0.98). In #5 at lr 2e-5 both were about
   +0.005, and that learning was format. The effect is about 4× larger now,
   and the ratio rose from 0.87.
2. **The gain is skill, not format.** Every arm ends with ≤ 0.3% unparseable
   answers, so format is saturated everywhere. The arms differ in accuracy
   among parseable answers: +0.053 for PP and PT against +0.032 for R. That
   gap (+0.021) is the whole PP−R and PT−R effect.
3. **Mechanism is consistent with the targeting rationale.** PP and PT keep
   many more gradient-bearing groups late in training (0.61–0.74 vs
   0.45–0.51 for R). As R's student improves, more random items become
   all-correct and give no GRPO signal. Targeted items stay near 50%.
4. **E8 holds in 8 of 9 runs.** Answers stay at 450–630 characters with no
   letter skew. PT seed 1 shortened to 175 characters at u40; KL 0.05 does not
   guarantee long reasoning in every trajectory.
5. **The weak point is seed-to-seed variation of PP.** PP − R ranges from
   +0.011 to +0.029 (seed sd 0.009, against 0.0035 for PT − R). Its t-interval
   still includes 0 (p = 0.065). The item bootstrap excludes 0, but it holds
   the three trajectories fixed, so it is not evidence across seeds.
   Neither interval clears the configured minimum effect of 0.02.

## Proposed next step after 3 seeds: extend seeds (done, see below)

To resolve PP − R across seeds, extend R and PP to 7 seeds (seeds 3–6, 8 more
runs). With seed sd ≈ 0.009 that gives a t-interval half-width of about
±0.009, so a +0.02 effect would exclude 0 with room to spare. R and PP take
about 3.5 h each with three runs per server, so 8 runs on GPUs 3–7 and the
three servers take roughly 4–5 h. PT is the expensive arm (about 13 h per run
here). It is already resolved against R, so extending it is optional; it
would also tighten the targeting ratio.

Open questions for the owner, none blocking:
- Whether one shortened-reasoning run (PT s1) is acceptable under E8, or
  whether KL should be a little stronger (e.g. 0.07) in later runs.
- Whether to move from development comparisons to the confirmatory protocol
  once the seed extension resolves PP − R.

## Seed extension to 7 (2026-10-27)

**What was run.** R and PP at seeds 3–6, settings identical to seeds 0–2,
in the same experiment directory. PT was not extended: it was already
resolved against R and costs about 9.5 h per run. The first launch on
2026-10-26 failed: an Xid 45 on 2026-10-23 had silently killed the CUDA
contexts of all three vLLM servers while HTTP stayed up. The servers were
restarted, the empty run dirs moved to `artifacts/_failed_starts/2026-10-26_xid45/`,
and the runs relaunched. All eight new u0 evaluations equal seeds 0–2's
(S 0.6763), so the restarted servers reproduce the earlier ones exactly.
Statistics: `analysis/extra_stats_7seeds.{txt,json}`.

Final S accuracy:

| seed | R | PP | PP − R |
|---|---|---|---|
| 0 | 0.7294 | 0.7400 | +0.0106 |
| 1 | 0.7231 | 0.7525 | +0.0294 |
| 2 | 0.7244 | 0.7450 | +0.0206 |
| 3 | 0.7169 | 0.7338 | +0.0169 |
| 4 | 0.7175 | 0.7550 | +0.0375 |
| 5 | 0.7256 | 0.7462 | +0.0206 |
| 6 | 0.7250 | 0.7238 | −0.0013 |
| **mean** | 0.7231 | 0.7423 | **+0.0192** |

| contrast | seeds | seed sd | t-interval over seeds | two-sided p | item bootstrap | positive |
|---|---|---|---|---|---|---|
| **PP − R** | **0–6** | 0.0125 | **[+0.008, +0.031]** (df 6) | **0.007** | [+0.011, +0.027] | 6/7 |
| PP − R | 0–2 | 0.0094 | [−0.003, +0.044] (df 2) | 0.065 | [+0.008, +0.032] | 3/3 |
| PP − R | 3–6 only | 0.0159 | [−0.007, +0.044] (df 3) | 0.10 | [+0.009, +0.028] | 3/4 |
| PT − R | 0–2 | 0.0035 | [+0.012, +0.029] (df 2) | 0.009 | [+0.009, +0.032] | 3/3 |

Targeting ratio (seeds 0–2, where PT exists): 0.98.

Per arm over all seeds:

| arm | seeds | final S (mean) | Δ accuracy among parseable answers | answer length u40 (chars) | max letter share | gradient groups, last 10 updates |
|---|---|---|---|---|---|---|
| R | 7 | 0.7231 | +0.029 (0.022–0.035) | 546, 446, 516, 510, 599, **335**, **283** | 0.26–0.28 | 0.45–0.53 |
| PP | 7 | 0.7423 | +0.049 (0.031–0.060) | 628, 495, 466, **315**, **172**, 580, **335** | 0.26–0.29 | 0.52–0.68 |
| PT | 3 | 0.7462 | +0.053 (0.048–0.055) | 478, **175**, 450 | 0.27–0.29 | 0.68–0.74 |

### What the extension shows

1. **PP − R is now resolved across seeds: +0.019, t-CI [+0.008, +0.031],
   p = 0.007, positive in 6 of 7 seeds.** The four new seeds alone give
   +0.018, matching the first three (+0.020). The 3-seed estimate was not
   inflated by luck.
2. **The effect is still skill, not format.** Among parseable answers, PP
   gains +0.049 against R's +0.029; every run ends at ≤ 0.5% unparseable.
3. **Seed-to-seed spread is real.** One seed (6) shows no PP advantage
   (−0.001). That PP run had the smallest skill gain of any PP run (+0.031).
   The seed sd of PP − R (0.0125) is larger than the 3-seed estimate
   (0.0094), so the 3-seed t-interval was not too pessimistic.
4. **E8 holds less well than the first 9 runs suggested.** Answers under
   about 350 characters now appear in 6 of 17 runs (R s5 and s6, PP s3, s4
   and s6, PT s1; earlier 1 of 9). KL 0.05 slows the shortening but does not
   prevent it. Length does not track accuracy: PP s4, the shortest PP run
   (172 characters), is also the best (0.755). There is no letter skew in
   any run.

### Open questions for the owner
- Accept the shortening rate under E8, or test a stronger KL (e.g. 0.07–0.1)
  at the cost of some learning?
- Move to the confirmatory protocol for PP vs R, now that the development
  contrast is resolved?
- Batch-size robustness (8 vs 32 items per update, same total items) and the
  tracker under-prediction (PP's chosen items are answered 57–65% correct, not
  about 50%) remain proposed follow-ups.
