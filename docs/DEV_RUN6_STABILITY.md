# Dev run 6: stabilising GRPO at a higher learning rate (2026-10-19)

**Question.** Dev run 5 found that lr 1e-4 to 2e-4 gives real learning but
that runs at KL 0 sometimes drop their reasoning or collapse onto one
letter. Do a KL penalty or a decaying learning rate fix that, and at what
cost to learning?

**Design.** R only (its item stream does not depend on the student, so arms
differ in training alone). Seed 0, slate 16, 40 updates.
lr ∈ {1e-4, 2e-4} × {KL 0 constant, KL 0.05 constant, KL 0 cosine}.
The cosine schedule decays to 0 at u40 after 5 warmup steps. **First runs on
batch-invariant vLLM** (FINDINGS #8): the six runs' u0 completions are
identical, 1,800/1,800 on S and D, across three servers and concurrent
traffic, so differences between checkpoints are the student's, not the
server's. Experiment: `artifacts/olmo3sft_grpo_stability/`, small results in
`results/olmo3sft_grpo_stability/`, table in `analysis/summary.json`.
**One seed per cell.**

## Results (S, 1,600 items; u0 = 0.6763 in every run)

Reference points: the untrained student scores 0.687 when told to answer
directly (FINDINGS #8). `late` is the mean and sd over u30/35/40. Δparsed is
the change in accuracy among parseable answers. `max letter` is the share of
the most common predicted letter at u40 (key uniform, 25%). `grad groups` is
the share of gradient-bearing groups in the last 10 updates.

| lr | schedule | KL | u40 | peak | late (sd) | Δparsed | D u40 | answer length u0→min→u40 | max letter | grad groups | wall time |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1e-4 | constant | 0 | 0.7475 | 0.7475 | 0.7290 (0.015) | +0.055 | 0.720 | 559 → 138 → 609 | 0.27 | 0.42 | 162 min |
| 1e-4 | constant | 0.05 | 0.7031 | 0.7125 | 0.7069 (0.004) | +0.009 | 0.685 | 559 → 455 → 512 | 0.26 | 0.48 | 199 min |
| 1e-4 | cosine | 0 | 0.7006 | 0.7050 | 0.6987 (0.002) | +0.005 | 0.695 | 559 → 338 → 340 | 0.27 | 0.42 | 160 min |
| 2e-4 | constant | 0 | 0.7525 | 0.7581 | 0.7492 (0.009) | +0.059 | 0.750 | 559 → 245 → 299 | **0.34** | 0.26 | 139 min |
| 2e-4 | constant | 0.05 | 0.7294 | 0.7294 | 0.7210 (0.006) | +0.035 | 0.715 | 559 → 396 → 546 | 0.27 | 0.47 | 199 min |
| **2e-4** | **cosine** | **0** | **0.7544** | 0.7562 | **0.7544 (0.002)** | **+0.059** | **0.760** | 559 → 147 → 148 | 0.28 | 0.23 | **108 min** |

The same configs from the non-batch-invariant sweep (dev run 5) behaved
differently: lr 1e-4 KL 0 collapsed (u40 0.639, 49% one letter) where it now
ends at 0.748, and lr 2e-4 KL 0 kept 525-character answers where it now
shrinks to about 300. Under KL 0 at a constant lr the trajectory is
sensitive enough that server noise alone changed the outcome.

## What this shows

1. **lr 2e-4 learns the most, whatever the stabiliser:** +3.5 to +5.9 points
   among parseable answers, against about 0 at the old lr 2e-5. Every 2e-4
   run beats the direct-answer baseline (0.687) by 4–7 points, so this is not
   just a change of answering style.
2. **Cosine decay gives the best and the most stable result.** At 2e-4 its
   late sd is 0.002, against 0.009 for constant, and it has the best u40 on S
   and D. Shrinking the lr to 0 removes the late-update risk that produced
   the collapses in dev run 5. It is also the fastest run (108 min), because
   short answers make rollouts cheap. The price: answers shrink to about 150
   characters. Reasoning is cut short, but it does not vanish into
   `Answer: X` as in run 5.
3. **Constant lr at KL 0 is risky.** It reaches nearly the same peak, but it
   carries the most letter skew (0.34 and creeping) and the fewest gradient
   groups (0.26). Across runs 5 and 6, 2 of the 6 KL 0 constant runs at
   lr ≥ 1e-4 collapsed late.
4. **KL 0.05 preserves the reasoning and keeps the policy diverse**
   (gradient groups about 0.47, no skew), **but halves learning at 2e-4 and
   all but stops it at 1e-4.** It is also the slowest arm (+25–40% wall time,
   from the reference pass). A smaller coefficient (e.g. 0.01) is the
   untested middle ground.
5. **lr 1e-4 with cosine barely learns** (+0.005): halving the lr and then
   decaying it leaves too little total step size in 40 updates.

## Recommendation for the seeded R/PP/PT re-test

**lr 2e-4, cosine schedule, KL 0, 40 updates, batch-invariant vLLM.** It
learns the most, has the smallest late variance, and is the cheapest to run.
For the targeting question the larger, steadier learning signal matters most.
Seed variance is now the only noise source left (evaluation is
deterministic), so the re-test should start with 3 seeds × {R, PP, PT} (9
runs, about 2 h each on 6 GPUs). Extend seeds only once the seed-to-seed sd
is known.

Owner decisions this raises:
- **Short answers.** With cosine the student settles at about 150-character
  answers. If keeping full reasoning is part of the task, use KL 0.05 instead
  (half the learning) or test KL 0.01 first.
- **Cosine ties the schedule to the run length.** `training.updates` is now
  part of the optimizer identity. A longer run is a different run, not an
  extension, and late updates are small. That favours final accuracy as the
  metric (already pre-registered) over AULC.
