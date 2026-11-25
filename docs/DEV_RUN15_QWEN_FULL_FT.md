# DEV_RUN15: Qwen3-8B as the training student, full fine-tuning (development)

**Status: lr pilot running since 2026-11-25 22:12 UTC.** Owner's plan after FINDINGS #49: switch the
student to Qwen3-8B, with full fine-tuning, thinking off, and DEV_RUN13/14's focused note-distillation
design.

## Why

With OLMo-3-7B, distilling note-guided rollouts did not internalise the notes, with LoRA (#48) or with
full fine-tuning (#49). The remaining explanation is the student. Qwen3-8B transfers tutoring better
on the bench (near transfer F4 +0.105 vs OLMo +0.043, #43).

## Setup

- **Student:** `Qwen/Qwen3-8B` @ `b968826d…`.
- **Non-thinking mode:** `templates/qwen3_nothink.jinja` is Qwen's own template with
  `enable_thinking = false`. Every generation prompt ends in an empty think block. The trainer and the
  bench use the same file.
- **Precondition (FINDINGS #50):** with thinking off, the test-time note still raises boundaries
  0.306 → 0.581 and transitions 0.619 → 0.781 on S.
- **Engineering:**
  - Full fine-tuning as DEV_RUN14. Smoke run: peak trainer memory 34.2 GB of 40, about 3 min of
    gradient flush per update, publish 25 s.
  - `STUDENT=qwen3_8b FULL=1 scripts/start_vllm.sh`.
  - Configs: `scripts/make_full_ft_configs.py --student qwen`.
- **Format:** with thinking off, 17.5% of Qwen's D answers fail the strict `answer-line-v2` parser at
  u0 (smoke). They get the −0.1 unparseable reward, so early GRPO partly learns the answer format.

## Stage 1: lr pilot

The design follows DEV_RUN14: focused GRPO (boundaries + transitions), seed 0, 20 updates, lr 3e-6 /
1e-5 / 3e-5. The criteria are DEV_RUN14's:
- pick the largest stable lr: S unparseable ≤ 2% at u20 **or not above u0's**, length 0.5–2× base,
  other skills not more than 3 points below base;
- prefer focus accuracy at u20 above base.

## Stage 2 (planned)

grpo vs note (every item, distilled), seeds 0–3, 40 updates, at the chosen lr.

Analysis, fixed now:
- **Primary:** S boundaries + transitions at u40 without notes, note − grpo paired by seed. Scoring
  is the run's own completions **re-scored with the lenient parser** (`tutor_bench.lenient`, as #44/#50),
  so that learning the answer format does not count as learning the skill.
- **Secondary:** strict scoring (the runs' own `correct`); the other eight skills; answer length;
  the note groups' correct rollouts.
- **Reading:**
  - A clearly positive note − grpo means this student internalises the guidance where OLMo did not.
  - A null means the failure holds across two students and both adapters.
