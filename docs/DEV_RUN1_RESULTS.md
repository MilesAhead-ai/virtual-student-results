# First real-student development runs (2026-10-10)

OLMo 3 7B Instruct-SFT, outcome-only GRPO, 100 updates × 32 presentations,
pool_v1, vLLM generation. R (random) vs PP (PanelProbe), seeds 0 and 1.
Artifacts: `artifacts/olmo3sft_grpo_dev_vllm/`; report in `analysis/report.md`.

| run | AULC (D) | D acc, update 0 → 100 | selected b (mean) | measured acc | gradient-bearing groups |
|---|---|---|---|---|---|
| PP s0 | 0.7555 | 0.735 → 0.745 | −0.06 | 0.73 | 0.55 |
| PP s1 | 0.7615 | 0.730 → 0.790 | −0.09 | 0.73 | 0.55 |
| R s0 | 0.7578 | 0.735 → 0.780 | −0.34 | 0.76 | 0.50 |
| R s1 | 0.7580 | 0.730 → 0.770 | −0.34 | 0.76 | 0.49 |

**PP − R: ΔAULC = +0.0006, 95% CI [−0.0023, 0.0035]** (2 pairs). No
detectable difference. All four runs improve by 1–6 points on D (200 items,
SE ≈ 0.03), so GRPO training works. Two seeds cannot support inference, and
D is not E1.

## Why PP and R end up alike: PP runs out of hard items

PP seed 0, by quarter of the run:

| updates | tracker θ | selected b | predicted p | in target band [.35, .65] | measured acc |
|---|---|---|---|---|---|
| 1–25 | 0.90 | +0.42 | 0.59 | 58% | 0.61 |
| 26–50 | 1.47 | +0.09 | 0.72 | 33% | 0.74 |
| 51–75 | 1.65 | −0.25 | 0.78 | 23% | 0.78 |
| 76–100 | 1.81 | −0.51 | 0.79 | 16% | 0.80 |

R stays at selected b ≈ −0.35 and 14–17% in band throughout.

PP targets as designed in the first quarter. It then exhausts the pool's hard
items, because selection is without replacement. By the last quarter it
picks *easier* items than R. The supply is thin: P + P+ items with b > 0.5
per skill are central_ideas 25, rhetorical_synthesis 30, text_structure 46,
command_of_evidence 61, cross_text 77, form_structure 78, inferences 108,
words_in_context 150, boundaries 166, transitions 266, out of about 640 each.
A run makes 320 presentations per skill.

So with this student, the pool cannot sustain the target success
probability for a full run, and the selection manipulation fades. This is
the generation finding again (AI items land easy) showing up as a design
constraint.

## Options

1. **More hard items.** Generate asked-D4/D5-heavy batches, keep only items
   with b > 0.5 after scoring, and top up each skill to a few hundred.
   Measured hard yield is ~27%, so roughly 4× over-generation. Cost is fine,
   at about $0.06 per item plus ~0.6 GPU-h per 1,000 items × 3 passes.
2. **Shorter runs**, e.g. 40–50 updates, so that the hard supply lasts.
   Learning per run is smaller, though.
3. **A weaker starting student.** Its p = 0.5 point then sits where the pool
   is dense. But the screened weaker OLMo models are unusable, and the panel
   ceiling makes the easy end hard to rank.
4. **Change the design to sample with replacement.** This departs from the
   spec (§9.2), so it is a scientific decision.

Recommendation: option 1, possibly with 2. It keeps the spec's design and
attacks the binding constraint directly.
