# DEV_RUN13: focused notebook distillation (development)

**Status: running since 2026-11-23 22:51 UTC.** Owner asked (after CONFIRMATORY_NB) to test whether guidance
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
