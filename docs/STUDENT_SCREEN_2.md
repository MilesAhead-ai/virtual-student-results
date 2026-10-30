# Student-model screen, round 2 (2026-10-30)

**Why.** The owner asked to try a second student model after confirmatory v1.
Candidates had to come from model families *outside the panel*: gemma, llama,
phi, qwen and deepseek were excluded, because PanelProbe difficulty is
calibrated on those models' answers. internlm3 was skipped because it
requires remote code.

Method as in `STUDENT_SCREEN.md` (`scripts/screen_students.py`): greedy
answers with the study's student prompt and strict parser on D (200), S
(1,600) and W (706), bf16, one A100 each. Summaries are in
`results/student_screen/*.summary.json`; raw responses are in
`data/raw/student_screen/` (not committed).

| model (revision) | S acc strict / lenient | strict parse (S) | median tokens | truncated | θ (S) | ρ(b, correct) D / S / W | s/item |
|---|---|---|---|---|---|---|---|
| **Ministral-8B-Instruct-2410** (`2f494a1`) | **0.632 / 0.677** | **0.87** | 67 | 0.1% | **0.65** | **−0.33 / −0.35 / —** | 0.31 |
| Falcon3-7B-Instruct (`1e57a0e`) | 0.495 / 0.716 | 0.55 | 4 | 0% | −0.02 | −0.22 / −0.19 / — | 0.05 |
| Mistral-7B-Instruct-v0.3 (`c170c70`) | 0.407 / 0.603 | 0.50 | 5 | 0% | −0.44 | −0.21 / −0.24 / — | 0.10 |
| Granite-3.3-8B-Instruct (`51dd4bc`) | 0.357 / 0.454 | 0.43 | 11 | 0% | −0.68 | −0.35 / −0.25 / — | 0.36 |
| Yi-1.5-9B-Chat (`1a0fc69`) | 0.416 / **0.759** | 0.46 | 512 | **100%** | −0.40 | −0.14 / −0.11 / −0.16 | — |
| SmolLM3-3B (`a07cc9a`) | 0.122 / 0.566 | 0.15 | 16 | 0% | −2.23 | −0.27 / −0.20 / −0.25 | 0.07 |
| *reference: Olmo-3-7B-Instruct-SFT (current student)* | *0.676 (from F10 u0)* | *0.97* | *80* | *0%* | *0.75* | *−0.39 / — / −0.45* | *0.52* |

(— : W column omitted for brevity; values are in the summaries.)

Reading:

- **Ministral-8B is the only usable new candidate as it stands.** It reasons
  briefly (median 67 tokens) and follows the answer format 87% of the time
  (OLMo-3: 97%). It sits mid-panel, slightly below OLMo-3 (θ 0.65 vs 0.75),
  and PanelProbe difficulty predicts its correctness almost as well
  (ρ ≈ −0.35). It comes from a different family (Mistral) and is 1.7× faster
  per answer. Its licence is the Mistral Research License: research use is
  fine, commercial use is not.
- **Falcon3, Mistral-7B and Granite answer with a bare letter** (median
  4–11 tokens), and about half of their answers fail the strict parser.
  Training them would again be dominated by format learning (FINDINGS #6).
- **Yi-1.5-9B never stops** (100% truncated at 512 tokens), almost certainly
  an end-of-turn token that generation does not treat as EOS. Its lenient
  accuracy, 0.76, is the highest of all candidates. It might be a stronger
  student once fixed. But PanelProbe difficulty predicts its correctness only
  weakly (ρ −0.11 to −0.16), and the truncation may depress that, so it would
  need a re-screen.
- **SmolLM3-3B** writes `Answer: D) <option text>`, which the strict parser
  rejects, and gives no reasoning. Weak (lenient 0.57).
- No candidate is both clearly weaker than OLMo-3 *and* well formatted, so
  the "weaker student" idea cannot be tested with this set.
