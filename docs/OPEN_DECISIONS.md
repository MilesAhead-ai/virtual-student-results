# Open decisions

Everything below must be decided by the study owner before a confirmatory
run. None of it is a software question. Recorded 2026-10-02, after the M0
software milestone (commit `8d401cd`).

Status key: **open** = nobody has decided; **proposed** = a recommendation
exists here but is not accepted.

## A. Missing scientific design

| # | Decision | Status | Notes |
|---|---|---|---|
| A1 | The scientific design document (`virtual_student_design_revised.md`) | **open** | It does not exist. The spec says it governs estimands, treatments, and interpretation. Every item in section B traces back to it. |
| A2 | What distinguishes stage 1, 2, and 3 | **open** | `configs/stage{1,2,3}.example.yaml` are identical apart from `stage`. Arms, seeds, students, and contrasts per stage are undefined. |
| A3 | What the W, E2, E3, E4, E5 splits contain | **open** | The spec names them without defining them. The code only knows E4/E5 may have an empty passage and E3 has a licensing question. W is currently used as the panel calibration split. |
| A4 | Misconception taxonomy | **open** | `taxonomies/sat_rw_misconceptions.yaml` is a placeholder (`status: development_placeholder`); confirmatory preflight rejects it. |

## B. Values left `REQUIRED` in the confirmatory templates

The stage templates have 51 unresolved values that a default SFT + PP run
uses, and more under other arms. Grouped:

| Group | Fields | Status |
|---|---|---|
| Student | `student.model_id`, `student.revision` (40-hex commit), `student.chat_template_hash` | **open** |
| Optimiser | `training.{learning_rate, weight_decay, warmup_steps, lr_schedule, max_grad_norm, max_target_tokens, max_consecutive_no_gradient_updates}`, `training.lora.{rank, alpha, dropout, target_modules}` | **open** |
| GRPO | `grpo.kl_coefficient` | **open** |
| Tracker | `tracker.process_variance` (`tracker fit-process-variance` proposes one from development runs) | **open** |
| PT arm | `selection.pt.rollouts_per_candidate`, `selection.pt.tracker_difficulty_rule` (spec §14 forbids a default) | **open** |
| Feedback | `feedback.{resolve_temperature, dialogue_temperature, f2_token_target, sibling_map_version, sibling_difficulty_tolerance, sibling_check_context}` | **open** |
| Tutor and judges | `provider`, `model_id`, `model_revision`, `maximum_output_tokens` for the tutor and each of the four judges | **open** |
| Panel | `panel.calibration_splits`, `panel.{theta,difficulty}_prior_{mean,variance}` (sat-reading-platform used N(0, 2) for both) | **open** |
| Statistics | `statistics.{minimum_effect_aulc, equivalence_margin_aulc, reference_condition, contrast_families}` | **open** |
| Data | `data.e3_license_decision`, `data.dedup.{embedding_model, embedding_revision, embedding_threshold}`, the frozen split file | **open** |
| Budget | `budget.{compute_gpu_hours, paid_api_usd}` | **open** |

## C. Constraints found while building M0

| # | Finding | Consequence | Status |
|---|---|---|---|
| C1 | **The item bank is about 10× too small.** A run is 3,200 presentations without replacement: ≥ 320 pool items per skill, plus 60 E1 items per skill. The bank has 42–90 items per skill in total. | Preflight's `selection.pool_support` rejects any full-length run. | **decided 2026-10-02**: minimum target, 6,240 landed items — `docs/ITEM_GENERATION_PLAN.md` |
| C2 | **E1 cannot be real College Board items for every skill.** Real items per skill: cross_text_connections 8, central_ideas 15, … words_in_context 73. | At least some of E1 must be generated, or E1's size must change. | **open** |
| C3 | **Current Claude models reject `temperature`** (HTTP 400). The spec's `tutor.temperature: 0.0` cannot be sent. | Live configs must set `temperature: null`. Reproducibility rests on the response cache. | decided in code |
| C4 | **No refusal fallback.** It would swap the tutor model mid-run. | A refusal is a protocol failure: retry, then that item's feedback fails. | decided in code; revisit if refusals turn out frequent |
| C5 | **The panel runs on CPU** (all 8 A100s are held by a vLLM job that has been running for 63 days). Measured on Stage A/B: ~7–8 minutes per item for all 8 models, one request at a time. | Panel scoring, not generation, is the bottleneck for C1. | **decided 2026-10-02**: try same-model concurrency on CPU, measure in the pilot, then choose |

