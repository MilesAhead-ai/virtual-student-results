# Confirmatory NB: results (2026-11-23)

Pre-registration: [`PREREGISTRATION_CONFIRMATORY_NB.md`](PREREGISTRATION_CONFIRMATORY_NB.md) (hypotheses H1–H3 defined in its
[§2](PREREGISTRATION_CONFIRMATORY_NB.md#2-hypotheses)), frozen 2026-11-23 (tag `confirmatory-nb-frozen`,
hashes in `configs/confirmatory/nb/FROZEN.json`). The 72 DC checkpoints at update 40 answered E2 between
16:34 and 17:49 UTC, split across two vLLM servers, with 0 failures. No E2 accuracy was computed until
all 72 answer files existed. The analysis is `scripts/confirmatory_nb_analysis.py` (sha256 `f8d27640…`,
as frozen), run once. Output: `results/confirmatory_nb/analysis.json`.

All 600 E2 items were routed and every route had a note, so each item was answered once plain and once
with a note.

## Hypotheses (E2 accuracy at update 40, 600 items, seeds 200–223, lenient scoring)

Means over seeds: **R plain 0.8120 → with notes 0.8552; PP16 0.8221 → 0.8590; PJ 0.8186 → 0.8583.**

| hypothesis | mean Δ | seed sd | 95% t-interval | p (Holm) | positive seeds | item bootstrap (seeds fixed) | result |
|---|---|---|---|---|---|---|---|
| **H1: PP16 note − PP16 plain** | **+0.0369** | 0.0148 | **[+0.031, +0.043]** | 1.4e-11 | 24/24 | [+0.021, +0.053] | **supported** |
| H2: R note − R plain | +0.0432 | 0.0133 | [+0.038, +0.049] | 1.3e-13 | 24/24 | [+0.026, +0.061] | **supported** |
| H3: PP16 note − R plain | +0.0470 | 0.0099 | [+0.043, +0.051] | 4.9e-17 | 24/24 | [+0.030, +0.063] | **supported** |

The item-bootstrap intervals also exclude 0, so by the pre-registered rule (§4.4) the effect is not
confined to E2's particular items.

## Exploratory (no confirmatory claim)

- **Where the gain comes from.** Almost entirely from two Standard English skills. Note − plain (PP16):
  **boundaries +0.233, transitions +0.149**, form_structure_sense +0.008; the seven other skills range from
  −0.022 (words_in_context) to +0.006. Standard English as a whole: PP16 0.510 → 0.640, R 0.501 → 0.642.
  The other skills: 0.956 → 0.953 (PP16), 0.945 → 0.947 (R). The reading skills are near the ceiling on E2,
  and the notes neither help nor clearly hurt them. In development some reading skills dropped (FINDINGS #44).
- **Selection with and without notes.** PP16 − R: plain +0.0101 [+0.005, +0.016] (the DC result,
  reproduced). With notes it is **+0.0038 [−0.001, +0.008]**. PP16 − PJ with notes: +0.0008 [−0.006, +0.007].
  The notes close most of the gap that PanelProbe selection opened. Both mostly act on the same weak skills,
  so their effects partly overlap rather than add.
- **PJ** note − plain +0.0397 [+0.034, +0.046].
- **Strict scoring** gives the same answers: H1 +0.0365, H2 +0.0428, H3 +0.0469, all intervals above 0.
  Parseable answers (strict): 99.8–99.9% plain, 99.5% with notes.
- **Method check.** The plain answers (strict scoring) match the runs' own DC evaluation: means 0.8219 vs
  0.8203 (PP16), 0.8116 vs 0.8099 (R), 0.8181 vs 0.8189 (PJ). The largest per-seed gap is 0.018 (on S in
  development: 0.007). The gap comes from re-running greedy decoding through a separately loaded adapter
  on 600 items. It does not affect the hypotheses, since both conditions come from this same pass.

## Conclusion

For OLMo-3-7B students trained with 40 GRPO updates, **showing a short, general note for the question's
sub-type at test time raises held-out accuracy by about 4 points, whatever the training selection was**
(PP16 +3.7, R +4.3, PJ +4.0; every seed positive). The PP16 student with notes beats the plain
random-selection baseline by 4.7 points. That is about 4.7 times what PanelProbe selection alone gives
on E2 (DC H2, +1.0). The note set is fixed: 72 notes written by Claude Opus 5.5 from training items,
routed without the key by Claude Sonnet 5.5.

What the result does and does not say:
- **It is help at test time, not learning.** The student does not keep anything from the notes. When it
  was trained to answer without them, it did not internalise them (FINDINGS #45).
- **The gain is narrow.** It comes from two rule-based Standard English skills (sentence boundaries,
  transitions), where a stated rule fixes a systematic error. On the reading skills, already at about 95%
  on E2, the notes do nothing.
- **Selection and notes overlap.** With notes, PP16's advantage over random falls from +1.0 to +0.4 point
  and is no longer clearly above 0. Much of what targeted training buys on E2 is also bought by the note
  on the same weak skills.
- **Limits** (pre-registration §9): E2's plain results were already public; E2 and the notes come from the
  same model family (Claude Opus 5.5). The study used one student, one note set and one router.
