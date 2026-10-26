# Plan: generate a pool large enough for the main study

Status: **accepted in part** (2026-10-02). Nothing has been run or paid for yet.

Decided: the **minimum target (6,240 landed, ~7,800 generated)**. Panel:
**try same-model concurrency first**, measured in the pilot before choosing.
sat-reading-platform's in-progress work is committed (`cbb411d`, `5ffb12f`,
`2edc5d0`), so Phase 0 is unblocked.

Rough timeline for the minimum target:

| Step | Estimate |
|---|---|
| Phase 0 (code changes + tests) | ~half a day |
| Phase 1 pilot | ~2 h |
| Generation, ~7,800 items in ~1,560 calls of ~70 s | ~30 h serial; ~3–6 h with 5–10 parallel streams, if Bedrock rate limits allow |
| Key verification | ~2–4 h in parallel |
| Panel scoring, ~6,240 kept items × ~450 s | 32 days at 1×, ~8 days at 4×, ~4 days at 8× concurrency |

The panel line decides the schedule; the pilot replaces these estimates with
measurements.

Goal: enough panel-scored items that preflight's `selection.pool_support`
passes for a full run (100 updates × 32 = 3,200 presentations), using the
existing sat-reading-platform generator (`generate_gap_questions.py`, Opus 5
on Bedrock) and panel (`eval_multi_model.py`, 8 Ollama models).

## 1. How many items

Per skill (10 skills), landed and usable after verification and dedup:

| Split | Minimum | Recommended | Why |
|---|---|---|---|
| P + P+ (pool) | 384 | 640 | A run consumes 320 per skill without replacement. 320 + 64 keeps a full 64-item slate to the last presentation; 2× lets the policies actually choose difficulty late in the run. |
| S (siblings) | 160 | 160 | ~half of 320 presentations are wrong at target p = 0.5, and siblings may not repeat within a run. |
| E1 | 60 | 60 | Spec §19.2. |
| D | 20 | 20 | Development evaluation. |
| **Total per skill** | **624** | **880** | |
| **Total (10 skills)** | **6,240** | **8,800** | |

W (panel calibration) stays the existing 706-item bank, so the panel's
abilities stay comparable to the paper's.

Ask for about **1.25×** the landed target (~7,800 or ~11,000 generated),
assuming ~20% loss to the format validator, key verification, and dedup. The
pilot measures the real loss.

Difficulty: every usable item is usable in the pool whatever its difficulty,
because selection, not labels, decides what a student sees. But the pool must
span the students' ability range. AI items land easier than asked (only 27%
of asked-hard items land hard). So ask hard-heavy, e.g. D1–D5 = 10/15/20/25/30%,
and judge the result by PanelProbe difficulty after scoring, not by the asked
label.

## 2. Cost and time, from measured numbers

| Step | Measured basis | Minimum (7.8k asked) | Recommended (11k asked) |
|---|---|---|---|
| Generation (Opus 5, Bedrock) | Stage A: $3.68 / 70 items = $0.053/item | ~$410 | ~$580 |
| Key verification (blind solve, Sonnet 5.5) | estimate, ~$0.015/item | ~$120 | ~$170 |
| Panel scoring, CPU, as today | Stage A/B: ~450 s/item for 8 models, one request at a time | ~40 days | ~57 days |

**The panel is the bottleneck, not money.** The 8 A100s are held by a vLLM
job (63 days old). Options, decided at Gate 1:

1. **Parallel requests per model on CPU.** The rule "never two models at once"
   stays; concurrent requests to the *same* model (`OLLAMA_NUM_PARALLEL`)
   batch the decode. Unmeasured; the pilot measures 1/4/8. If it gives 6×,
   recommended takes ~10 days.
2. **Free one or two GPUs** and serve the panel there. Then hours, not weeks.
   But it changes the runtime (and with vLLM, the quantisation), which
   changes the panel. W would have to be re-scored under the new runtime so
   abilities and difficulties stay on one scale. It is cheap on a GPU (706
   items), but it is a different panel from the paper's.
3. **Smaller target first**: the minimum target in stages, starting with
   the skills the first pilot runs need.

## 3. Changes to the existing code (sat-reading-platform)

