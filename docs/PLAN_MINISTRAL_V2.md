# Plan: replication on a second student (Ministral-8B) → confirmatory v2

Written 2026-10-31 so the work can be resumed from this file alone. Update the
status column as steps finish; record results in FINDINGS/registry as usual.

## Where we are

| step | status | record |
|---|---|---|
| Confirmatory v1 (OLMo-3-7B-Instruct-SFT): PP − R +0.019 on E1, H1/H2 supported | done 10-29 | `CONFIRMATORY_V1_RESULTS.md`, C1 |
| Second student chosen: Ministral-8B-Instruct-2410 @ `2f494a1` | done 10-30 (E11) | `STUDENT_SCREEN_2.md` |
| Integration: token-id prompts, tokenizer checks, parity | done 10-30 | commit `bd93594`, FINDINGS #13 |
| LR check: lr 1e-4 (half of OLMo's) | done 10-30 | F13, FINDINGS #13 |
| Dev R vs PP, 4 seeds | done 10-30 | F14, FINDINGS #14 |
| **Step A: parser v2** | done 10-31 | `evaluation.answer_parser`, commit below |
| **Step B: dev R vs PP, 8 seeds, parser v2** | done 10-31: **no PP advantage** (AULC −0.001 [−0.010, +0.008]) | F15, FINDINGS #15 |
| **Step C: choose the v2 primary metric, pre-register, freeze** | **on hold: owner to decide whether to run v2 at all, given B** | — |
| **Step D: run and analyse confirmatory v2** | todo | — |

What F14 showed, and why this plan exists:
- On Ministral, PP leads early (u10–u25, about +1.5 to +3 points on S), but
  both arms plateau near 0.78–0.79 by u40. Final accuracy at u40 shows no
  advantage (PP − R −0.008, 4 seeds). The benefit of targeting shows up as
  **learning speed**. OLMo had not plateaued by u40, so there the speed
  showed up as a higher final accuracy.
- A **format attractor** distorts the strict metric. Runs intermittently write
  `Answer: <C>`, copying the prompt's `Answer: <A|B|C|D>`, and sometimes the
  template itself. The strict parser (`answer-line-v1`) rejects these, so S
  drops to 0.00–0.30 for a checkpoint or two. This hit 3/8 runs.

## Step A — parser v2 (engineering)

- Add `answer-line-v2`: as v1, plus a single letter in angle brackets
  (`Answer: <C>`). The literal template `Answer: <A|B|C|D>` and anything else
  stay unparseable. The prompt is unchanged (spec §15.2).
- Make it a config value (`evaluation.answer_parser`, default `answer-line-v1`),
  used for **both** the GRPO reward and evaluation, and therefore part of the
  run identity. All v1 / OLMo configs keep v1, so earlier results are unchanged.
- Unit tests for both parsers. Generations stay cacheable (parsing happens
  after generation), but a different reward changes training, so v2 runs get
  new run ids.

## Step B — dev R vs PP on Ministral, 8 seeds (GPU only)

- Settings: Ministral-8B, lr 1e-4 constant, KL 0.05, slate 16, θ₀ 1.0,
  40 updates, batch-invariant vLLM with token-id prompts, parser v2, S + D
  evaluated every 5 updates.
- R and PP × seeds 0–7 (16 runs, about 5–6 h with the queue at 2 per GPU on
  GPUs 3–7). The 4-seed F14 runs used parser v1 and are not reused.
- Report:
  - PP − R at every checkpoint (u5…u40);
  - **AULC** (mean S accuracy over u0…u40);
  - updates needed to reach R's u40 level;
  - accuracy among parseable answers;
  - incidence of format collapse;
  - answer length;
  - gradient-bearing groups.
  Use t-intervals over seeds (registry §4).
- Purpose: (1) confirm PP's early lead across 8 seeds; (2) check that
  parser v2 removes most dips; (3) estimate the per-seed SD of each candidate
  metric for the power calculation.

## Step C — confirmatory v2 pre-registration (owner decisions)

The owner chooses the primary metric from B, *before* any v2 run. Candidates:
1. **AULC on E1** (mean accuracy over the 9 checkpoints u0…u40): captures
   speed, uses all checkpoints. E7 chose final accuracy for v1 because AULC
   and final accuracy disagreed at the time. For v2 the question is
   explicitly about speed.
2. **E1 accuracy at a fixed early checkpoint** (e.g. u20).
3. **Final E1 accuracy at u40** (as v1). F14 suggests no effect on this metric.

Draft defaults, to confirm:
- H1: PP − R on the chosen metric, paired t over seeds, two-sided α 0.05.
- Fresh seeds 200+; n from B's SD with ≥ 80% power at a conservative δ.
- PT optional.
- Same data release as v1: pool-v1-final, split lock `6147da9a`, topic twins,
  and the exposure and twin-free checks.
- E1 note: E1 was read once for v1, for OLMo. No setting was tuned on E1, and
  the Ministral question (a different student) is separate. Reusing E1 is
  acceptable; the pre-registration states it.
- Parser v2 and token-id prompts are listed as frozen settings.
- Write `docs/PREREGISTRATION_CONFIRMATORY_V2.md` and
  `configs/confirmatory/v2/` (+ `FROZEN.json`), tag `confirmatory-v2-frozen`,
  commit, push and publish **before** launch.

## Step D — run and analyse v2

As v1: `scripts/run_queue.py` (health checks, same-seed retries), E1
blackout until all runs are done, then an analysis script committed before
it is run. Then `CONFIRMATORY_V2_RESULTS.md`, FINDINGS, registry, publish.

## Operational notes for Ministral

- Servers: `STUDENT=ministral8b scripts/start_vllm.sh <GPU> <PORT>` (tokenizer
  mode mistral). Configs must set `student.vllm_prompt_format: token_ids`.
- Check servers with a real `/v1/completions` call before launching
  (`run_queue.py` does). Watch `journalctl -k | grep Xid`.
- Base config to copy: `results/ministral8b_grpo_dev_rpp/configs/r_s0.yaml`
  (add `evaluation.answer_parser: answer-line-v2` once step A lands).
- When comparing runs across experiment dirs, match by config (lr, seed),
  never by glob alone: several lrs share a seed in `ministral8b_grpo_lr_check`.
