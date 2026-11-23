# Pre-registration: a test-time sub-type notebook for trained students (confirmatory NB)

**Status: DRAFT 2026-11-23, awaiting the owner's sign-off.** Not frozen. No checkpoint has answered E2
with a note.

## 1. Question

A notebook of short, general notes, one per question sub-type, written by Claude Opus 5.5 from
training items, can be shown to the student next to a question it is answering. Does this raise the
held-out accuracy of a student that GRPO has already trained with PanelProbe item selection? In other
words, do test-time notes and PanelProbe training add up?

Development evidence (S only, never E2):
- Frozen student (FINDINGS #44): S 0.691 → 0.732 with the routed note (+0.041 [+0.018, +0.064], item
  bootstrap); Standard English +0.179. Qwen3-8B: +0.031.
- Trained students (FINDINGS #46, DEV_RUN10 checkpoints at update 40, seeds 0–3): note − plain is
  positive for all 8 checkpoints. PP16 0.739 → 0.791 (per seed +0.043 to +0.060); R 0.726 → 0.775.
  PP16 with notes − R without notes ≈ +0.065.
- Training the student to use the notes (distillation, FINDINGS #45) did not work, so the notebook
  is tested only at test time.

## 2. Hypotheses

Metric: accuracy on E2 (all 600 items) at update 40, scored with the lenient parser (§3.3).

- **H1 (primary).** For PP16-trained students, accuracy with the routed note is higher than without.
  Estimand: mean over seeds of [acc(PP16 checkpoint, note) − acc(same checkpoint, plain)].
- **H2 (secondary).** The same for R-trained students: R note − R plain > 0.
- **H3 (secondary).** PP16 with notes beats R without notes: acc(PP16, s, note) − acc(R, s, plain) > 0,
  paired by seed. This is the combined gain of PanelProbe training and the notebook over the plain
  random-selection baseline.
- **Exploratory, no confirmatory claim:** PJ note − plain; PP16 − R with notes and without them;
  PP16 − PJ with notes; Standard English vs the other skills; per skill; strict scoring; parseable
  rates; the plain answers against each run's own E2 evaluation.

## 3. Design

| component | value |
|---|---|
| Students | the 72 checkpoints of confirmatory DC at update 40 (`artifacts/olmo3sft_grpo_confirmatory_dc`, arms R, PP16, PJ × root seeds 200–223), unchanged; OLMo-3-7B-Instruct-SFT @ `e1452fc5…` + LoRA |
| Set | E2 (600 items, 60 per skill; PREREGISTRATION_CONFIRMATORY_DC §3.1) |
| Conditions | **plain**: the standard answer prompt (`prompts/student_answer.txt`); **note**: the same prompt with `"\n\nNote from your tutor about this kind of question: " + note` appended to the user message |
| Notes | `artifacts/notebook/notebook.jsonl` (FINDINGS #44): 72 notes, one per sub-type, written by Claude Opus 5.5 from up to 5 training items (P) of that sub-type; unchanged since 2026-11-21 |
| Routing | each E2 item gets a sub-type of its skill from Claude Sonnet 5.5, shown the item without the key (router prompt of `scripts/notebook_eval.py`); file `artifacts/subtypes/routed_e2.jsonl`, written 2026-11-23 before freezing (§3.2). An item whose route has no note is answered plain in both conditions. |
| Decoding | greedy, ≤ 512 tokens (the runs' evaluation setting), vLLM with the checkpoint's adapter loaded; script `scripts/notebook_answer.py` |
| Pairing | H1 and H2: the same checkpoint in two conditions; H3: arms paired by root seed |

### 3.1 What is and is not new about E2

E2 is not untouched. The DC analysis (2026-11-07) read every DC checkpoint's plain E2 accuracy once,
and those results are public (CONFIRMATORY_DC_RESULTS.md). That reading was the plain condition only.
**No note has ever been shown with an E2 item, and no E2 answer under a note exists.** The notes were
written from training items before E2 was routed, and neither the notes nor the router saw any E2
outcome. The DC per-skill plain results were known when this study was designed. The design was
fixed from S (FINDINGS #44 and #46), not from them: all skills get notes, with the prompt and router
used in development.

### 3.2 Routing E2

Routing reads the item text (passage, question, choices) but not the key, and no student output. It ran
once on 2026-11-23 (access logged as `route` in `data/locks/pool_v2_dc/access_log.jsonl`): 600 of 600
routed, about $2 on the tutor ledger. The file is hashed at freezing. Nothing else was read from it
before freezing apart from the count of items with a note.

### 3.3 Scoring

Primary: **lenient** (`scripts/tutor_bench.py:lenient`): the run's parser (`answer-line-v2`) first;
otherwise the last "answer is X" / "Option X" / "choice X" mention after any reasoning block. Used for
both conditions, as in development (FINDINGS #44, #46). Strict scoring is reported as exploratory.

## 4. Analysis plan

`scripts/confirmatory_nb_analysis.py`, committed before E2 is answered (hash in FROZEN.json). A dry
run on the development checkpoints (DEV_RUN10, S standing in for E2) reproduced FINDINGS #46 (§7).

1. Integrity: exactly one DC run and one complete answer file (600 items) per arm and seed; every
   file covers the same items.
2. For each hypothesis, d_s per seed s (24 values), as defined in §2.
3. Two-sided one-sample t-test of {d_s}, α 0.05; mean, t-interval, p. **Holm across H1–H3.** A
   hypothesis is supported if its t-interval lies above 0 and its Holm p < 0.05.
4. **Secondary, reported with each hypothesis: an item bootstrap with the seeds fixed** (2,000
   resamples of the 600 items). The t-test over seeds treats E2's items as fixed. With a fixed note
   set, the item sample is the main source of uncertainty about other questions. If the item-bootstrap
   interval of H1 includes 0, the write-up will say that H1 holds for E2's items, but that
   generalisation to new items is not established.
5. **No interim look.** `scripts/notebook_answer.py` writes per-item answers to artifacts and prints no
   accuracy. No E2 accuracy under any condition is computed until all 72 answer files exist. The
   analysis then runs once.

## 5. Sample size and power

From the dry run (DEV_RUN10 checkpoints, 4 seeds per arm, PP16): the per-seed SD of note − plain is
0.0073 on S (1,600 items). Resampling 60 items per skill from S (200 subsets) gives a 600-item set
with **seed SD ≈ 0.012** and **item-bootstrap half-width ≈ 0.021**. The development mean, +0.052,
varies by 0.008 across subsets.

- Seed-level t-test, 24 seeds: power before Holm is about 0.97 at δ +0.010 and about 1 at +0.02.
- Item bootstrap of H1: the interval excludes 0 with probability about 0.5 at δ +0.02, 0.8 at +0.03,
  and about 0.99 at +0.05. This, not the number of seeds, limits what can be said about new items.
- E2 is easier for these students than S (plain ≈ 0.81 vs 0.73), so the room for gain is smaller.
  The effect may be smaller than in development.

## 6. Failures and exclusions

- Every checkpoint is analysed; no exclusion based on outcomes.
- A technical failure (server error, crash) is re-run for that checkpoint. Greedy vLLM decoding is
  batch-invariant on these servers, but a re-run is valid either way. A partial answer file is never
  written (written to `.tmp`, then renamed).
- No change to code, notes, routes or prompts after freezing.
- Before answering, both vLLM servers must pass a real `/v1/completions` check.

## 7. Dry run (development data)

`scripts/confirmatory_nb_analysis.py --exp artifacts/olmo3sft_grpo_pool_v2 --answers
artifacts/notebook/answers/dev_run10_s --split s --seeds 0 1 2 3 --arms r pp16 --allow-development`
(answers from `scripts/notebook_answer.py`, 8 checkpoints, 23 min). Every one of the 1,600 S items was
routed and had a note. It reproduces FINDINGS #46:

| | mean | t-interval (4 seeds) | item bootstrap |
|---|---|---|---|
| H1 PP16 note − plain | +0.0522 | [+0.041, +0.064] | [+0.040, +0.066] |
| H2 R note − plain | +0.0494 | [+0.035, +0.064] | [+0.036, +0.063] |
| H3 PP16 note − R plain | +0.0650 | [+0.043, +0.087] | [+0.052, +0.079] |

The plain answers (strict scoring) match each run's own S evaluation: mean 0.7381 vs 0.7409 (PP16)
and 0.7256 vs 0.7241 (R), with the largest per-seed gap 0.007. The script reproduces the training
runs' evaluation.

## 8. Cost and schedule

No paid API calls after routing. 72 checkpoints × 600 items × 2 conditions on the two OLMo vLLM
servers (GPU 0 and 1): about 1.5 h (the dry run did 8 × 1,600 × 2 in 23 min).

## 9. Known limitations

- One student (OLMo-3-7B), one note set, one router; the notes come from one Claude model writing
  from 5 items per sub-type.
- E2 was generated by Claude Opus 5.5, the model that wrote the notes. The notes were written from
  real training items, not from E2. Even so, the same model's style may make its notes fit its own
  questions better than they would fit human-written SAT questions.
- This tests notes shown at test time, which is a form of help with the test, not learning. It does
  not show that the student learned anything from the notes (FINDINGS #45 suggests it does not).
- E2's plain results were already public (§3.1).

## 10. Changes after freezing

None yet.