Kept small, all behind new flags so the paper's pipeline is unchanged:

| Change | Why |
|---|---|
| `generate_gap_questions.py --batch-id` stamps ids `…_R{i}_{batch}` | ids restart at R1 every run; at this scale collisions are certain (`rekey_batch_ids.py` exists because they already happened). |
| `--chunk-size N` (e.g. 5 items per call), many calls per cell | One call cannot produce 300+ items without truncating at 16k tokens. |
| `--avoid-topics FILE` feeds already-used topics/titles into the prompt | Hundreds of items per cell from one prompt will repeat topics. |
| `--output-dir` outside `data/calibration/` | Keeps the new pool out of the paper's bank (below). |
| `eval_multi_model.py --concurrency K` | Option 1 above. Default 1 keeps today's behaviour. |
| New `verify_keys.py`: a strong model solves each item without the key; disagreement drops or flags it | The generator has never had its keys checked. At ~10k items, wrong keys are certain, and a wrong key looks exactly like a hard item to the panel. |

**The new pool does not enter `questions_validated.jsonl`.** That file is
the paper's bank; ingesting thousands of items would change every number in
the paper. New items and their panel responses live in
`virtual-student/data/raw/pool_v1/` (questions per batch, one eval dir per
batch). virtual-student's importer gains a source for them; W stays the
existing bank.

Blocker before any change: sat-reading-platform has uncommitted in-progress
work (Stage B re-key, Stage C items, `rekey_batch_ids.py`, paper build files)
on branch `remove-math-module`. That needs to be committed or set aside by
you first; I will not modify the scripts on top of it.

## 4. Phases and gates

Work that takes hours runs in workflows; panel scoring runs for days, so it
is a resumable background job, not a workflow agent.

**Phase 0 — prepare (inline, no spend). Done 2026-10-02:** sat-reading-platform `72b38f8` on branch `pool-generation` (12 tests), virtual-student `baf0579` (pool importer). Bedrock ids `us.anthropic.claude-opus-5`, `us.anthropic.claude-opus-5-5`, `us.anthropic.claude-sonnet-5-5` all answer. Original Phase 0 text: Settle the sat-reading-platform
working tree; make the code changes above with tests; one-call Bedrock checks
of the generator and verifier model ids.

**Phase 1 — pilot (workflow, ~$15, ~2 h).** 10 skills × 1 cell × 10 items =
100 items. Measures: cost per item, validator loss, verifier disagreement rate,
duplicate rate, topic diversity, and panel throughput at concurrency 1/4/8 on
two models (gemma2:2b, qwen3:14b), plus whether concurrency changes answers
beyond the panel's known nondeterminism.

> **Gate 1 (you):** target size, panel option (CPU parallel / GPU /
> staged), generator model, total budget.

**Phase 2 — generate (workflow, hours).** Five agents, two skills each, one
cell file per (skill, difficulty, batch). Each agent runs the generator in
chunks with resume and reports asked/kept/cost. Then dedup against the whole
bank plus the new pool, and key verification. A completeness check lists
under-filled cells. Spend is capped per batch; the workflow stops at the cap.

**Phase 3 — panel scoring (background job, days).** One model at a time, all
items, then the next model; per-batch eval dirs; `retry_failed_cells.py
--min-timeout 900` after each model; coverage gate (every item needs the
required tiers, as `recalibrate_ai.py` enforces). Progress is checked on a
long interval.

**Phase 4 — import, assign splits, probe (inline).** virtual-student imports
the pool, assigns P/P+/S/E1/D by a frozen split file (stratified by skill and
PanelProbe difficulty), locks it, probes difficulties against W-calibrated
abilities, builds the sibling map, and runs preflight for a full-length
config.

> **Gate 2 (you):** per-skill counts and difficulty spread vs target. If
> cells are short, one or two top-up rounds of Phases 2–3 for those cells only.

## 5. Decisions needed from you

1. **Target size**: minimum (6.2k) or recommended (8.8k), or staged.
2. **Panel runtime**: CPU with parallel requests, free GPUs (new panel
   runtime, W re-scored), or staged.
