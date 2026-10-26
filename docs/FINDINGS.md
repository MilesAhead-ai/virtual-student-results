# Findings to date (living summary)

This is the single place for the project's conclusions. Parameters, data
versions and validity of every run are in `EXPERIMENT_REGISTRY.md`. Each entry links
the detailed report, the artifacts, and the commit. Newest first. Small
result files (configs, metrics, manifests, analyses) for every run are
committed under `results/<experiment>/`. Large data and run artifacts are
backed up as described in "Where everything is".

## Experimental conclusions (development runs, not confirmatory)

All runs below use student `allenai/Olmo-3-7B-Instruct-SFT@e1452fc`, LoRA r16,
outcome-only GRPO (8 rollouts, Dr. GRPO, KL 0), lr 2e-5, 32 presentations per
update, and the GPU panel. Primary metric from 2026-10-13: final accuracy on S.

| # | date | question | result | report |
|---|---|---|---|---|
| 10 | 2026-10-20 | With real learning (lr 2e-4, KL 0.05, E8): R vs PP vs PT, slate 16, 40 updates, 3 seeds, batch-invariant | **Targeting helps and PanelProbe matches the oracle.** Final S: R 0.7256, PP 0.7458, PT 0.7462. PT − R = +0.0206 (t-CI over seeds [+0.012, +0.029], p 0.009). PP − R = +0.0202, positive in 3/3 seeds, but its seed spread is larger (t-CI [−0.003, +0.044], p 0.065; item bootstrap [+0.008, +0.032]). PP − PT ≈ 0, targeting ratio 0.98. **The effect is skill, not format:** all arms ≤ 0.3% unparseable, but accuracy among parseable answers gains +0.053 for PP and PT vs +0.032 for R. Targeted arms keep more gradient groups late (0.61–0.74 vs 0.45–0.51). About 4× the #5 effect. Reasoning kept in 8/9 runs (PT s1 shortened to 175 characters). The built-in 3-seed bootstrap CI is just min–max; do not quote it. Next: extend R/PP to 7 seeds. | `DEV_RUN7_KL05_SEEDS.md` |
| 9 | 2026-10-19 | Do KL or a decaying lr stabilise GRPO at lr 1e-4/2e-4? R, seed 0, {KL 0, KL 0.05, cosine}, batch-invariant | **lr 2e-4 + cosine (KL 0) is best and most stable:** S 0.754 at u40 (late sd 0.002), Δparsed +0.059, D 0.760, 108 min. Answers shrink to about 150 characters but do not vanish. Constant lr at KL 0 reaches the same peak (0.758) but with letter skew 0.34 and few gradient groups; 2 of 6 such runs in #7+#9 collapsed late. KL 0.05 keeps the reasoning (about 500 characters) but halves learning at 2e-4 (+0.035) and nearly stops it at 1e-4. lr 1e-4 + cosine barely learns. All six u0 evaluations are identical (1,800/1,800), and the same configs gave different outcomes in the noisy sweep (#7), so the KL 0 constant trajectory is noise-sensitive. **Recommended for the seeded R/PP/PT re-test: lr 2e-4, cosine, KL 0.** One seed per cell. | `DEV_RUN6_STABILITY.md` |
| 8 | 2026-10-19 | Can evaluation be made deterministic, and what does the untrained student score when it answers directly? | **Batch-invariant vLLM fixes the noise.** Two passes over S, one in item order on an idle server and one shuffled under random background traffic: batch-invariant gives 100% identical text and 0 flips, for the base model and for a trained LoRA (R lr 2e-4 u40). A normal server gives 35–45% identical text and 4.5–7% flips. Cost: about 1.5× generation time (1,354 vs 2,027 tok/s). Live parity with the HF trainer is unchanged (same answer 0.84–0.91 in both modes, the bf16 floor). Now the default: `start_vllm.sh`, plus `student.vllm_batch_invariant`, which keys the cache and is probed at startup (`a0ad1ee`). **Direct-answer baseline:** told not to explain, the untrained student scores 0.687 on S (standard prompt: 0.676 strict, 0.695 if parsed). So the GRPO runs that dropped their reasoning and reached about 0.72 learned something beyond answering style (about +3.5 points). Side check: all 14,052 generated items' keys still point to the raw correct choice. A re-import permutes choice positions, so stored answers from before the Oct 12 import cannot be compared letter for letter. | `artifacts/determinism/`, `results/determinism/` |
| 7 | 2026-10-16 | Does a higher lr give real learning? R, PP × lr {5e-5, 1e-4, 2e-4}, seed 0 | **Yes, but unstably.** Accuracy-if-parsed gains up to +0.057 (R 2e-4, final 0.758; PP 1e-4 +0.049, the most stable run) vs about 0 at 2e-5. Failure modes at KL 0: the student drops its reasoning (R 5e-5/1e-4 → `Answer: X`, which still scores about 0.72 > the 0.69 base with reasoning), letter-bias collapse (R 1e-4, PP 2e-4 put about 50% on one letter, −6 to −8 points late), gradient groups fall to 0.09–0.32. **Two infrastructure problems surfaced.** (1) The history hash omitted optimizer settings, so the first sweep replayed cached lr 2e-5 runs (fixed `fd41d22`; earlier experiments unaffected). (2) Greedy vLLM evaluation is not batch-invariant: the same model's u0 differs by up to 0.017 across runs, 6.5% of items flip, and the difference noise sd ≈ 0.006 exceeds the #4/#5 effects. One seed per cell. | `DEV_RUN5_LR_SWEEP.md` |
| 6 | 2026-10-16 | Re-analysis of #4 and #5: what does the ~2-point gain consist of? (15 runs, lr 2e-5) | **The gain is almost all format learning.** S accuracy rises by +0.0188 on average. The unparseable rate falls from about 3.0% to 0.3% (parse recovery 0.0277). Recovering those answers at the parsed-accuracy rate (0.695) predicts +0.0192. Accuracy *among parseable answers* changes by −0.0005 (sd 0.0047). About half of the unparseable answers at u0 are markdown (`**Answer: B**`), which the strict `answer-line-v1` parser rejects. Answers also shorten, from 560 to 340–450 characters. Consequence: outcome-only GRPO at lr 2e-5 for 40 updates has not yet been shown to teach any reading skill, so the R/PP/PT contrasts in #4/#5 mostly compare format-learning speed. From now on, report accuracy-if-parsed alongside strict accuracy (`scripts/run_curves.py`). | this file |
| 5 | 2026-10-14 | Does *any* targeting help? R vs PP vs PT, slate 16, 40 updates, 3 seeds | PT − R = +0.0048 (3/3 seeds positive); PP − R = +0.0042 [−0.0025, +0.0119], unresolved; targeting ratio 0.87. All arms gain ~2 points. **Under outcome-only GRPO, targeting is worth about half a point; the learning signal itself is small.** | `DEV_RUN4_PT16.md` (`671a903`) |
| 4 | 2026-10-13 | PP vs R on the topped-up pool, slate 64, 40 updates, 3 seeds | PP − R final S accuracy = 0.0000 [−0.0025, +0.0044]. PP is in the target band 73–94% of the time and has more gradient-bearing groups (0.87 vs 0.69), but does not learn faster. | `DEV_RUN3_SHORT40_POOLV1.md` (`5f268c5`) |
| 3 | 2026-10-11 | 40-update R vs PP on the easy pool, 3 seeds | ΔAULC −0.0012; PP finished higher on D in 3/3 seeds and gained more on mid/hard D tertiles. That did not replicate on S in #4. AULC and final accuracy disagreed, which led to pre-registering final accuracy. | `DEV_RUN2_SHORT40.md` (`6aa3e7c`) |
| 2 | 2026-10-10 | 100-update R vs PP on the original pool, 2 seeds | ΔAULC +0.0006. **PP ran out of hard items** (selection without replacement): in band 58% early, then picking easier items than R. This drove the hard-item top-ups. | `DEV_RUN1_RESULTS.md` (`11470e3`) |
| 1 | 2026-10-09 | Which student? | OLMo 3 7B (Instruct and Instruct-SFT) sits mid-panel (θ ≈ 0.75–0.93). **PanelProbe difficulty predicts its correctness out of panel** (Spearman −0.39 to −0.45). OLMo 2 7B/1B are unusable. | `STUDENT_SCREEN.md` (`c1ea25d`) |

