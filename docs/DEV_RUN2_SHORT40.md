# Short runs: 40 updates, R vs PP × 3 seeds (2026-10-11)

Same setup as `DEV_RUN1_RESULTS.md` (OLMo 3 7B Instruct-SFT, outcome-only
GRPO, pool_v1, vLLM), but 40 updates, with D evaluated every 5.
Artifacts: `artifacts/olmo3sft_grpo_short40/`.

**AULC: PP − R = −0.0012, 95% CI [−0.0031, 0.0000]** (3 pairs; p = 0.07).
PP is no better on the area under the curve.

But PP does what it is designed to do, and its gains land where expected:

| updates | PP selected b | PP in target band | PP measured acc | R selected b | R in band | R acc |
|---|---|---|---|---|---|---|
| 1–10 | +0.51 | 73% | 0.58 | −0.36 | 18% | 0.74 |
| 11–20 | +0.41 | 52% | 0.62 | −0.37 | 15% | 0.74 |
| 21–30 | +0.18 | 40% | 0.69 | −0.33 | 17% | 0.75 |
| 31–40 | +0.12 | 33% | 0.71 | −0.34 | 16% | 0.77 |

- Gradient-bearing GRPO groups: **PP 0.77 vs R 0.62**.
- Final D accuracy (update 40): PP 0.785 / 0.800 / 0.780 vs R 0.775 / 0.780 /
  0.750. PP is higher in all 3 seeds (+0.01, +0.02, +0.03).
- Gain by D-difficulty tertile, update 0 → 40 (mean of 3 seeds):

  | | easy | mid | hard |
  |---|---|---|---|
  | PP | 0.93 → 0.95 | 0.74 → **0.81** | 0.50 → **0.61** |
  | R | 0.93 → 0.95 | 0.76 → 0.77 | 0.52 → 0.58 |

Reading: PP spends its early updates on hard items, where the student is
weak. Its D curve dips in the middle of the run and finishes higher, so AULC
(which weights the whole curve) and final accuracy disagree. D has 66
items per tertile and these are 3 seeds, so all of this is suggestive, not
evidence. Hard-item depletion still appears even in 40 updates: in-band falls
from 73% to 33%.

Implications for the design (study owner's call):

- The primary outcome matters. AULC rewards fast early gains; final accuracy
  or hard-item accuracy would favour PP here.
- An easy-heavy evaluation set (D, and E1 drawn the same way) hides gains on
  hard items behind a 0.93–0.95 ceiling. The P3 top-up will put harder items
  into E1 and D as well.