3. **E1 source**: generated items for every skill, or real College Board
   items where there are enough (words_in_context 73, inferences 62, …) and
   generated items elsewhere. Real items exist for only 8 cross_text and 15
   central_ideas questions, so all-real E1 is impossible (OPEN_DECISIONS C2).
4. **Generator**: stay on Opus 5 (matches the existing AI items) or Opus 5.5
   (newest, ~20% cheaper; the paper found generator strength did not change
   hard-item yield).
5. **Verifier**: which model blind-solves for key checks, and whether
   disagreement drops the item or sends it for regeneration.
6. **Budget ceiling** for Phases 1–3.

## 6. Pilot results (Phase 1, 2026-10-02)

Generation and verification ran as a workflow (5 agents × 2 skills, 11.5 min);
throughput ran in the background on 16 existing Stage B items.
Scripts: `scripts/pilot_throughput.py`, `scripts/pilot_report.py`. Raw data:
`data/raw/pool_v1/pilot/` (not committed).

**Generation (Opus 5, 10 skills × 10 asked):** 99 kept. One item was dropped
for five choices. Measured cost $4.16 ($0.042/item, first-party rates).
Duplicates: none exact or near (8-word-shingle Jaccard ≥ 0.5), against the
bank or within the batch. 95 distinct topics; 3 topics repeated, all across
skills. Passage types: science 35, social science 29, history 25, literature 10.
**Keys: A 21, B 18, C 21, D 39.** Prompt rule 7 over-corrected the old B skew.

**Verification (Sonnet 5.5, 2 blind samples):** 98 agree, 0 disagree, 1
split (boundaries D4: one sample A, one sample C, both confident). $0.91
($0.009/item).

**Panel throughput (s/item, 16 items):**

| model | c=1 | c=1 repeat | c=4 | c=8 |
|---|---|---|---|---|
| gemma2:2b | 14.1 | 14.0 | 5.9 | 6.3 |
| qwen3:14b | 97.3 | 90.0 | 34.4 | 67.9 (8/16 timed out) |

Answer agreement with the first c=1 run: gemma2:2b repeat 0.875, c=4 0.812;
qwen3:14b repeat 0.938, c=4 0.875, c=8 0.50. The c=8 drop is timeouts, not
changed answers. At c=4 the agreement is within the models' own run-to-run
variation, though 16 items cannot rule out a small shift.

**Consequences**

- Use **concurrency 4** with `--min-timeout 900`. c=8 is slower and times out.
- Panel at c=4 is ~2.6× faster: ~175 s/item for all 8 models, so **~13 days
  for 6,240 items**. Start scoring each batch as soon as it is generated,
  rather than waiting for all of them.
- Generation for ~7,800 items: ~$330, ~4 h at 10 streams. Verification:
  ~$70.
- Fixed in sat-reading-platform `3ff3652`: `balance_keys.py` (run before
  verification and panel), `--avoid-global`, `eval_multi_model.py --min-timeout`.

## 7. Moving the panel to GPU (2026-10-04)

The 8 A100s were held by an idle vLLM server (see `docs/STOPPED_SERVICES.md`).
It was stopped with the owner's approval. The panel now runs as 8 Ollama
servers, one per GPU (ports 11500–11507, `CUDA_VISIBLE_DEVICES=i`), with the
same Q4 models and prompts as the CPU panel, at 16 slots each. phi3 runs 4
slots: it has no grouped-query attention, so 16 × 8192 context needed 48 GB of
KV cache and pushed half its layers to the CPU.

**Concordance on the full W bank (706 items, all 8 models, CPU vs GPU):**

| model | agree | acc CPU | acc GPU | mean θ CPU | mean θ GPU |
|---|---|---|---|---|---|
| deepseek-r1:8b | 0.872 | 0.840 | 0.837 | 2.17 | 2.19 |
| qwen3:14b | 0.926 | 0.873 | 0.881 | 2.40 | 2.46 |
| qwen3:8b | 0.923 | 0.858 | 0.861 | 2.23 | 2.25 |
| qwen2:7b | 0.717 | 0.671 | 0.678 | 0.87 | 0.95 |
| llama3.1:8b | 0.695 | 0.654 | 0.690 | 0.85 | 1.11 |
| gemma2:2b | 0.697 | 0.608 | 0.585 | 0.59 | 0.41 |
| phi3:3.8b | 0.644 | 0.608 | 0.578 | 0.49 | 0.30 |
| llama3.2:3b | 0.592 | 0.579 | 0.559 | 0.34 | 0.30 |

