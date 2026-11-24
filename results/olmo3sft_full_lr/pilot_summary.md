### Pilot results (S, seed 0, 20 updates; base: focus 0.325, other skills 0.757, 563 characters)

| lr | focus u5 / u10 / u15 / u20 | other skills u20 | unparseable u20 | length u20 |
|---|---|---|---|---|
| 3e-6 | 0.350 / 0.384 / 0.438 / 0.412 | 0.774 | 0.5% | 569 |
| **1e-5** | 0.400 / 0.388 / 0.409 / **0.422** | **0.787** | 0.9% | 811 |
| 3e-5 | 0.428 / 0.409 / 0.378 / 0.403 | **0.691** (−6.6, fails) | 1.6% | 761 (340 at u10) |

**1e-5 is chosen.** It is the largest lr meeting the stability criteria, and its focus accuracy at u20
(0.422) exceeds LoRA's (0.375). Its answers lengthen (811 characters at u20), which needs watching over
40 updates. Single seed: the lr arms are not compared with each other beyond this choice.

**Parity** (`scripts/check_full_parity.py`, 40 D items, greedy, 64 tokens): vLLM serving the run's final
weights against Transformers on the saved weights gives 23/40 identical completions and 39/40 with the
same first 40 characters. The base model gives 23/40 and 36/40. The difference is ordinary vLLM-vs-HF
numerics, so the weight sync is correct.