## Panel and item-bank conclusions

- **The GPU panel is consistent with the CPU panel.** Item difficulty on 706
  W items correlates r = 0.80 (pure-noise retest expectation 0.60). Decision:
  GPU panel throughout. `ITEM_GENERATION_PLAN.md` §7.
- **A single panel pass is noisy.** Item-difficulty test-retest is r = 0.71.
  Every item is scored three times, which gives Spearman–Brown ≈ 0.88.
  Repeat weighting `mean` vs `binomial` is an open choice; strong models
  repeat themselves 93–94% of the time. §9.
- **Silent panel failures exist and need guards.** A partially CPU-offloaded
  model emits nonsense; phi3 degrades on long-running servers; weak models
  fail canaries by chance. `scripts/rescore_with_canary.py` covers all three. §8.
- **AI items land easy; hard ones need a screen with fresh re-scoring.**
  Asked-D5 → b > 0.5 yield is 4% (central_ideas) to 59% (transitions). Only
  35–82% of screen survivors stay hard on fresh passes (winner's curse).
  §11. This replicates the paper's negative result at scale.
- **Final pool_v1**: 14,052 generated items + 706 W. Per skill P+P+ has
  298–522 items with b > 0.5. Median b is −0.08, harder than W (−0.30).
  Split file `data/splits/pool_v1_dev.json`, lock `6147da9a…`. §11.
- **Generation economics**: Opus 5 about $0.042–0.06 per item, Sonnet 5.5 key
  check about $0.009 per item; Bedrock caps throughput at about 30 items/min
  account-wide. Total spend to date about $2,400.

## Engineering conclusions

- vLLM generation with hot-swapped LoRA is 3.6× faster than Transformers
  generation and matches it (91.5% same answer on base, 95.8% with an adapter). `2c3c01b`.
- Gradient checkpointing disables the KV cache; generation must pass
  `use_cache=True` (otherwise about 50 s per answer). `bb3f9a2`.
- Current Claude models reject `temperature`; tutor/judge configs must set it null.

## Where everything is

| what | where |
|---|---|
| Spec, plan, decisions | `docs/virtual_student_implementation_spec.md`, `docs/M0_PLAN.md`, `docs/ITEM_GENERATION_PLAN.md`, `docs/OPEN_DECISIONS.md`, `docs/DEV_PROPOSALS.md` |
| Per-run small results (git) | `results/<experiment>/<run>/{resolved_config.yaml,metrics.json,manifest.json,status.json}`, `results/<experiment>/analysis/` |
| Full run artifacts (not in git) | `artifacts/<experiment>/` (checkpoints, parquet tables, events) |
| Item data (not in git) | `data/raw/pool_v1/{P1..P5,pilot,gpu_W,repeat_r2,repeat_r3}`, `data/processed/pool_v1` |
| Backups (same machine) | `/home/ubuntu/backups/virtual-student/2026-10-16/` (zstd tarballs of `data/raw`, `data/processed`+splits+locks, `artifacts` without checkpoints; `SHA256SUMS`) |
| Generator / panel code | sat-reading-platform, branch `pool-generation` (`scripts/calibration/`) |
| Stopped service | `docs/STOPPED_SERVICES.md` (vLLM 70B, restart command) |
