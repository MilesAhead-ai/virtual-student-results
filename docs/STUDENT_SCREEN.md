# Student-model screen (2026-10-09)

`scripts/screen_students.py` on the pool's D split (200 generated items) and W
(706 bank items, 471 of them real College Board). It uses the study's own
student prompt and answer parser, with greedy decoding (batched, bf16, one
A100 each). Raw responses: `data/raw/student_screen/` (not committed).

| model (revision) | acc D | acc W | strict parse | median tokens | truncated | θ on panel scale | ρ(b, correct) D / W | s/item (batch 32) |
|---|---|---|---|---|---|---|---|---|
| Olmo-3-7B-Instruct (`6e5971d`) | 0.765 | 0.711 | 0.99 / 0.98 | 99 | 1–2% | 0.93 | −0.43 / −0.44 | 0.68 |
| **Olmo-3-7B-Instruct-SFT** (`e1452fc`) | 0.740 | 0.674 | 0.97 / 0.97 | 80 | 0–0.3% | 0.75 | −0.39 / −0.45 | 0.52 |
| OLMo-2-1124-7B-Instruct (`470b1fb`) | 0.320 | 0.418 | 0.44 / 0.68 | 4 | 0% | −1.2 / −0.6 | −0.18 / −0.27 | 0.07 |
| OLMo-2-0425-1B-Instruct (`48d788e`) | 0.000 (0.235 lenient) | 0.000 (0.227 lenient) | 0.00 | 150 | 0% | (−1.7 lenient) | −0.09 (lenient) | 0.26 |

Panel abilities on the same scale (mean over skills): phi3 0.28,
llama3.2 0.29, gemma2 0.41, llama3.1 0.89, qwen2 0.91, deepseek-r1 2.12,
qwen3:8b 2.18, qwen3:14b 2.35.

Reading:

- Both OLMo 3 7B checkpoints sit **mid-panel**: above the weak members,
  level with llama3.1/qwen2, well below qwen3/deepseek. So PanelProbe can
  rank items around them (no ceiling problem), and there is about one logit
  of headroom up to the strong members.
- **PanelProbe difficulty predicts their correctness out of panel**
  (Spearman −0.39 to −0.45 against 0/1 correctness on held-out items). This
  is the study's premise, now checked on a model outside every panel family.
- Both follow the answer format (97–99% strict parse) without training.
- Neither shows a College Board advantage: W accuracy is below D accuracy
  even though W items are harder on the panel scale.
- OLMo 2 7B mostly answers with a bare letter (median 4 tokens) and often
  not in the required format. OLMo 2 1B is at chance even with lenient
  parsing. Neither is a usable student.

Cost note: one greedy answer takes 0.5–0.7 s on an A100 in batches of 32. The
PT arm needs slate × rollouts generations per presentation: 64 × 4 × 3,200
≈ 820k per run, about 115 GPU-hours. `selection.pt.rollouts_per_candidate`
and the slate size used for PT should be set with this in mind.
