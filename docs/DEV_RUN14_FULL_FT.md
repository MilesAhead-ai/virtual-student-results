# DEV_RUN14: full fine-tuning (development)

**Status: lr pilot done (lr 1e-5 chosen); stage 2 running since 2026-11-24 21:15 UTC.** Owner's request after FINDINGS #48:
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

### Pilot results (S, seed 0, 20 updates; base: focus 0.325, other skills 0.757, 563 characters)

| lr | focus u5 / u10 / u15 / u20 | other skills u20 | unparseable u20 | length u20 |
|---|---|---|---|---|
| 3e-6 | 0.350 / 0.384 / 0.438 / 0.412 | 0.774 | 0.5% | 569 |
| **1e-5** | 0.400 / 0.388 / 0.409 / **0.422** | **0.787** | 0.9% | 811 |
| 3e-5 | 0.428 / 0.409 / 0.378 / 0.403 | **0.691** (−6.6, fails) | 1.6% | 761 (340 at u10) |

**1e-5 is chosen.** It is the largest lr meeting the stability criteria, and its focus accuracy at u20
(0.422) exceeds LoRA's (0.375). Its answers lengthen (811 characters at u20), which needs watching over
40 updates. Single seed: the lr arms are not compared with each other beyond this choice.

**Parity** (`scripts/check_full_parity.py`, 40 D items, greedy, 64 tokens): vLLM serving the run's final
weights against Transformers on the saved weights gives 23/40 identical completions and 39/40 with the
same first 40 characters. The base model gives 23/40 and 36/40. The difference is ordinary vLLM-vs-HF
numerics, so the weight sync is correct.

## Stage 2 (running)

DEV_RUN13's comparison with full fine-tuning at lr 1e-5: grpo vs note (every item gets a note
group, distilled into the plain question), seeds 0–3, 40 updates. Configs:
`artifacts/olmo3sft_full_focus/configs/` (`make_full_ft_configs.py focus`); preflight passed.

Four slots run one seed each, grpo then note:
- GPU 1 + server 8110 (GPU 0);
- GPU 3 + server 8114 (GPU 4);
- GPU 5 + server 8116 (GPU 6);
- GPU 2 + server 8117 (GPU 7).

The LoRA servers on GPU 0/1 and the Qwen3-8B bench server were stopped to free the GPUs.

Analysis, as DEV_RUN13 (`scripts/analyze_note_focus.py --exp artifacts/olmo3sft_full_focus`):
- **Primary:** S boundaries + transitions at u40 without notes, note − grpo paired by seed.
- **Secondary:** the other eight skills, answer length, and the note groups' correct rollouts.

Reading, fixed now: a clearly positive note − grpo would mean the adapter's capacity was what blocked
internalisation (DEV_RUN13: −0.005 with LoRA). If it is null again, capacity is ruled out as the
explanation for this student.