Item difficulty, each side calibrated separately: **Pearson 0.80, Spearman
0.77**, mean shift −0.001, SD of the difference 0.67. For comparison, if every
response were an independent draw from the fitted CPU model, two runs would
correlate only **0.60** (simulation, 5 replicates). The GPU panel agrees with
the CPU panel more closely than the measurement model's own noise predicts.
That is consistent with GPU and CPU being the same panel, but it cannot fully
separate a runtime change from the weak models' known run-to-run instability.

**Decision:** virtual-student uses the GPU panel throughout. W is re-scored on
GPU, and pool items are scored on GPU, so abilities and difficulties come
from one panel. The paper's CPU numbers stay as they are.

**A finding that matters for the study:** one panel run gives each item's
difficulty a test-retest reliability of only about 0.6–0.8, from 8 binary
responses with a posterior SD ≈ 0.8. PP selects on this noisy estimate. PP-u
exists for exactly this reason. Re-scoring each pool item several times (cheap
on GPU) would shrink the noise and is worth considering as a design choice.

## 8. P1 batch: generated, verified, panel-scored (2026-10-05)

**Generation** (Opus 5, 10 nohup streams via `scripts/run_pool_skill.sh`,
19:08–01:53 UTC): 7,457 items kept of 7,800 asked. The losses are items with
five choices or broken JSON. Cost ≈ $355 for generation and ≈ $70 for
verification, at first-party rates.

**Verification** (Sonnet 5.5, 2 blind samples): 7,411 agree, 24 disagree, 22
split (0.6%). The problems concentrate in transitions (26) and
words_in_context (7).

**Panel** (8 GPU Ollama servers): every model has exactly one valid answer
per item (8 × 7,457). Unparseable rates: phi3 1.5%, llama3.2 3.2%,
qwen2 2.9%, every other model under 0.3%. These match W.

Two silent failures had to be repaired, and both now have guards:

1. **CPU offload produces nonsense, not only slow answers.** A model loaded
   while the previous one was still in VRAM got only part of the GPU
   (deepseek-r1 at 23/37 and 14/37 layers). Its answers were 63–94%
   unparseable, and it saturated the CPU for every other server.
   `scripts/panel_plan.py` now unloads, reloads, and requires
   `size_vram == size` before each shard. The 36 bad rows were re-scored.
2. **phi3 degrades on a long-running server.** It ran fully on GPU, but after
   ~2,000 items it began emitting fluent nonsense and never recovered (77%
   unparseable on the pool). It happened once more within a single fresh
   400-item chunk (13.8%). `scripts/rescore_with_canary.py` restarts the
   server per chunk, checks 12 W canaries against a known-good run, and
   redoes any chunk above 10% unparseable. All 7,457 phi3 rows were
   re-scored this way.

The lesson: "a row exists" is not evidence of a valid measurement. Every
future panel run should go through the canary + per-chunk post-check.

## 9. Test-retest of the GPU panel (2026-10-06)

With two full GPU passes over W + P1 (8,163 items), the item difficulties
calibrated from pass 1 alone and from pass 2 alone correlate **0.71**
(Spearman 0.65). Agreement of each model with its own earlier answer:
qwen3:8b 0.94, qwen3:14b 0.93, deepseek-r1 0.91, gemma2 0.75, llama3.1 0.75,
qwen2 0.73, phi3 0.67, llama3.2 0.64. By Spearman–Brown, the mean of three
passes should reach a reliability of about 0.88, so the decision to score
each item three times is justified.

How repeats enter the likelihood is a new scientific choice,
`panel.repeat_weighting` (REQUIRED in the confirmatory templates):

- `binomial`: every repeat is an independent trial. The posterior SD falls
  from 0.89 (one pass) to 0.74 (two passes). But the strong members mostly
  repeat themselves, so this overstates precision, and PP-u selects on that
  precision.
