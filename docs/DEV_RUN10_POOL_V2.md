# Dev run 10: OLMo-3 on pool v2, R vs PP16, 100 updates (2026-11-04)

Plan: `PLAN_HARD_POOL.md` step 3 (E17). Arms R and PP16 × seeds 0–3, 100
updates, settings as DEV_RUN9 (lr 2e-4 constant, KL 0.05, θ₀ 1.0) except:
pool v2 (`data/processed/pool_v2_wp`, lock `4f468bd2…`, calibration
`pool-v2-wp`, panel v2 of 15 members) and answer parser v2. Evaluated on S
(1,600, the same items as DEV_RUN9) and D every 5 updates; E1 untouched.
All 8 runs completed (0 failures, 0 retries; 17:02–02:02 UTC).
Experiment: `artifacts/olmo3sft_grpo_pool_v2/`; small results:
`results/olmo3sft_grpo_pool_v2/`; analysis:
`results/olmo3sft_grpo_pool_v2/analysis/pool_v2_vs_long100.txt`
(`scripts/analyze_dev_long.py`, which also re-scores DEV_RUN9 with parser v2
so the two compare on one footing).

## Main result: the harder pool did not extend PP's advantage

Mean S accuracy (parser v2):

| update | 20 | 40 | 60 | 80 | 100 |
|---|---|---|---|---|---|
| R, pool v2 | 0.711 | 0.724 | 0.750 | 0.761 | 0.761 |
| PP16, pool v2 | 0.716 | 0.741 | 0.757 | 0.772 | 0.772 |
| R, pool v1 (DEV_RUN9) | 0.705 | 0.723 | 0.747 | 0.768 | 0.759 |
| PP16, pool v1 (DEV_RUN9) | 0.705 | 0.742 | 0.758 | 0.773 | 0.779 |

PP16 − R (t-interval over 4 seeds, positive seeds):

| | u40 | u60 | u80 | u100 | AULC u0–100 |
|---|---|---|---|---|---|
| pool v2 | **+0.017** [+0.002, +0.032], 4/4 | +0.007 [−0.022, +0.036], 3/4 | +0.011 [−0.010, +0.032], 3/4 | +0.012 [−0.016, +0.039], 3/4 | +0.006 [−0.011, +0.022], 3/4 |
| pool v1 | **+0.019** [+0.004, +0.034], 4/4 | +0.011 [−0.008, +0.030], 3/4 | +0.005 [−0.009, +0.020], 3/4 | +0.020 [−0.013, +0.053], 3/4 | +0.013 [+0.002, +0.025], 4/4 |

- The u40 advantage replicates again (+0.017; C1 +0.019).
- After u40 the picture is the same as on pool v1: positive point estimates,
  intervals that include 0. The step-3 success criterion (PP − R positive at
  u80–u100) is **not met**.
- Two PP runs dipped at u90 (s0 0.711; s3 0.701 with 12% unparseable) and
  recovered by u95–u100. On pool v1 the collapse was in an R run (s1 at u90).

## Why: hard items now exist for two skills only

Selected items, PP16, last quarter (u76–100):

| skill | greedy success v1 → v2 | mean b v1 → v2 |
|---|---|---|
| **inferences** | 0.88 → **0.66** | +0.88 → **+2.04** |
| **command_of_evidence** | 0.80 → **0.55** | +0.84 → **+1.74** |
| central_ideas | 0.97 → 0.98 | +0.61 → +0.94 |
| rhetorical_synthesis | 0.97 → 0.95 | +0.65 → +0.83 |
| text_structure | 0.93 → 0.94 | +1.00 → +1.13 |
| cross_text_connections | 0.86 → 0.88 | +0.66 → +0.84 |
| words_in_context | 0.67 → 0.70 | +1.23 → +0.82 |
| transitions | 0.50 → 0.49 | +0.64 → +0.32 |
| form_structure_sense | 0.51 → 0.47 | +0.26 → −0.41 |
| boundaries | 0.41 → 0.36 | −0.37 → −0.63 |

- **Where the top-up added hard items, the mechanism works:** PP's late
  selections on inferences and command_of_evidence moved close to the target
  success rate (0.55–0.66), with mean b around 2.
- **On the five other reading skills nothing changed:** the student still
  answers 86–98% of the items PP picks late in training, because the pool
  has few items above the student's level there (FINDINGS #19).
- Overall, last-quarter greedy success on PP's items: 0.70 (v1: 0.75), still
  well above the 0.5–0.6 the plan asked for.
- Gains on S for the two improved skills are not visible: PP16 − R averaged
  over u80–u100 is +0.028 on inferences and +0.001 on command_of_evidence
  (160 S items per skill, noisy; DEV_RUN9's per-skill late contrasts are
  inflated by its R collapse at u90 and are not a fair baseline).

## Conclusion

Harder items make PP target them as intended, but adding them to two of the
ten skills did not change the overall result. Through u40 PP learns faster;
after that R catches up on pool v2 as on pool v1. A larger late-training
advantage would need hard items on the student's strongest skills too
(central_ideas, rhetorical_synthesis, text_structure, cross_text), and the
pilot found Opus 5.5 cannot reliably write those (FINDINGS #17).
