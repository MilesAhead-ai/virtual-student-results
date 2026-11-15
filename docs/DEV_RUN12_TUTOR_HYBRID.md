# Dev run 12: does a tutor improve GRPO training? (2026-11-15)

Plan: `TUTOR_FEEDBACK_PLAN.md` C1, decision E24. Arms GRPO + F1 (key and "explain why"), GRPO + F2 (one
tutor-written explanation), GRPO + F4 (Claude Opus 5.5 adaptive tutor that reads the student's reasoning,
diagnoses, and withholds the key for two turns). In every hybrid arm all 32 presented items get outcome
GRPO as usual; the greedily wrong ones go to the feedback condition, and the student's accepted
re-solution is added as an SFT example in the same step (`training.method: grpo_feedback`,
`sft_weight` 0.5 on GRPO's token scale, targets need ≥ 150 reasoning characters, ≤ 350 tokens, no
passage copying, KL 0.05 on SFT tokens; FINDINGS #33–36). PP16 selection, pool v2, seeds 0–2, 40 updates.
Reference: DEV_RUN10's GRPO PP16 at the same seeds (100-update runs, constant lr, read at ≤ u40).
All 9 runs completed; the vLLM servers failed once before any run launched (CUDA launch failure, queue
paused, servers restarted). Analysis: `scripts/analyze_hybrid_dev.py`,
`results/olmo3sft_hybrid_dev/analysis/hybrid_dev.txt`.

## Result: no gain from any feedback condition

Mean S accuracy (3 seeds):

| update | 10 | 20 | 30 | 40 |
|---|---|---|---|---|
| GRPO | 0.696 | 0.719 | 0.727 | **0.742** |
| GRPO + F1 | 0.694 | 0.712 | 0.728 | 0.745 |
| GRPO + F2 | 0.696 | 0.708 | 0.727 | 0.740 |
| GRPO + F4 | 0.695 | 0.710 | 0.726 | 0.742 |

vs GRPO, paired by seed: u40 F1 +0.003 [−0.026, +0.032], F2 −0.003 [−0.032, +0.027], F4 −0.000
[−0.021, +0.020]; AULC u0–40 −0.002 to −0.004 (0–1 of 3 seeds positive). At u20 all three are slightly
behind GRPO (−0.007 to −0.011).

- **Standard English skills** (boundaries, form_structure_sense, transitions; where GRPO stalls and the
  tutor was expected to help): F4 − GRPO +0.012 [−0.060, +0.084], F1 +0.004, F2 −0.006. The pilot's
  form_structure gain (FINDINGS #36, 1 seed) did not replicate (F4 0.410 vs GRPO 0.417).
- **Stable:** answers 555–577 characters at u40 (GRPO 491), unparseable ≤ 0.7%.
- **Tutor yield:** accepted targets for 73% (F1), 86% (F2) and 59% (F4) of wrong items; 8–11 SFT
  examples per update. F4 loses most to leak retries.
- **Cost:** F1 $9, F2 $22, F4 $104 for 3 runs each (judges Sonnet 5.5; F4 tutor Opus 5.5). Tutor ledger
  total $311 of the $1,000 ceiling.

## Conclusion

In this setting (OLMo-3-7B, outcome GRPO, 40 updates), adding tutor-derived re-solutions as a stabilised
SFT term does not improve learning, whether the feedback is the bare key (F1), a written explanation (F2)
or an adaptive Socratic tutor (F4), overall or on the weak Standard English skills. With 3 seeds,
differences up to about ±3 points at u40 cannot be ruled out. Earlier attempts to let the tutor's targets
carry more weight (pure SFT, FINDINGS #33–34; larger SFT weight, #35–36) destabilised the student.