- `mean`: one trial per cell at its mean correctness. The repeats denoise
  b̂ without counting as independent evidence. Development configs use this.

## 10. pool_v1 imported (2026-10-06)

`configs/pool_v1.dev.yaml` with the frozen split file `data/splits/pool_v1_dev.json`:

| split | items | per skill |
|---|---|---|
| W (existing bank) | 706 | 42–90 |
| P | 5,746 | 560–581 |
| P+ | 640 | 64 |
| S | 1,600 | 160 |
| E1 | 600 | 60 |
| D | 200 | 20 |

- 8,786 pool items after dropping 56 that failed key verification. Each item
  has 24 panel responses (8 models × 3 GPU passes); 227,807 responses in total.
- No exact or normalised-text duplicates. Keys are balanced in every split × skill.
- Every split has the same difficulty profile (median b −0.56; 5/25/75/95th
  percentiles −1.23/−0.98/0.15/1.27), as the stratified build intends.
- **Preflight passes for a full-length run** (100 updates × 32,
  candidate slate 64). The only warning is the placeholder taxonomy.

Two properties of the pool that matter for the study:

1. **It is easier than the real bank.** Median b is −0.56 against W's
   −0.30, and the 75th percentile is 0.15 against 0.49. The asked labels
   are monotone but compressed (median b by asked D1→D5: −0.97, −0.83,
   −0.64, −0.45, −0.22), consistent with the earlier finding that AI items
   land easier than asked.
2. **There is a ceiling: 22% of pool items were answered correctly by all 8
   models in all 3 passes** (W: 18%). Their difficulty estimates pile up at
   the prior-shrunk floor (−1.23 at the 5th percentile, −0.98 at the 25th).
   The panel cannot rank items below its weakest member (gemma2:2b). If the
   student model starts weaker than that, PanelProbe will see a large block
   of the pool as equally easy.

## 11. Hard-item top-ups P3–P5 and the final pool_v1 (2026-10-12)

The first real-student runs showed PanelProbe running out of hard items
(`DEV_RUN1_RESULTS.md`). The target, chosen by the study owner: ≥ 300 items
with b > 0.5 per skill in P + P+, with the new items spread across every
split by the stratified re-split.

Procedure for each round: Opus 5 generates D5 only, in 5–9 parallel streams
per skill with disjoint `--subject-areas` (PROMPT_VERSION 6). Then balance
keys, then a blind key check (Sonnet 5.5). Then **one screening pass** on a
5-model subset (qwen3:8b, llama3.1, qwen2, llama3.2, gemma2), keeping items
with b̂ > 0.3. Then **three fresh full-panel passes** on the kept items. Only
the fresh passes enter calibration, so selecting on the screen does not
inflate the difficulty estimates. Survivor → b > 0.5 rates in the fresh
passes were 0.35–0.82; the gap from 1.0 is the winner's curse the design
avoids reporting.

| round | generated | kept by screen | note |
|---|---|---|---|
| P3 | 15,626 | 2,931 | all skills; central_ideas kept only 7% |
| P4 | 13,338 | 1,969 | the shortfall after P3 (1-pass estimate) |
| P5 | 1,502 | 366 | the shortfall once difficulty is measured from 3 passes |

Generation plus verification cost about $1,900 at first-party rates.

**Final pool_v1** (`data/splits/pool_v1_dev.json`, lock `6147da9a…`):
14,052 generated items plus W (706). Per skill: E1 60, D 20, S 160, P+ 64,
and P 636–1,580. 354,188 panel responses.

P + P+ items with b > 0.5: boundaries 304, central_ideas 346,
command_of_evidence 298, cross_text 308, form_structure 309, inferences 433,
rhetorical_synthesis 298, text_structure 522, transitions 312,
words_in_context 314. That meets the target, with two skills 2 short.

The difficulty profile is now **harder than the real bank**. Median b is
−0.08 against W's −0.30, and the 75th percentile is 0.67 against 0.49. P,
P+, S, E1, and D share the profile (5/25/50/75/95th ≈ −1.22/−0.75/−0.05/0.67/1.65).
Preflight passes for a full-length run; the only warning is the placeholder taxonomy.
