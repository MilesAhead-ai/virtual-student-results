# Pre-registration: PanelProbe item selection for an LLM student (confirmatory v1)

**Status: FROZEN 2026-10-28**, signed off by the owner. The frozen configs
and hashes are in `configs/confirmatory/v1/FROZEN.json` (code commit
`bded020`, split lock `6147da9a…`, topic-twin list `297f2dd0…`); git tag
`confirmatory-v1-frozen`. E1 had never been accessed before this point (no
`data/locks/pool_v1/access_log.jsonl` existed).

There is no scientific design document (OPEN_DECISIONS A1). For this study,
this pre-registration takes its place: it fixes the estimand, the arms and
the analysis before any held-out data is seen. Changes after freezing are
listed in §11, never edited into §1–§10.

## 1. Question

Does choosing training items by PanelProbe difficulty (PP) make an LLM
student learn more than choosing them at random (R) under outcome-only GRPO?

Development evidence (pool-v1-final, evaluated on S, not E1):
- PP − R = +0.019 final S accuracy over 7 seeds (t-CI [+0.008, +0.031]).
- PT − R = +0.021 over 3 seeds; targeting ratio 0.98.
- The gain is in accuracy among parseable answers, not format (FINDINGS #10).
- The settings were chosen on S during development (FINDINGS #6–#11). This
  study tests them on held-out items with fresh seeds.

## 2. Hypotheses

- **H1 (primary).** After 40 updates, PP's final accuracy on E1 is higher
  than R's. Estimand: the mean over seeds of the paired difference PP − R in
  final E1 accuracy (all 600 items).
- **H2 (secondary).** PT − R > 0 on the same metric (seeds 100–107).
- **Pre-registered checks (§4.4).** Topic-twin exposure balance, and H1
  restricted to twin-free E1 items.
- **Exploratory, no confirmatory claim:** targeting ratio; final S accuracy;
  accuracy among parseable answers; AULC; per skill; answer length;
  gradient-bearing groups; tracker calibration.

## 3. Design

| component | value |
|---|---|
| Student | `allenai/Olmo-3-7B-Instruct-SFT` @ `e1452fc572d51966ff4aaeb25118b891eb93e549` |
| Data | pool-v1-final: items `b4e060d6…`, split lock `6147da9a…`, split file `data/splits/pool_v1_dev.json`, calibration `pool-v1-gpu3` |
| Arms and seeds | **R and PP: root seeds 100–115 (16 each); PT: 100–107 (8)**, paired by seed; none used in development |
| Training | outcome-only Dr. GRPO, 8 rollouts at T 1.0, ≤ 512 tokens; LoRA r16/α32/dropout 0.05; AdamW lr 2e-4 constant (5 warmup), wd 0, clip 1.0; KL 0.05 to the base policy (E9); 32 items per update; 40 updates |
| Selection | slate 16; PP target success 0.5, band ±0.15; PT 4 rollouts per candidate |
| Tracker | θ₀ 1.0 (E9), initial variance 2.0, process variance 0.05; spec §12 formula unchanged |
| Evaluation | greedy, ≤ 512 tokens, every 5 updates, batch-invariant vLLM; dense sets E1 (primary, 600 items, 60 per skill) and S (secondary) |
| Prompt / parser | `prompts/student_answer.txt`; `answer-line-v1` (strict) |
| Configs | `configs/confirmatory/v1/{r,pp}_s100…115.yaml`, `pt_s100…107.yaml` (40; all pass confirmatory preflight) |

E1 and S have the same difficulty profile (mean b̂ +0.024 vs +0.030; 30% of
items with b̂ > 0.5 in both). All items in both are generated.

## 4. Analysis plan

1. For each seed s, d_s = final E1 accuracy(PP, s) − final E1 accuracy(R, s)
   at update 40.
2. **H1:** two-sided one-sample t-test of {d_s}, α = 0.05; report the mean,
   the t-interval and p. H1 is supported if the interval lies above 0.
3. **H2:** the same for PT − R on seeds 100–107. H1 and H2 are Holm-corrected
   as a family of two.
4. **Topic twins (pre-registered checks).** An embedding check (§7) found
   that 287 of 600 E1 items have a same-topic twin in the training pools
   (rewritten passage, usually a different skill). They are listed in
   `configs/confirmatory/v1/topic_twins.json`, together with the 937 training
   items that twin them.
   - (a) **Exposure balance:** per run, the share of training presentations
     whose item is an E1 twin. Compare PP and R (paired t over seeds). In
     development the shares were equal (R 0.085, PP 0.084).
   - (b) **Sensitivity:** H1's analysis repeated on the 313 twin-free E1 items.
   - Interpretation: if (a) shows no imbalance, topic overlap cannot explain
     PP − R. (b) shows whether the effect holds on items whose topic the
     student never trained on. Neither replaces H1.
5. Secondary, not decisive: an item bootstrap with seeds fixed, and the
   built-in `virtual-student analyze` report. Its seed-bootstrap CI is not
   the test; with few seeds it reduces to min–max (registry §4).
6. **No interim look at E1.** During the runs, monitoring uses only S,
   training signals and run health. E1 metrics are read once, after every run
   has completed. Commands that print primary-set (E1) metrics, such as
   `analyze`, `report` and `build_registry.py`, are not run before then.

## 5. Sample size

The per-seed SD of d on a 600-item set was estimated from the 7 F10 seed
pairs by resampling 60 items per skill from S: 0.0165. Power of the
two-sided paired t-test with 16 seeds is 0.78 at δ = 0.012, **0.93 at
δ = 0.015**, and 0.99 at δ = 0.019 (the development estimate). The twin-free
sensitivity subset (313 items) has less power and is not expected to be
decisive on its own.

## 6. Runs, failures and exclusions

- Every run that completes 40 updates is analysed. There is **no exclusion
  based on outcomes**: answer shortening, letter skew or poor learning are
  reported, never filtered.
- A technical failure (crash, server fault such as an Xid, OOM) is re-run
  from scratch with the same seed (deterministic generation), up to 2 retries.
  A failed run's directory is moved aside, never deleted.
- A seed that still cannot complete is reported as missing. The primary
  analysis then uses complete pairs, with a sensitivity note.
- Before launch, every vLLM server must pass a real `/v1/completions` check
  and the student's batch-invariance probe.

## 7. Frozen data-release values

- **Deduplication.** Exact and normalised-text duplicates: 0. Embedding
  check with `BAAI/bge-small-en-v1.5` @ `5c38ec7c405ec4b44b94cc5a9bb96e735b38267a`,
  CLS-pooled, L2-normalised, cosine on passage + question, **threshold 0.88**.
  The threshold was set by inspecting S pairs only (no E1 text was used to
  choose it): pairs above about 0.84 share a specific topic, and below 0.86
  topics chain into giant clusters, so a fully topic-disjoint split is not
  achievable. 0.88 is the lowest threshold at which twin groups stay small
  (largest 53 items).
- **E3 licence decision:** not applicable. pool-v1-final has no E3 split; the
  College Board items in W are used only for panel calibration.

## 8. Spec interpretations (approved 2026-10-28)

1. Preflight `config.no_dummy_backends` and `taxonomy.frozen` apply only to
   runs whose feedback condition uses the tutor, the judges and the taxonomy.
   R, PP and PT (outcome-only) do not. This matches the spec's rule that
   confirmatory configs must resolve the fields "used by that run" (§5).
2. Single stage: spec stages 1–3 are undefined (A2). This study is one stage
   with the arms above.

**Correction to the draft:** the draft said its config failed preflight
only on the two checks in 8.1. It also failed on four unresolved data-release
fields (`data.dedup.*`, `data.e3_license_decision`); only the last three
lines of the error output had been read. Those fields were resolved as in §7
before freezing.

## 9. Cost and schedule (estimate)

About 18–20 h for 32 R/PP runs plus 10–13 h for 8 PT runs, run concurrently
(≤ 10 at a time, two per training GPU, on three vLLM servers). In total about
1–1.5 days on this machine. No paid API calls.

## 10. Known limitations

- One student model; outcome-only training (no tutor feedback arms).
- All settings were tuned on S during development; E1 is the held-out test.
- Under KL 0.05 about 1/3 of runs shorten their reasoning (E9 accepts this).
- Late in training PP is limited by the pool's supply of hard items
  (DEV_RUN8).
- The generated pool reuses topics across batches. About half of E1 items
  have a same-topic twin in training (§4.4, §7).
- The strict parser counts markdown answers as wrong. It is applied the same
  way in every arm.

## 11. Changes after freezing

(none)
