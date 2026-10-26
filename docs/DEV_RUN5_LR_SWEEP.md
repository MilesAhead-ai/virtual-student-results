# Dev run 5: learning-rate sweep (2026-10-16)

**Question.** Results #4 and #5 gained only about 2 points in 40 updates.
FINDINGS #6 showed that gain is format learning: accuracy among parseable
answers did not move. Does a higher learning rate produce real learning?

**Design.** R and PP, lr ∈ {5e-5, 1e-4, 2e-4}, seed 0, slate 16, 40 updates.
Everything else matches `olmo3sft_grpo_pt16` (outcome-only Dr. GRPO, 8
rollouts, KL 0, LoRA r16, constant schedule with 5 warmup steps). The
baselines are the lr 2e-5 seed-0 R and PP runs from `olmo3sft_grpo_pt16`.
Experiment: `artifacts/olmo3sft_grpo_lr_sweep/`, small results in
`results/olmo3sft_grpo_lr_sweep/`, table in `analysis/summary.json`.
**One seed per cell: these are directions, not estimates.**

## A bug invalidated the first attempt

The student's history hash keys the generation cache and names the vLLM
adapter. It covered model, LoRA, init seed and template, **but no optimizer
settings**. Runs differing only in lr therefore had identical checkpoint
hashes at every step:

- The R runs (selection does not depend on the student) replayed the lr
  2e-5 runs from cache. All three were identical to the baseline to four
  decimals.
- PP runs sharing a vLLM server unloaded each other's adapter (HTTP 404).

Fixed in `fd41d22`: the hash now includes lr, schedule, warmup, clipping,
batch settings and the GRPO section, and there is a test for it. All earlier
experiments used a single lr, so equal hashes meant equal training and they
are unaffected. The invalid attempt is kept in
`artifacts/olmo3sft_grpo_lr_sweep_INVALID_hash_collision/`.

## Results (S, 1,600 items)

`late` is the mean accuracy at u30/u35/u40 and is less noisy than a single
checkpoint. Δparsed is the change in accuracy among parseable answers, the
skill-only part of the gain. `max letter` is the share of the most common
predicted letter at u40 (the key is uniform, 25%).

| policy | lr | u0 | u40 | peak (u) | late | Δacc | Δparsed | min len | len u40 | max letter | grad groups (last 10) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R | 2e-5 | 0.6725 | 0.6875 | 0.6887 (35) | 0.6873 | +0.015 | −0.006 | 393 | 393 | 0.28 | 0.58 |
| R | 5e-5 | 0.6725 | 0.7231 | 0.7231 (40) | 0.7140 | +0.051 | +0.028 | **9** | **9** | 0.29 | 0.25 |
| R | 1e-4 | 0.6669 | **0.6388** | 0.7219 (30) | 0.6935 | −0.028 | −0.054 | **9** | **9** | **0.49** | 0.09 |
| R | 2e-4 | 0.6806 | **0.7581** | 0.7581 (40) | **0.7429** | +0.078 | **+0.057** | 376 | 525 | 0.26 | 0.32 |
| PP | 2e-5 | 0.6725 | 0.6994 | 0.6994 (40) | 0.6931 | +0.027 | +0.007 | 404 | 404 | 0.28 | 0.79 |
| PP | 5e-5 | 0.6713 | 0.7119 | 0.7156 (35) | 0.7108 | +0.041 | +0.020 | 374 | 411 | 0.28 | 0.67 |
| PP | 1e-4 | 0.6750 | 0.7444 | 0.7444 (40) | 0.7363 | +0.069 | +0.049 | 296 | 556 | 0.30 | 0.50 |
| PP | 2e-4 | 0.6644 | 0.6950 | 0.7525 (35) | 0.7302 | +0.031 | +0.013 | 218 | 278 | **0.51** | 0.19 |

## What this shows

1. **A higher lr gives real learning.** For lr ≥ 1e-4, accuracy among
   parseable answers rises by up to +5.7 points, against about 0 at 2e-5.
   The learning signal is no longer just format.
2. **But outcome-only GRPO with KL 0 is unstable at these rates.** Three
   failure modes appear:
   - *Dropping the reasoning.* R at 5e-5 and 1e-4 converge to the 9-character
     `Answer: X`. Interestingly, direct answering scores about 0.72, above the
     base model's 0.69 with reasoning. Under this prompt and the 512-token
     cap, reasoning is not helping this student.
   - *Letter-bias collapse.* R 1e-4 and PP 2e-4 put about 50% of answers on
     one letter by u40, and accuracy falls 6–8 points in the last 5–10
     updates.
   - *Loss of gradient signal.* The share of gradient-bearing groups falls to
     0.09–0.32 in collapsing runs, so the policy becomes deterministic and
     GRPO has nothing left to learn from.
3. **PP never fully dropped the reasoning** (minimum length 218 characters),
   and PP 1e-4 is the most stable run: no collapse, 0.50 gradient groups.
   That fits PP picking items where reasoning still pays off, but it is a
   single seed.
4. **Measurement noise from vLLM batch nondeterminism.** All runs start from
   the same base model, and evaluation is greedy with the same seeds. Yet u0
   ranges from 0.664 to 0.681. Comparing u0 evaluations between runs, only
   about 46% of completions are identical, and 6.5% of items flip
   correctness. Greedy vLLM output depends on what else is in the batch, and
   two to three runs share each server. The resulting noise in the
   difference between two evaluations is sd ≈ √(0.065/1600) ≈ 0.006. That is
   larger than the PP−R and PT−R effects in #4/#5 (about 0.004–0.005).
   Earlier runs took u0 from a shared cache, which hid this. Seeds partly
   absorb it in those CIs, but a stable evaluation is needed before small
   contrasts mean anything. vLLM 0.25.1 has `VLLM_BATCH_INVARIANT=1`, which
   covers the LoRA kernels too, and is the obvious first fix to test.

## Proposed next steps (owner decisions)

- **Evaluation determinism first.** Test `VLLM_BATCH_INVARIANT=1`: re-run
  u0 twice concurrently and require identical completions; measure the
  slowdown. This is engineering, not science, so I can do it right away.
- **Stabilise training at lr 1e-4–2e-4.** Candidates:
  (a) KL > 0 to the base policy (e.g. 0.02–0.05);
  (b) a decaying lr (cosine) so late updates are small;
  (c) a reward or length term that keeps the reasoning.
  (c) changes the scientific task, so the owner should decide it.
- **Then a seeded re-test** of R vs PP (vs PT) at the chosen setting, with
  enough seeds for the now-larger effects.
- **Direct-answer baseline.** Evaluate the base model with a no-reasoning
  prompt. If 0.72 holds, the "dropping the reasoning" gains are not reading
  skill either.
