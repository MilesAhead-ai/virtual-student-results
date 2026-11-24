# DEV_RUN13: focused notebook distillation (development)

**Status: complete 2026-11-24** (8/8 runs, 22:51 → 04:53 UTC, 0 failures). Owner asked (after CONFIRMATORY_NB) to test whether guidance
can produce *learning*, i.e. a gain that remains when the note is not shown.

## Why this design

- CONFIRMATORY_NB: shown at test time, the sub-type note raises E2 accuracy about 4 points, almost all on
  boundaries (+0.23) and transitions (+0.15). The notes' content is valid where it matters.
- The #45 pilot distilled note-conditioned rollouts into the plain prompt across all ten skills (≈ 3
  items per skill per update, 20 updates, notes only when ≤ 4 of 8 correct) and did not internalise them.
- Here the dose on the two skills where notes work is much higher. Training is on boundaries and
  transitions only (16 items each per update), every presented item gets a note group, and there are 40
  updates. That is about 640 note-practised items per skill against about 60 in the pilot.

## Arms (seeds 0–3, PP16, pool v2, 40 updates, LoRA r16, lr 2e-4, KL 0.05)

| arm | training |
|---|---|
| grpo | outcome GRPO, schedule restricted to `expression_of_ideas.transitions`, `standard_english.boundaries` |
| note | the same, plus one note-conditioned group of 8 for every presented item (`grpo.note_max_correct 8`), trained under the plain question (`note_distill: true`) |

Configs: `artifacts/olmo3sft_note_focus/configs/`, built by `scripts/make_note_focus_configs.py` from the
#45 pilot config. Preflight passed (treatment field `grpo.note_max_correct`).

## Analysis, fixed before the results

- **Primary:** accuracy on the 320 S items of boundaries + transitions at update 40, **without notes**
  (the runs' own evaluation). Contrast note − grpo, paired by seed: mean, t-interval (3 df) and an item
  bootstrap.
- Secondary: the same at u10/u20/u30; each skill separately; the other eight skills, which are not trained
  here (a drop would show interference); answer length; note groups' correct rollouts against plain ones.
- References, not contrasts: base student (S boundaries 0.244, transitions 0.456); DEV_RUN10 PP16 trained
  on all skills; the base student with the note at test time (boundaries 0.456, transitions 0.731),
  the level that full internalisation would approach.
- Reading: if note − grpo is clearly positive, guidance produced learning in development, and a
  pre-registered test would follow. If not, together with #36–#45, the conclusion is that this
  student and training setup do not learn from rule-based guidance.

## Results (`scripts/analyze_note_focus.py`, `results/olmo3sft_note_focus/analysis_stdout.txt`)

S boundaries + transitions (320 items), without notes. Base student 0.334 (boundaries 0.231,
transitions 0.438; the eval parser differs slightly from the bench's lenient one).

| update | grpo | note | note − grpo | t-interval (3 df) | per seed |
|---|---|---|---|---|---|
| 10 | 0.379 | 0.377 | −0.002 | [−0.042, +0.038] | −0.013, +0.034, −0.022, −0.009 |
| 20 | 0.375 | 0.380 | +0.006 | [−0.026, +0.037] | +0.028, −0.006, −0.016, +0.016 |
| 30 | 0.391 | 0.380 | −0.012 | [−0.085, +0.062] | −0.044, −0.003, +0.050, −0.050 |
| **40** | **0.409** | **0.404** | **−0.005** | **[−0.053, +0.044]** | +0.038, −0.031, −0.003, −0.022 |

- Item bootstrap at u40: [−0.034, +0.027]. Per skill at u40: transitions 0.547 vs 0.530, boundaries
  0.270 vs 0.278.
- **The signal was there:** 5,120 note groups; correct rollouts per 8 rose from 3.10 (plain) to 4.60
  with the note.
- The untrained eight skills did not suffer: 0.762 at u0, 0.775 (grpo) and 0.779 (note) at u40.
  Answers were longer with notes: 626 vs 566 characters.
- For scale, focused GRPO alone gained +0.075 on these skills (0.334 → 0.409). The base student shown the
  note at test time reaches about 0.59 (FINDINGS #44: boundaries 0.456, transitions 0.731).

## Reading

**No internalisation, even at about 10× the pilot's dose on the two skills where the note works.**
Practising with the note produced more correct rollouts, and these were trained under the plain
question. The student without the note was no better than with plain focused GRPO (−0.5 point, CI ±5).
With #36–#45, every way tried of turning guidance into learning has given nothing over outcome
GRPO in this setup (OLMo-3-7B, LoRA r16, 40 updates):
- tutor dialogue SFT and hybrid training;
- hints in training;
- note distillation, broad and focused.

What remains untested: other training objectives (e.g. full SFT on note-guided correct answers with
the rule written out, or a larger adapter / full fine-tuning), and other students.
