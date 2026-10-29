# Confirmatory v1: results (2026-10-29)

Pre-registration: `PREREGISTRATION_CONFIRMATORY_V1.md`, frozen 2026-10-28
(tag `confirmatory-v1-frozen`). All 40 runs completed: 0 failures, 0
retries, no server faults (queue log
`artifacts/olmo3sft_grpo_confirmatory_v1_queue.log`). E1 was not read until
the queue logged `END done=40` (2026-10-29 14:24 UTC). The analysis is
`scripts/confirmatory_analysis.py`, committed before it was run (`aa9c0d1`).
Its first run stopped while serialising numpy scalars to JSON, before printing
anything; the fix (`git log`) changes only type conversions. Output:
`results/olmo3sft_grpo_confirmatory_v1/analysis/confirmatory_analysis.json`.

## Primary and secondary hypotheses (final E1 accuracy, 600 items)

Initial E1 accuracy (same base model in every run): 0.6917. Final, mean over
seeds: **R 0.7312, PP 0.7503, PT 0.7577.**

| hypothesis | seeds | mean Δ | seed sd | 95% t-interval | p (two-sided) | p (Holm) | positive seeds | result |
|---|---|---|---|---|---|---|---|---|
| **H1: PP − R** | 100–115 (16) | **+0.0191** | 0.0199 | **[+0.0085, +0.0296]** | 0.0016 | 0.0016 | 13/16 | **supported** |
| **H2: PT − R** | 100–107 (8) | **+0.0319** | 0.0140 | **[+0.0202, +0.0435]** | 0.00035 | 0.0007 | 8/8 | **supported** |

Per-seed PP − R: +0.037, +0.010, +0.060, −0.008, +0.032, +0.033, −0.005,
+0.012, +0.022, +0.048, +0.005, +0.035, +0.012, +0.003, +0.012, −0.002.

Secondary (not decisive): an item bootstrap with seeds fixed gives H1
[+0.009, +0.030]. The built-in `analyze` report gives PP − R +0.0191
(percentile [0.0103, 0.0285]) and PT − R +0.0319 ([0.0227, 0.0408]).

The development estimate (+0.019 on S) replicated almost exactly on held-out
items with fresh seeds. The seed sd of the paired difference on E1 (0.0199)
was larger than planned (0.0165), and the interval still excludes 0.

## Pre-registered topic-twin checks (§4.4)

| check | result |
|---|---|
| (a) exposure: share of training presentations that are E1 twins | R 0.0802, PP 0.0862; **PP − R +0.0060** [+0.0014, +0.0105], p 0.014 |
| (b) H1 on the 313 twin-free E1 items | **PP − R +0.0270** [+0.0145, +0.0394], p 0.0003, 12/16 positive |
| implied PP − R on the 287 twin items | +0.0105 |

**Interpretation.** Check (a) finds a small imbalance: PP trained on E1-twin
topics slightly more often than R (8.6% vs 8.0% of presentations). In
development the shares were equal. Under the pre-registered logic this means
(b) decides whether topic overlap could explain H1. It cannot. On E1 items
whose topic never appears in training, PP's advantage is larger (+0.027),
while on twin items it is smaller (+0.010). If PP's gain came from extra
exposure to twin topics, it would concentrate on the twin items, which is
the opposite of what is observed.

## Exploratory (no confirmatory claim)

- **Targeting ratio** (seeds 100–107): (PP − R)/(PT − R) = **0.67**. In
  development it was 0.98. The oracle gained more here (+0.032 vs +0.021 on
  S in F10), and PanelProbe recovered two thirds of it.
- **Final S** (secondary eval set, which also guided development): PP − R
  +0.0168 [+0.011, +0.023], 15/16 positive; PT − R +0.0234 [+0.015, +0.032].
- **Skill, not format.** Accuracy among parseable answers on E1 rises
  +0.046 for PP, +0.052 for PT and +0.027 for R. Unparseable answers end at
  ≤ 0.3% in every arm.
- **Mechanism.** Gradient-bearing groups in the last 10 updates: R 0.50,
  PP 0.66, PT 0.74.
- **Reasoning length.** Mean final answer length: R 511, PP 477, PT 414
  characters. Runs below 350 characters: R 1/16, PP 0/16, PT 3/8. That is
  fewer than the ~1/3 expected under E9.
- **Per skill** (60 items each, noisy): PP − R is positive in 8 of 10 skills
  (largest: text_structure +0.050, inferences +0.046). It is negative on the
  two Standard English skills, boundaries (−0.003) and form_structure_sense
  (−0.026).

## Conclusion

In this setting (OLMo-3-7B-Instruct-SFT, outcome-only GRPO with lr 2e-4 and
KL 0.05, 40 updates, the pool-v1-final item bank), **choosing training items
by PanelProbe difficulty makes the student learn more than random
selection.** Final held-out accuracy is +1.9 points higher (95% CI +0.9 to
+3.0), and the effect holds on items whose topics never appear in training.
An oracle that measures the student directly does better still (+3.2
points); PanelProbe captures about two thirds of that without querying the
student.

Limits (pre-registration §10): one student model; outcome-only training;
settings tuned on S; a generated pool with topic reuse and few very hard
items late in training.
