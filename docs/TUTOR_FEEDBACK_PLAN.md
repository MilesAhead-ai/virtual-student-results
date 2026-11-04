# Plan: tutor-feedback arms (F0–F5) — draft, 2026-10-30

Status: **active since 2026-11-04 (E18).** Tutor Claude Opus 5.5; judges and
validator Claude Sonnet 5.5; API ceiling $1,000 for phases B–C. Why now:
FINDINGS #21–22 (the skills with headroom have enough items but outcome-only
GRPO barely moves them; their groups are often all-wrong).

| phase | status | record |
|---|---|---|
| A. Engineering (§3) | mostly done 11-04: spend ledger + hard ceiling (`backends/spend.py`, `budget.api_ledger_file`); `bedrock_runtime` provider (Sonnet 5.5 is not on Mantle); schemas sent without numeric bounds; live test of all 7 schemas; F4 smoke run (1 wrong item: 11 calls, $0.095, ~2 min, 1 leak caught and regenerated, target accepted). Not done: concurrency in the feedback step (measure in B first); prompt fixes (§6) | commits `1ba668b`, `8c4a4f1` |
| B. Pilot | running since 11-04 06:02 UTC: F1, F2, F4 × PP16 × seed 0 × 5 updates, pool v2 | `artifacts/olmo3sft_feedback_pilot/` |
| C. Dev comparison | todo | — |
| D. Confirmatory | todo | — |

## 1. What changes compared with confirmatory v1

Confirmatory v1 trained the student with **outcome-only GRPO**: the only
learning signal was whether its own sampled answers were correct. The spec's
feedback conditions (§15) teach differently. When the student answers wrong,
a tutor intervenes. The student then **re-solves** the item and writes a
standalone solution. If an independent validator accepts that solution, it
becomes an **SFT training target**. Correct first attempts become targets
after a guess filter.

| condition | what the student gets after a wrong answer | tutor API calls |
|---|---|---|
| F0 | "Your answer is incorrect. Reconsider." (no key) | none (template) |
| F1 | the key, plus "explain why X is supported and Y is not" | none (template) |
| F2 | one worked explanation written by the tutor from the item and key (no learner input) | 1 per item, cacheable across runs |
| F3 | a generic Socratic script (≤ 6 turns) generated offline per (item, wrong option) | offline, cacheable |
| F4 | an adaptive tutor that reads the student's reasoning, diagnoses first, and must not reveal the key in turns 1–2 (≤ 6 turns) | ~3–6 per wrong item |
| F5 | F4 plus a learner profile of recent error categories | as F4, plus classifier |

Every condition also uses judges: an error classifier, a leakage judge for
protected turns (F3–F5), and a standalone validator for the re-solved target.

**Consequence: the training method changes from GRPO to SFT.** So F-arm results
are not directly comparable with confirmatory v1. Comparisons should be made
within the F-arms (e.g. F4 vs F1), with outcome-GRPO kept as a separate
reference.

## 2. Questions the study could answer (owner's choice)

- **Q1: Does richer feedback teach more?** Compare F0 / F1 / F2 / F4 (/ F5)
  under one selection policy. This is the spec's main feedback contrast; the
  reference condition (`statistics.reference_condition`) must be chosen,
  e.g. F1.
- **Q2: Does PanelProbe selection still help under tutoring?** Compare PP and
  R within the best feedback condition. This tests whether the v1 result
  generalises beyond outcome-only GRPO.
- **Q3: Do the two interact?** A factorial design is the most expensive.

Proposal: answer Q1 first with PP (the policy already confirmed), then Q2 in
the winning condition.

## 3. Work before any run (engineering, no science decided)

1. **Cost accounting and a hard budget guard.** Log tokens and USD per call,
   per run and per experiment, and stop launching when
   `budget.paid_api_usd` is reached. Nothing of this exists yet.
2. **Concurrency in the feedback step.** The 32 items of an update are
   processed sequentially today (`training/loop.py::_feedback`). Run them
   concurrently, bounded by an API rate limit; otherwise a run takes many
   hours of API latency.
3. **Live backend test.** The Bedrock/Anthropic tutor and judge code exists
   but has only run against the dummy. Test it on a handful of items
   end-to-end: JSON validation, retries, `temperature: null`, caching.
4. **Prompt review.** The tutor, judge and validator prompts in `prompts/`
   are M0 drafts. Review them on real transcripts.
5. **Taxonomy (F5 only).** `taxonomies/sat_rw_misconceptions.yaml` is a
   placeholder (A4). Draft per-skill error categories, have the owner review
   and freeze them, or leave F5 out of the first round.

## 4. Phases

| phase | content | cost / time (estimates, to be measured in phase B) |
|---|---|---|
| A. Engineering | §3 items 1–4, tests | ~1–2 days of work, ~$5 of API for the live test |
| B. Pilot | F1, F2, F4 × PP × 1 seed × 5 updates. Measures API calls and USD per run, wall time, leakage rate, validator acceptance, target yield, plus a sanity check of SFT learning rate | ~$20–60 |
| C. Dev comparison | F0/F1/F2/F4 × PP × 3 seeds × 40 updates (+ SFT tuning), monitored like F10 | depends on B; rough guess $0.5k–3k |
| D. Confirmatory v2 | pre-registered like v1, fresh seeds, E1 | decided after C |

Rough per-run arithmetic for F4, to be replaced by the pilot's measurement:
- 1,280 presentations, of which ~40–45% are wrong → ~550 tutoring episodes.
- ~7 API calls per episode → ~4,000 calls per run.
- That is roughly $50 per run with a Sonnet-class tutor and judges, and
  several times more with an Opus-class tutor.
- F0/F1 need judges only; F2 explanations are cached per item, so they are
  much cheaper.

## 5. Decisions needed from the owner

1. Research question: Q1, Q2 or Q3 (proposal: Q1, then Q2).
2. Tutor and judge models. Proposal: tutor Claude Opus 5 or Sonnet 5.5 via
   Bedrock (instance role, no key); judges a *different* model from the tutor,
   so a model does not grade its own output (e.g. tutor Opus 5, judges
   Sonnet 5.5).
3. A budget ceiling for phases B–C (`budget.paid_api_usd`).
4. F5 now (and build the taxonomy) or later.

## 6. Prompt review notes (from the F4 smoke run, 2026-11-04)

- **The student echoes the tutor.** Its first dialogue reply repeated the
  tutor's message word for word and appended `Answer: B`. Tutor messages
  reach the student as a bare user turn, with no instruction on how to
  reply. Proposal: wrap them in a `student_dialogue_reply` template ("Your
  tutor says: ... Reply in your own words: answer the tutor's question, say
  whether you keep or change your answer, end with `Answer: <A|B|C|D>`").
  Changing it after the pilot is fine: no dev result depends on it yet.
- The tutor handled the echo well (it named it and re-asked), engaged the
  student's own claim, and kept the answer back in the protected turns
  (one draft was caught by the leakage judge and rewritten).
