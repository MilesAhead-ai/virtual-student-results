# Experiment registry

The single global record of every experiment: what ran, with which
parameters, on which data, whether it is still valid, and what it found.
Use it to keep later runs consistent with earlier ones.

- **This file** is the source of truth for *parameters, data versions,
  validity and headline numbers*. The per-run tables at the end are
  generated from the committed run files; never edit them by hand.
- **`FINDINGS.md`** holds the *interpretation* (one row per finding).
- **`DEV_RUN*.md`** and the other reports hold the full analysis of each experiment.
- **`OPEN_DECISIONS.md`** records the owner's decisions (E1–E8) that fixed the settings.

**After every experiment:** copy the small run files to `results/<experiment>/`
(as in earlier experiments), then run `uv run python scripts/build_registry.py`
while `artifacts/` is still present. Add a row to the index below (and to
FINDINGS.md), commit all of it together, push to
`MilesAhead-ai/virtual-student` (private), and run
`scripts/publish_results.sh` to update the public mirror
[`MilesAhead-ai/virtual-student-results`](https://github.com/MilesAhead-ai/virtual-student-results).

## 1. Fixed setup (unchanged unless stated)

| component | value | since |
|---|---|---|
| Student | `allenai/Olmo-3-7B-Instruct-SFT` @ `e1452fc572d51966ff4aaeb25118b891eb93e549`, bf16, chat template sha `edbb35ef…afe6` | 2026-10-09 (STUDENT_SCREEN.md) |
| Adapter | LoRA r16, α32, dropout 0.05, all attention and MLP projections | 2026-10-09 |
| Training | outcome-only (`feedback.condition: outcome`), Dr. GRPO, 8 rollouts at T 1.0, ≤ 512 completion tokens, 32 items per update, AdamW, wd 0, clip 1.0, warmup 5 | 2026-10-09 |
| Reward | correct 1, wrong 0, unparseable −0.1 | M0 default |
| Prompt | `prompts/student_answer.txt` ("Think briefly, then … `Answer: <A\|B\|C\|D>`") | M0 |
| Parser | `answer-line-v1`: the last non-blank line must be `Answer: X`; markdown (`**Answer: B**`) is unparseable | M0 |
| Evaluation | greedy, ≤ 512 tokens, every 5 updates, dense on S and D | 2026-10-13 (E7) |
| Schedule | rotating round-robin over the 10 SAT R&W skills | M0 |
| Panel | 8 Ollama models on GPU, 3 passes per item, per-skill MAP IRT, calibration `pool-v1-gpu3`, repeat weighting `mean` | 2026-10-06 (E3) |
| Generation backend | vLLM 0.25.1 server + hot-swapped LoRA, training in HF/PEFT | 2026-10-09 |
| Item-selection policies | R random; PP PanelProbe difficulty targeted to the band; PT oracle via 4 student rollouts per candidate | M0 / dev run 4 |

### Data versions (from each run's manifest)

| label | items.parquet sha | split lock | contents | primary set | used by |
|---|---|---|---|---|---|
| **pool-P1P2** | `d3651289` | `3b17766d` | 8,786 items (P1+P2 + W), 1 split file `pool_v1_dev_p1p2.json` | D (200) | dev, dev_vllm, short40, timing* |
| **pool-v1-final** | `b4e060d6` | `6147da9a` | 14,052 generated + 706 W; P+P+ ≥ 298 items with b > 0.5 per skill; `pool_v1_dev.json` | S (1,600) | short40_v2 and everything after |

**Runs on different data versions are not comparable**: their S/D sets
differ, and a re-import permutes choice positions.

## 2. Experiment index

Validity: **valid** means the numbers stand; **superseded** means the
numbers stand but a later experiment answers the question better;
**invalid** means do not use.

| # | experiment (`artifacts/`, `results/`) | date | question | arms × seeds | settings that differ from §1 | data | eval mode | validity | headline | report | commit |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F1 | `student_screen` (no training) | 10-09 | Which student? | 4 models | — | pool-P1P2 | HF greedy | valid | OLMo-3-7B-Instruct-SFT sits mid-panel; PanelProbe b predicts its correctness (ρ −0.39 to −0.45) | STUDENT_SCREEN.md | `c1ea25d` |
| — | `m0_dev_satbank` | 10-02 | M0 software end-to-end | dummy | dummy backend | sat bank | — | valid (software only) | pipeline runs end to end | M0_PLAN.md | `8d401cd` |
| — | `olmo3sft_grpo_dev` | 10-09 | First real run (HF generation) | R, PP × 2 | lr 2e-5, slate 64, 100 upd | pool-P1P2 | HF | **invalid** (stopped, `failed_terminal`) | too slow (10.5 min/update); replaced by vLLM | — | — |
| — | `olmo3sft_grpo_timing`, `_timing_vllm` | 10-09 | Throughput | 1 + 1 | 2 updates | pool-P1P2 | HF / vLLM | valid (timing only) | 10.5 → 2.7 min/update with vLLM | — | `2c3c01b` |
| F2 | `olmo3sft_grpo_dev_vllm` | 10-10 | PP vs R, 100 updates | R, PP × 2 | lr 2e-5, slate 64, 100 upd, AULC on D | pool-P1P2 | vLLM, not invariant | superseded | ΔAULC +0.0006; PP ran out of hard items | DEV_RUN1_RESULTS.md | `11470e3` |
| F3 | `olmo3sft_grpo_short40` | 10-11 | PP vs R, 40 updates | R, PP × 3 | lr 2e-5, slate 64, AULC on D | pool-P1P2 | not invariant | superseded | ΔAULC −0.0012 | DEV_RUN2_SHORT40.md | `6aa3e7c` |
| F4 | `olmo3sft_grpo_short40_v2` | 10-13 | PP vs R on the final pool | R, PP × 3 | lr 2e-5, slate 64 | pool-v1-final | not invariant | valid, but **format-only learning** (F6) | PP − R final S 0.0000 | DEV_RUN3_SHORT40_POOLV1.md | `5f268c5` |
| F5 | `olmo3sft_grpo_pt16` | 10-14 | Does any targeting help? | R, PP, PT × 3 | lr 2e-5, slate 16 | pool-v1-final | not invariant | valid, but **format-only learning** (F6) | PT − R +0.0048, PP − R +0.0042 | DEV_RUN4_PT16.md | `671a903` |
| F6 | re-analysis of F4 and F5 | 10-16 | What is the ~2-point gain? | 15 runs | — | pool-v1-final | — | valid | gain = parse recovery; accuracy among parseable answers −0.0005 | FINDINGS.md | `f9f4868` |
| — | `olmo3sft_grpo_lr_sweep_INVALID_hash_collision` | 10-16 | lr sweep, first attempt | R, PP × 3 lr | — | pool-v1-final | not invariant | **invalid** (history-hash bug: replayed lr 2e-5 cache) | — | DEV_RUN5_LR_SWEEP.md | fixed `fd41d22` |
| F7 | `olmo3sft_grpo_lr_sweep` | 10-16 | Does a higher lr learn? | R, PP × lr {5e-5, 1e-4, 2e-4} × 1 | lr varies | pool-v1-final | **not invariant** (noise sd ≈ 0.006) | valid in direction; single noisy trajectories | real learning at ≥ 1e-4, but reasoning is dropped / letters collapse | DEV_RUN5_LR_SWEEP.md | `bf622ed` |
| F8 | `determinism` (no training) | 10-19 | Deterministic eval? Direct-answer baseline? | — | — | pool-v1-final | both | valid | batch-invariant: 0 flips; direct answer 0.687 on S | FINDINGS.md | `a0ad1ee`, `52dd4c2` |
| F9 | `olmo3sft_grpo_stability` | 10-19 | KL or cosine to stabilise? | R × {1e-4, 2e-4} × {KL 0, KL 0.05, cosine} × 1 | lr, KL, schedule vary | pool-v1-final | **invariant** | valid (1 seed) | 2e-4 cosine best (0.754, ~150-char answers); KL 0.05 keeps reasoning, about half the gain | DEV_RUN6_STABILITY.md | `e7e741c` |
| F10 | `olmo3sft_grpo_kl05_seeds` | 10-20, ext. 10-27 | R vs PP vs PT with real learning | R, PP × 7; PT × 3 | **lr 2e-4, KL 0.05, slate 16, 40 upd (E8)** | pool-v1-final | **invariant** | **valid; current reference** | PP − R +0.0192 [+0.008, +0.031] (7 seeds, p 0.007); PT − R +0.0206 [+0.012, +0.029] (3 seeds); ratio 0.98 | DEV_RUN7_KL05_SEEDS.md | `344209c`, `936fefb` |

## 3. Current reference settings

Use these for new development runs unless the owner decides otherwise. The
reference config to copy is
`results/olmo3sft_grpo_kl05_seeds/configs/r_s0.yaml`; change only
`experiment_id`, `root_seed`, `selection.policy` and `student.vllm_url`.

| setting | value | reason |
|---|---|---|
| `training.learning_rate` | 2.0e-04 | lr 2e-5 learns only format (F6); 2e-4 learns skill (F7, F9) |
| `training.lr_schedule` | constant_with_warmup (5 steps) | cosine shortens answers to about 150 characters, rejected by E8 |
| `grpo.kl_coefficient` | 0.05 | keeps full reasoning (E8, F9) |
| `training.updates` | 40 | dev budget (E7) |
| `selection.candidate_slate_size` | 16 | F5, F10 |
| `student.generation_backend` / `vllm_batch_invariant` | vllm / true | deterministic evaluation (F8) |
| `evaluation.primary_set` / `statistics.primary_metric` | s / final_accuracy | E7 |
| data | pool-v1-final (`b4e060d6`, lock `6147da9a`) | final pool |

## 4. Comparability rules

1. Compare final accuracy only within one data version (§1).
2. Runs at lr 2e-5 (F2–F5) measure format learning, not skill (F6). Do not
   pool them with lr ≥ 1e-4 runs.
3. Runs before batch-invariant evaluation (everything up to F7) carry about
   0.006 of extra evaluation noise per contrast. Their u0 often came from a
   shared cache and hid it.
4. With fewer than about 5 seeds the built-in bootstrap CI in
   `analysis/report.md` is just the min–max of the seed differences. Quote
   a t-interval over seeds instead (as in DEV_RUN7).
5. Identical config → identical run id → cache replay. Under batch-invariant
   generation that is an exact reproduction (e.g. the F10 R seed 0 replay of
   F9's lr 2e-4 KL 0.05 run).

## 5. Per-run parameters and results (generated)

Status, parameters and initial/final/AULC come from `results/`. The *
columns come from `artifacts/` and are cached in `results/registry/runs.csv`.
"initial", "final" and "AULC" are on the run's primary set (D for pool-P1P2,
S for pool-v1-final).

<!-- BEGIN GENERATED: scripts/build_registry.py -->

Generated from `results/*/*/` (61 runs). Full per-run data: `results/registry/runs.csv`.
Columns marked * need the full artifacts and are cached in the CSV.

### `m0_dev_satbank`

Shared: student=dummy-student@dummy-v, generation=dummy, batch_invariant=False, method=sft, lr=REQUIRED, schedule=REQUIRED, warmup=REQUIRED, updates=4, kl=REQUIRED, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=rREQUIRED/aREQUIRED, batch_items=32, slate=8, primary_set=d, primary_metric=aulc, items_sha=ba034e57, split_lock=e4e7c078.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-f4-sft-s000-f1105f40` | complete | pp | 0 | 0.6392 | 0.7526 | 0.7152 | +0.113 | 0.0%→0.0% | 49 | 0.29 | — | 0 |

### `olmo3sft_grpo_dev`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=transformers, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=100, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=64, primary_set=d, primary_metric=aulc, items_sha=d3651289, split_lock=3b17766d.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-4f19407e` | failed_terminal | pp | 0 | — | — | — | — | — | — | — | — | — |
| `pp-outcome-grpo-s001-0ba70175` | failed_terminal | pp | 1 | — | — | — | — | — | — | — | — | — |
| `r-outcome-grpo-s000-33f4d0e6` | failed_terminal | r | 0 | — | — | — | — | — | — | — | — | — |
| `r-outcome-grpo-s001-f87fcf5f` | failed_terminal | r | 1 | — | — | — | — | — | — | — | — | — |

### `olmo3sft_grpo_dev_vllm`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=100, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=64, primary_set=d, primary_metric=aulc, items_sha=d3651289, split_lock=3b17766d.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-d6c44c2b` | complete | pp | 0 | 0.7350 | 0.7450 | 0.7555 | -0.013 | 3.0%→0.0% | 343 | 0.28 | 0.33 | 196 |
| `pp-outcome-grpo-s001-a8531baa` | complete | pp | 1 | 0.7300 | 0.7900 | 0.7615 | +0.034 | 3.5%→0.0% | 286 | 0.27 | 0.28 | 176 |
| `r-outcome-grpo-s000-92c2d71e` | complete | r | 0 | 0.7350 | 0.7800 | 0.7578 | +0.022 | 3.0%→0.0% | 415 | 0.27 | 0.39 | 192 |
| `r-outcome-grpo-s001-fae6d103` | complete | r | 1 | 0.7300 | 0.7700 | 0.7580 | +0.014 | 3.5%→0.0% | 343 | 0.29 | 0.41 | 184 |

### `olmo3sft_grpo_kl05_seeds`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=True, method=grpo, lr=2e-04, schedule=constant_with_warmup, warmup=5, updates=40, kl=0.05, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=16, primary_set=s, primary_metric=final_accuracy, items_sha=b4e060d6, split_lock=6147da9a.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-28c3455b` | complete | pp | 0 | 0.6763 | 0.7400 | 0.7099 | +0.047 | 2.8%→0.3% | 628 | 0.29 | 0.68 | 223 |
| `pp-outcome-grpo-s001-da85649c` | complete | pp | 1 | 0.6763 | 0.7525 | 0.7179 | +0.058 | 2.8%→0.1% | 495 | 0.28 | 0.66 | 238 |
| `pp-outcome-grpo-s002-833f9d80` | complete | pp | 2 | 0.6763 | 0.7450 | 0.7114 | +0.053 | 2.8%→0.4% | 466 | 0.28 | 0.61 | 200 |
| `pp-outcome-grpo-s003-5e38b191` | complete | pp | 3 | 0.6763 | 0.7338 | 0.7091 | +0.040 | 2.8%→0.2% | 315 | 0.27 | 0.68 | 247 |
| `pp-outcome-grpo-s004-f7c06cf5` | complete | pp | 4 | 0.6763 | 0.7550 | 0.7155 | +0.060 | 2.8%→0.0% | 172 | 0.26 | 0.52 | 224 |
| `pp-outcome-grpo-s005-0da61dd0` | complete | pp | 5 | 0.6763 | 0.7462 | 0.7118 | +0.053 | 2.8%→0.3% | 580 | 0.27 | 0.65 | 227 |
| `pp-outcome-grpo-s006-160dd0bf` | complete | pp | 6 | 0.6763 | 0.7238 | 0.7112 | +0.031 | 2.8%→0.4% | 335 | 0.27 | 0.67 | 221 |
| `pt-outcome-grpo-s000-7e9e5d1f` | complete | pt | 0 | 0.6763 | 0.7469 | 0.7141 | +0.055 | 2.8%→0.5% | 478 | 0.29 | 0.74 | 543 |
| `pt-outcome-grpo-s001-2743a788` | complete | pt | 1 | 0.6763 | 0.7431 | 0.7189 | +0.048 | 2.8%→0.1% | 175 | 0.27 | 0.71 | 577 |
| `pt-outcome-grpo-s002-6dce279a` | complete | pt | 2 | 0.6763 | 0.7488 | 0.7149 | +0.054 | 2.8%→0.1% | 450 | 0.28 | 0.68 | 567 |
| `r-outcome-grpo-s000-354a61dc` | complete | r | 0 | 0.6763 | 0.7294 | 0.7018 | +0.035 | 2.8%→0.1% | 546 | 0.27 | 0.47 | 53 |
| `r-outcome-grpo-s001-07388563` | complete | r | 1 | 0.6763 | 0.7231 | 0.7044 | +0.029 | 2.8%→0.1% | 446 | 0.26 | 0.51 | 205 |
| `r-outcome-grpo-s002-c495cda2` | complete | r | 2 | 0.6763 | 0.7244 | 0.7075 | +0.031 | 2.8%→0.3% | 516 | 0.26 | 0.45 | 191 |
| `r-outcome-grpo-s003-903ae2bd` | complete | r | 3 | 0.6763 | 0.7169 | 0.7010 | +0.022 | 2.8%→0.1% | 510 | 0.26 | 0.53 | 214 |
| `r-outcome-grpo-s004-3b3f4856` | complete | r | 4 | 0.6763 | 0.7175 | 0.6987 | +0.025 | 2.8%→0.4% | 599 | 0.28 | 0.50 | 189 |
| `r-outcome-grpo-s005-68a04d45` | complete | r | 5 | 0.6763 | 0.7256 | 0.7025 | +0.032 | 2.8%→0.2% | 335 | 0.27 | 0.50 | 190 |
| `r-outcome-grpo-s006-9db5f845` | complete | r | 6 | 0.6763 | 0.7250 | 0.7066 | +0.030 | 2.8%→0.1% | 283 | 0.26 | 0.45 | 199 |

### `olmo3sft_grpo_lr_sweep`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=False, method=grpo, schedule=constant_with_warmup, warmup=5, updates=40, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=16, primary_set=s, primary_metric=final_accuracy, items_sha=b4e060d6, split_lock=6147da9a.

| run_id | status | policy | seed | lr | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-b36c7490` | complete | pp | 0 | 1e-04 | 0.6750 | 0.7444 | 0.7056 | +0.049 | 2.9%→0.1% | 556 | 0.30 | 0.50 | 131 |
| `pp-outcome-grpo-s000-58767a68` | complete | pp | 0 | 2e-04 | 0.6644 | 0.6950 | 0.7182 | +0.013 | 2.8%→0.1% | 278 | 0.51 | 0.19 | 105 |
| `pp-outcome-grpo-s000-e486543f` | complete | pp | 0 | 5e-05 | 0.6713 | 0.7119 | 0.6959 | +0.020 | 3.2%→0.2% | 411 | 0.28 | 0.67 | 136 |
| `r-outcome-grpo-s000-cf474849` | complete | r | 0 | 1e-04 | 0.6669 | 0.6388 | 0.6987 | -0.054 | 3.9%→0.1% | 9 | 0.49 | 0.09 | 66 |
| `r-outcome-grpo-s000-93c5f2fe` | complete | r | 0 | 2e-04 | 0.6806 | 0.7581 | 0.7138 | +0.056 | 3.1%→0.1% | 525 | 0.26 | 0.32 | 107 |
| `r-outcome-grpo-s000-342d740b` | complete | r | 0 | 5e-05 | 0.6725 | 0.7231 | 0.6939 | +0.028 | 3.2%→0.0% | 9 | 0.29 | 0.25 | 82 |

### `olmo3sft_grpo_pt16`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=40, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=16, primary_set=s, primary_metric=final_accuracy, items_sha=b4e060d6, split_lock=6147da9a.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-2dbc997d` | complete | pp | 0 | 0.6725 | 0.6994 | 0.6825 | +0.007 | 3.3%→0.4% | 404 | 0.28 | 0.79 | 154 |
| `pp-outcome-grpo-s001-4bdc9c53` | complete | pp | 1 | 0.6737 | 0.6919 | 0.6857 | +0.001 | 2.8%→0.3% | 439 | 0.28 | 0.77 | 151 |
| `pp-outcome-grpo-s002-63fa6406` | complete | pp | 2 | 0.6706 | 0.6881 | 0.6833 | -0.002 | 3.1%→0.3% | 405 | 0.28 | 0.82 | 152 |
| `pt-outcome-grpo-s000-3783a148` | complete | pt | 0 | 0.6725 | 0.6913 | 0.6822 | -0.002 | 3.3%→0.3% | 356 | 0.27 | 0.86 | 338 |
| `pt-outcome-grpo-s001-269b78a1` | complete | pt | 1 | 0.6737 | 0.6956 | 0.6833 | +0.005 | 2.8%→0.3% | 428 | 0.27 | 0.86 | 343 |
| `pt-outcome-grpo-s002-6ad8117e` | complete | pt | 2 | 0.6706 | 0.6944 | 0.6830 | +0.005 | 3.1%→0.3% | 405 | 0.27 | 0.81 | 321 |
| `r-outcome-grpo-s000-c717e145` | complete | r | 0 | 0.6725 | 0.6875 | 0.6800 | -0.006 | 3.3%→0.3% | 393 | 0.28 | 0.58 | 133 |
| `r-outcome-grpo-s001-830dfea6` | complete | r | 1 | 0.6737 | 0.6887 | 0.6816 | -0.003 | 2.8%→0.2% | 369 | 0.27 | 0.57 | 133 |
| `r-outcome-grpo-s002-a6f256db` | complete | r | 2 | 0.6706 | 0.6906 | 0.6840 | -0.000 | 3.1%→0.1% | 343 | 0.27 | 0.53 | 129 |

### `olmo3sft_grpo_short40`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=40, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=64, primary_set=d, primary_metric=aulc, items_sha=d3651289, split_lock=3b17766d.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-b557ed52` | complete | pp | 0 | 0.7350 | 0.7850 | 0.7431 | +0.027 | 3.0%→0.0% | 345 | 0.28 | 0.66 | 96 |
| `pp-outcome-grpo-s001-8efc271c` | complete | pp | 1 | 0.7300 | 0.8000 | 0.7481 | +0.044 | 3.5%→0.0% | 366 | 0.28 | 0.62 | 61 |
| `pp-outcome-grpo-s002-618fea5d` | complete | pp | 2 | 0.7150 | 0.7800 | 0.7472 | +0.043 | 3.5%→0.5% | 406 | 0.29 | 0.63 | 106 |
| `r-outcome-grpo-s000-65eef42d` | complete | r | 0 | 0.7350 | 0.7750 | 0.7438 | +0.021 | 3.0%→0.5% | 395 | 0.28 | 0.50 | 49 |
| `r-outcome-grpo-s001-45f7bb14` | complete | r | 1 | 0.7300 | 0.7800 | 0.7481 | +0.024 | 3.5%→0.0% | 411 | 0.27 | 0.52 | 60 |
| `r-outcome-grpo-s002-e4aaa5ab` | complete | r | 2 | 0.7450 | 0.7500 | 0.7503 | -0.026 | 4.5%→0.5% | 417 | 0.28 | 0.53 | 89 |

### `olmo3sft_grpo_short40_v2`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=40, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=64, primary_set=s, primary_metric=final_accuracy, items_sha=b4e060d6, split_lock=6147da9a.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-aad294ce` | complete | pp | 0 | 0.6725 | 0.6931 | 0.6806 | +0.000 | 3.3%→0.4% | 448 | 0.27 | 0.78 | 158 |
| `pp-outcome-grpo-s001-a53177c3` | complete | pp | 1 | 0.6737 | 0.6919 | 0.6833 | +0.000 | 2.8%→0.2% | 340 | 0.27 | 0.82 | 155 |
| `pp-outcome-grpo-s002-7c0cc154` | complete | pp | 2 | 0.6706 | 0.6881 | 0.6801 | -0.001 | 3.1%→0.4% | 404 | 0.27 | 0.79 | 157 |
| `r-outcome-grpo-s000-71fd0302` | complete | r | 0 | 0.6800 | 0.6887 | 0.6825 | -0.011 | 3.1%→0.3% | 384 | 0.28 | 0.59 | 139 |
| `r-outcome-grpo-s001-de459d9f` | complete | r | 1 | 0.6675 | 0.6937 | 0.6852 | +0.005 | 3.2%→0.1% | 333 | 0.27 | 0.53 | 135 |
| `r-outcome-grpo-s002-4ef49185` | complete | r | 2 | 0.6775 | 0.6906 | 0.6808 | -0.005 | 2.9%→0.3% | 409 | 0.27 | 0.57 | 139 |

### `olmo3sft_grpo_stability`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=True, method=grpo, warmup=5, updates=40, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=16, primary_set=s, primary_metric=final_accuracy, items_sha=b4e060d6, split_lock=6147da9a.

| run_id | status | policy | seed | lr | schedule | kl | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `r-outcome-grpo-s000-c9a7a9f5` | complete | r | 0 | 1e-04 | constant_with_warmup | 0 | 0.6763 | 0.7475 | 0.6996 | +0.055 | 2.8%→0.4% | 609 | 0.27 | 0.42 | 162 |
| `r-outcome-grpo-s000-5911b95a` | complete | r | 0 | 1e-04 | constant_with_warmup | 0.05 | 0.6763 | 0.7031 | 0.6953 | +0.009 | 2.8%→0.2% | 512 | 0.26 | 0.48 | 199 |
| `r-outcome-grpo-s000-096ee418` | complete | r | 0 | 1e-04 | cosine | 0 | 0.6763 | 0.7006 | 0.6928 | +0.005 | 2.8%→0.0% | 340 | 0.27 | 0.42 | 160 |
| `r-outcome-grpo-s000-575b76a2` | complete | r | 0 | 2e-04 | constant_with_warmup | 0 | 0.6763 | 0.7525 | 0.7183 | +0.059 | 2.8%→0.2% | 299 | 0.34 | 0.26 | 139 |
| `r-outcome-grpo-s000-354a61dc` | complete | r | 0 | 2e-04 | constant_with_warmup | 0.05 | 0.6763 | 0.7294 | 0.7018 | +0.035 | 2.8%→0.1% | 546 | 0.27 | 0.47 | 199 |
| `r-outcome-grpo-s000-7c3d3c26` | complete | r | 0 | 2e-04 | cosine | 0 | 0.6763 | 0.7544 | 0.7229 | +0.059 | 2.8%→0.0% | 148 | 0.28 | 0.23 | 109 |

### `olmo3sft_grpo_timing`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=transformers, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=2, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=64, primary_set=d, primary_metric=aulc, items_sha=d3651289, split_lock=3b17766d.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-d8bd7419` | complete | pp | 0 | 0.7250 | 0.7300 | 0.7312 | +0.005 | 3.0%→3.0% | 490 | 0.26 | 0.88 | 22 |

### `olmo3sft_grpo_timing_vllm`

Shared: student=Olmo-3-7B-Instruct-SFT@e1452fc, generation=vllm, batch_invariant=False, method=grpo, lr=2e-05, schedule=constant_with_warmup, warmup=5, updates=2, kl=0, group_size=8, rollout_temp=1, max_completion_tokens=512, lora=r16/a32.0, batch_items=32, slate=64, primary_set=d, primary_metric=aulc, items_sha=d3651289, split_lock=3b17766d.

| run_id | status | policy | seed | initial | final | AULC | Δparsed* | unparse u0→end* | len end* | max letter* | grad groups* | min* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pp-outcome-grpo-s000-3d40d6e4` | complete | pp | 0 | 0.7350 | 0.7600 | 0.7388 | +0.022 | 3.0%→2.5% | 499 | 0.26 | 0.75 | 6 |

<!-- END GENERATED -->
