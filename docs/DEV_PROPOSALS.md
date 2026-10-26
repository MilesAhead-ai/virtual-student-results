# Development proposals for the first real-student runs (2026-10-09)

These fill `REQUIRED` fields for **development runs only**. Each entry is a
proposal for the study owner to accept, change, or replace before any
confirmatory run. All of them appear in `development_only` in
`configs/olmo3sft.grpo.dev.yaml`.

## Student (accepted 2026-10-09)

`allenai/Olmo-3-7B-Instruct-SFT` @ `e1452fc572d51966ff4aaeb25118b891eb93e549`,
chat-template SHA-256 `edbb35ef…afe6`, bf16, 4,096-token context. Rationale: `docs/STUDENT_SCREEN.md`.

## Proposed

| Field | Proposal | Why |
|---|---|---|
| `training.adapter` | `lora` | A 7B model fits one A100 40 GB with LoRA in bf16; a full fine-tune needs sharding. |
| `training.lora.rank` / `alpha` / `dropout` | 16 / 32 / 0.05 | Common LoRA defaults. Rank 16 is ample for one task's format and reasoning nudges. |
| `training.lora.target_modules` | all attention and MLP projections (`q,k,v,o,gate,up,down_proj`) | OLMo 3 module names, checked against the checkpoint. |
| `training.learning_rate` | 2e-5 for GRPO; 1e-4 for SFT arms | GRPO on LoRA is unstable at SFT-like rates. 100 updates is short, so constant after warmup. |
| `training.lr_schedule` / `warmup_steps` | `constant_with_warmup` / 5 | Arms are compared on a learning curve, and decay would flatten late differences. |
| `training.weight_decay` | 0.0 | LoRA adapters start at zero and run only 100 steps. |
| `training.max_grad_norm` | 1.0 | Standard. |
| `training.max_target_tokens` | 512 | The screen's median answer was 80 tokens, with 0–0.3% truncated at 512. |
| `training.max_consecutive_no_gradient_updates` | 5 | Abort if five updates in a row carry no gradient (all groups all-right or all-wrong). |
| `grpo.kl_coefficient` | 0.0 | Dr. GRPO uses no KL term, and it also halves the forward passes. Revisit if the format degrades. |
| `tracker.process_variance` | 0.05 | Placeholder. Fit it with `tracker fit-process-variance` on the first development runs. |

## Not yet proposed (needed for the F arms, not for outcome-only GRPO)

Tutor and judge models, `feedback.*` temperatures and the F2 token target,
sibling settings, the misconception taxonomy, `panel.repeat_weighting` for
confirmatory runs, and every `statistics.*` value.

## Timing (2-update GRPO run, one A100, 2026-10-09)

`artifacts/olmo3sft_grpo_timing/`: **~10.5 min per update**, with D
evaluated at every update. The batch is 32 presentations, measured one
by one because each selection depends on the tracker; then 32 × 8 rollouts
in batches of 32; then one LoRA step. 29 of 32 rollout groups carried
gradient (mean reward 0.56): PanelProbe targeting keeps groups mixed. D
accuracy 0.725 → 0.735 → 0.730. A 100-update run is **about 17 GPU-hours**,
so 8 arms or seeds run in parallel on the 8 GPUs in about 17 hours.

The rollouts dominate. The options, in order of payoff: generate with vLLM
and hot-swap the LoRA adapter each update (likely 5–10× on rollouts), raise
the generation batch to 64, or cap rollouts at 384 tokens (the median
answer is 80).
