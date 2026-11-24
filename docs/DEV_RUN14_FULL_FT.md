# DEV_RUN14: full fine-tuning (development)

**Status: learning-rate pilot running since 2026-11-24 18:20 UTC.** Owner's request after FINDINGS #48:
try full fine-tuning (all weights trainable) before switching the student to Qwen.

## Why

Every attempt to turn guidance into learning failed with LoRA r16 (FINDINGS #33–#48), although the
guidance's content works at test time (CONFIRMATORY_NB). One untested explanation is the adapter's
capacity. Full fine-tuning removes it.

## Engineering (commit `009530d`)

- `training.adapter: full`, with a `training.full` block:
  - **Trainer GPU:** bf16 weights and gradients, peak about 29.9 GB on OLMo-3-7B.
  - **CPU:** fp32 master weights and AdamW. Gradients pass through pinned buffers into fp32 CPU
    accumulators every 8 sequences.
  - **KL reference:** the base weights, kept as a pinned CPU copy and swapped in for reference
    log-probs.
- **Generation:** every run has its own vLLM server (`FULL=1 scripts/start_vllm.sh`, dev mode). After
  each update the weights are written to `/dev/shm` and reloaded in place (about 20 s). Tested first:
  a perturbed model's reload changes the output, and reloading the base restores it token for token.
- **Checkpoints and resume:** only the final weights are written to disk (14 GB) and no optimizer
  state is kept, so a failed full run restarts from scratch.
- **Tests:**
  - the CPU-offloaded step equals plain AdamW;
  - the flush interval does not change the result;
  - the reference swap restores the policy exactly;
  - 132 tests pass.
- **Smoke** (2 updates): complete. Evaluation changes with the weights. At update 1, still in
  warmup (lr 2e-7), the bf16 weights did not change: the step was below bf16 resolution, while the fp32
  master accumulated it.
- **Speed:** about 10 minutes per update, three runs in parallel. The gradient flush takes about
  220 s; it was 468 s before the pinned buffers.

## Stage 1: learning-rate pilot

Full fine-tuning usually uses lr ≈ 1e-6 over thousands of steps. Here a run has 20–40 optimizer
steps, so the learning rate must be chosen.

The setup is focused GRPO on boundaries + transitions, as DEV_RUN13's grpo arm, with seed 0 and
20 updates. The arms are lr 3e-6, 1e-5 and 3e-5. Configs: `artifacts/olmo3sft_full_lr/configs/`
(`scripts/make_full_ft_configs.py`).

Criteria, fixed before the results:
- Pick the largest lr that stays stable:
  - S unparseable answers ≤ 2%;
  - answer length within 0.5–2× of the base;
  - the other eight skills not more than 3 points below the base.
- Prefer an lr whose focus-skill accuracy at u20 is at least LoRA's (0.375; base 0.334).

## Stage 2 (planned)

DEV_RUN13's comparison with full fine-tuning at the chosen lr: grpo vs note (every item gets a note
group, distilled into the plain question), seeds 0–3, 40 updates; S without notes, boundaries +
transitions. About 8–10 h per run.