## D. Software deviations from the spec

Listed with reasons in `README.md` → "Deviations from the spec". They are
recorded decisions, but the study owner may overrule any of them.

## E. Decided 2026-10-05

| # | Decision |
|---|---|
| E1 | Pool items whose blind key verification is not `agree` are dropped (`data.drop_key_flagged: true`): 46 of P1's 7,457. |
| E2 | E1 consists of generated items for every skill. Real College Board items stay in W. |
| E3 | Every item is panel-scored three times (W and pool alike), and calibration uses the binomial likelihood over repeats. This changes what a PanelProbe difficulty is: one run gave a test-retest reliability of only ~0.6–0.8. |
| E4 | Pool target raised to the plan's recommended size: 880 usable items per skill (8,800 total). Batch P2 tops each skill up from P1's usable count. |
| E5 | (2026-10-11) Hard-item top-up to ≥ 300 items with b > 0.5 per skill in P+P+, spread across all splits by the stratified re-split. Round P3: 15,626 generated → 2,931 kept by a 5-model screen (b̂ > 0.3) → 3 fresh full-panel passes. Round P4 (full top-up, chosen over a cheaper partial one): 13,839 generated, about $830. |
| E6 | (2026-10-12) The last top-up round, P5 (~1,570 items, about $95), covers form_structure_sense, cross_text, command_of_evidence, and boundaries. These are the skills that still fall short of 300 once difficulty is measured from 3 passes. |
| E7 | (2026-10-13) The primary outcome for development comparisons is **final accuracy** on the evaluation set (`statistics.primary_metric: final_accuracy`), decided before the runs it applies to. AULC is still reported. Development runs evaluate on S (1,600 items, SE ≈ 0.01) as the primary set, with D as a secondary set. S is not used in outcome-only GRPO. |
| E8 | (2026-10-19) Development training keeps the student's full reasoning: GRPO uses a KL penalty to the base policy, not the cosine schedule that shortened answers to about 150 characters (DEV_RUN6_STABILITY.md). The seeded R/PP/PT re-test runs at lr 2e-4, constant schedule, KL 0.05, 3 seeds, on batch-invariant vLLM. This is the only tested KL setting that both keeps the reasoning (about 550 characters) and learns (+3.5 points among parseable answers). |
| E9 | (2026-10-27) The confirmatory configuration uses **KL 0.05** (lr 2e-4 constant), chosen over KL 0.1 after DEV_RUN8. This relaxes E8: the owner accepts that about 1/3 of runs shorten their answers below ~350 characters, in exchange for the larger learning signal (KL 0.1 kept the reasoning in 4/4 seeds but only ~60% of the skill gain). Also adopted from DEV_RUN8: `tracker.theta_initial: 1.0`, no guessing floor (spec §12 unchanged). |
| E10 | (2026-10-28) **Confirmatory v1 frozen** (`docs/PREREGISTRATION_CONFIRMATORY_V1.md`, `configs/confirmatory/v1/FROZEN.json`, tag `confirmatory-v1-frozen`, code `bded020`). Owner sign-off: R and PP × seeds 100–115, PT × 100–107; H1 PP − R on final E1 accuracy (paired t, two-sided α 0.05), H2 PT − R, Holm across both. Preflight's tutor/judge/taxonomy checks are scoped to feedback conditions. E3: not applicable. Dedup: bge-small-en-v1.5 @ 5c38ec7c, cosine ≥ 0.88. The 287 E1 topic-twins are kept; a pre-registered exposure-balance check and a twin-free sensitivity analysis cover them. |
| E11 | (2026-10-30) Second student for a replication: **`mistralai/Ministral-8B-Instruct-2410` @ `2f494a194c5b980dfb9772cb92d26cbb671fce5a`** (STUDENT_SCREEN_2.md). It is from a non-panel family, mid-panel (θ 0.65), strict-format 87%, and ρ(b, correct) ≈ −0.35. Licence: Mistral Research License (research use). Before any comparison: a vLLM parity check and a short learning-rate check, because the reference settings were tuned on OLMo-3. |
| E12 | (2026-10-31) **No confirmatory v2 on Ministral-8B.** The 8-seed dev comparison (F15) found no PP advantage (AULC −0.001 [−0.010, +0.008]); it is reported as an exploratory replication attempt: the effect is student-dependent. Next: OLMo-3 with longer training (100 updates) and a larger slate (16 vs 64), on S, to look for a larger effect and to test whether R catches up once OLMo plateaus (`PLAN_OLMO_LONG.md`). |
| E13 | (2026-11-01) After DEV_RUN9 the owner chose to **build a harder item pool** ("we are not short of money") so PP can keep targeting late in training (`PLAN_HARD_POOL.md`). This requires much harder items and probably stronger panel members to calibrate them. Pilots first; panel extension and held-out-set decisions are pending. |
| E14 | (2026-11-01) For pool v2: (1) **extend the panel with stronger models**, members chosen after pilot 1a; (2) a **fresh, topic-disjoint held-out set** (600 items, 60 per skill) for confirmatory v3 instead of reusing E1; (3) generate with **Claude Opus 5.5**; keep an item only if **both Sonnet 5.5 and Opus 5.5** blind solves agree with its key. |
| E15 | (2026-11-02) After the pilots (FINDINGS #17) the owner chose options **1 and 2**: (1) a targeted G2 top-up for the two skills where G2 yields hard items, **inferences and command_of_evidence** (first tranche 2,000 per skill, 4 subject-area streams each, about $500); (2) **extend the panel with API models via Bedrock**, since open models stop at θ ≈ 2.6. Ten API candidates are scored on W first; members are chosen from their θ. Not chosen: a skill-schedule change (option 3) and stopping (option 4). |
| E16 | (2026-11-02) **Panel v2 members** (owner, after FINDINGS #18): the 8 current Ollama members plus 7 API members via Bedrock: gpt-oss-120b, Claude Haiku 4.5, Mistral Large 3, Qwen3-Next-80B, Llama 4 Maverick, DeepSeek-V3.2, Claude Haiku 5.5. Not included: Nova Pro, Gemma 3 27B, Bedrock qwen3-32b, local qwen3:32b/llama3.3/qwen2.5. **API members score each item once** (they repeat 95–99.9% of answers at temperature 0); Ollama members keep 3 passes (E3) and `repeat_weighting: mean`. Open: whether member abilities are fit on W only (as in v1, which saturates near θ 3) or jointly on W + training pools; both will be computed and compared before choosing. |
| E17 | (2026-11-03) After FINDINGS #19: pool v2 uses the **joint W + P + P+ fit (`pool-v2-wp`)**; no further top-up before step 3. Step 3 starts on pool v2 as is: OLMo R vs PP16, 100 updates, seeds 0–3, parser v2, evaluated on S and D every 5 updates; everything else as DEV_RUN9. |
| E18 | (2026-11-04) After FINDINGS #21–22 the owner chose **tutor feedback** (`TUTOR_FEEDBACK_PLAN.md`), not more item generation: tutor **Claude Opus 5.5**, judges and validator Sonnet 5.5 (not the tutor's model); **API budget ceiling $1,000** for the pilot and dev phases (hard stop; ask the owner before raising it). In parallel, a selection-side test: PP with the whole eligible pool as slate (`candidate_slate_size` 4096) on pool v2, 4 seeds, against DEV_RUN10's R and PP16. |
| E19 | (2026-11-04) Before the tutor dev phase, a **single-model difficulty control** (`PLAN_SINGLE_MODEL_CONTROL.md`): Claude Opus 5.5 rates every item's difficulty once (no panel, no solving required); ratings are mapped to the panel b scale by **within-skill quantile mapping** over the training pool, so the arm differs from PP16 only in which items count as hard; trained like DEV_RUN10 (OLMo, GRPO, pool v2, slate 16, 100 updates, seeds 0–3) and compared with DEV_RUN10's R and PP16. Also the existing **L arm** (staircase over generator labels), same seeds. An offline check of predictive validity comes first. |
| E20 | (2026-11-06) The owner chose to make "panel-calibrated difficulty beats a single-model rating" a **confirmatory result** (`PLAN_CONFIRMATORY_DC.md`) before the tutor dev phase. Held-out set: a **fresh, topic-disjoint E2** (600 items, 60 per skill, stratified by asked label; double key check; twins vs every existing item dropped). Arms **PP16 (panel b), PJ (Opus 5.5 rating, quantile-mapped), R**, each **24 seeds**; primary outcome **final E2 accuracy after 40 updates**; pool v2, settings as DEV_RUN10/11. Pre-registered and frozen like v1 before any E2 result is seen. |
