# Virtual-student evaluation of PanelProbe: experiment records

Does choosing training items by **PanelProbe** difficulty make an LLM student
learn faster? PanelProbe calibrates each item's difficulty with an 8-model
panel of small open models. This repository is the public record of the experiments: settings,
data versions, validity, results and reports. It is a read-only mirror of
`docs/`, `results/` and `configs/confirmatory/` from the (private) source repository; the code is not
included.

## Start here

| file | what it is |
|---|---|
| [`docs/EXPERIMENT_REGISTRY.md`](docs/EXPERIMENT_REGISTRY.md) | **Every experiment**: settings, data version, evaluation mode, validity, headline numbers, current reference settings, comparability rules, and generated per-run tables |
| [`docs/FINDINGS.md`](docs/FINDINGS.md) | What each result means, newest first |
| [`docs/OPEN_DECISIONS.md`](docs/OPEN_DECISIONS.md) | Owner decisions that fixed the settings and the studies (E1–E21) |
| `docs/DEV_RUN*.md`, `docs/STUDENT_SCREEN*.md`, `docs/PLAN_*.md` | Full report for each experiment, and the plan each one followed |
| [`results/registry/runs.csv`](results/registry/runs.csv) | One row per run: all parameters and metrics |
| `results/<experiment>/` | Per-run config, metrics, manifest and analysis |
| [`docs/PREREGISTRATION_CONFIRMATORY_V1.md`](docs/PREREGISTRATION_CONFIRMATORY_V1.md) | The confirmatory study, frozen before any held-out data was seen |
| [`configs/confirmatory/v1/`](configs/confirmatory/v1/) | Its 40 frozen run configs, `FROZEN.json` (hashes) and `topic_twins.json` |
| [`docs/PREREGISTRATION_CONFIRMATORY_DC.md`](docs/PREREGISTRATION_CONFIRMATORY_DC.md) | The second confirmatory study (panel difficulty vs a single model's rating), frozen before its held-out set E2 was read |
| [`configs/confirmatory/dc/`](configs/confirmatory/dc/) | Its 72 frozen run configs and `FROZEN.json` |
| [`docs/PREREGISTRATION_CONFIRMATORY_MV.md`](docs/PREREGISTRATION_CONFIRMATORY_MV.md) | The third confirmatory study (measurement validity), frozen before its estimates existed; `results/confirmatory_mv/` |
| [`docs/PREREGISTRATION_CONFIRMATORY_NB.md`](docs/PREREGISTRATION_CONFIRMATORY_NB.md) | The fourth confirmatory study (a test-time notebook for trained students), frozen before any answer with a note existed; [`configs/confirmatory/nb/`](configs/confirmatory/nb/), `results/confirmatory_nb/` |

## Current state (2026-11-23)

Four pre-registered confirmatory studies are complete. **Each study numbers its own hypotheses (H1,
H2, …), so "H1" means something different in each.** The hypotheses are defined in §2 of each
pre-registration, frozen before the data they test existed or were read (v1 and DC: the held-out
outcomes; MV: the difficulty estimates, whose student outcomes came from v1 and DC; NB: any answer with a
note, on E2, whose plain results DC had already read); the results docs
report them in the same order.

1. **Confirmatory v1 (2026-10-29)** — pre-registration [§2](docs/PREREGISTRATION_CONFIRMATORY_V1.md#2-hypotheses),
   results [`CONFIRMATORY_V1_RESULTS.md`](docs/CONFIRMATORY_V1_RESULTS.md). Student OLMo-3-7B, 40 GRPO
   updates, 600 held-out items (E1), 16 seeds.
   - **H1** (primary): choosing training items by PanelProbe difficulty (panel of 8 small local models) gives
     higher final held-out accuracy than random selection. **Supported:** +1.9 points (95% CI +0.9 to +3.0).
   - **H2**: the oracle (measures the student directly) beats random. **Supported:** +3.2 points.
2. **Confirmatory DC (2026-11-07)** — pre-registration [§2](docs/PREREGISTRATION_CONFIRMATORY_DC.md#2-hypotheses),
   results [`CONFIRMATORY_DC_RESULTS.md`](docs/CONFIRMATORY_DC_RESULTS.md). Fresh topic-disjoint held-out
   set (E2, 600 items), 24 seeds per arm.
   - **H1** (primary): selection by the panel's calibrated difficulty (PP16) beats selection by Claude
     Opus 5.5's direct difficulty rating (PJ). **Not supported:** +0.1 point (CI −0.5 to +0.7).
   - **H2**: panel difficulty beats random. **Supported:** +1.0 (CI +0.5 to +1.6).
   - **H3**: the Opus rating beats random. **Supported:** +0.9 (CI +0.4 to +1.4).
3. **Confirmatory MV (2026-11-11)** — pre-registration [§2](docs/PREREGISTRATION_CONFIRMATORY_MV.md#2-hypotheses),
   results [`CONFIRMATORY_MV_RESULTS.md`](docs/CONFIRMATORY_MV_RESULTS.md). No training; measurement on E1 + E2.
   - **H1** (primary): the 8-small-model panel's difficulty predicts which held-out items trained students
     get wrong better than the Opus 5.5 rating. **Supported:** mean within-skill correlation 0.44 vs 0.32,
     difference +0.12 (CI +0.07 to +0.17).
4. **Confirmatory NB (2026-11-23)** — pre-registration [§2](docs/PREREGISTRATION_CONFIRMATORY_NB.md#2-hypotheses),
   results [`CONFIRMATORY_NB_RESULTS.md`](docs/CONFIRMATORY_NB_RESULTS.md). No training. DC's 72 checkpoints
   at update 40 answer E2 plain and with a short note for the question's sub-type (written by Claude Opus 5.5
   from training items; sub-type chosen by Claude Sonnet 5.5 without the key).
   - **H1** (primary): the note raises PP16-trained students' E2 accuracy. **Supported:** +3.7 points (CI +3.1
     to +4.3), 24/24 seeds; item bootstrap +2.1 to +5.3.
   - **H2**: the same for R-trained students. **Supported:** +4.3.
   - **H3**: PP16 with notes beats R without. **Supported:** +4.7 (CI +4.3 to +5.1).

### What the studies say together

| question | study | answer |
|---|---|---|
| Does targeting training items by panel-calibrated difficulty beat random selection? | v1 H1, DC H2 | **Yes**, twice (+1.9 and +1.0 points) |
| Is the small-model panel a better *measure* of which items LLM students get wrong than a single strong model's direct rating? | MV H1 | **Yes** (correlation 0.44 vs 0.32) |
| Does that better measure make the student *learn more* when used to choose training items? | DC H1 | **No measurable difference** (+0.1 point, CI −0.5 to +0.7); a single-model rating also beats random (DC H3) |
| Does a test-time note for the question's sub-type add to PanelProbe training? | NB H1, H3 | **Yes**, +3.7 points on top of PP16 training, almost all on two Standard English skills; it is help at test time, not learning, and with notes PP16's lead over random shrinks to +0.4 (exploratory) |

Two qualifications:
- In DC the panel arm used panel v2 (the 8 small models plus 7 API models). The 8 small models alone
  were compared in development only: they rank items almost identically to panel v2 (rank correlation
  0.96) and did as well in training over 4 seeds (FINDINGS #29, #30), but this is not confirmed.
- **Why a better measure did not give more learning is not tested.** A plausible reading: the targeting
  rule only needs items roughly near the student's level; both estimates order items well enough for that
  (they correlate about 0.6 with each other), and learning is not sensitive to the remaining ranking error.
  In development, every targeting variant tried (full panel, small panel, the rating with or without the
  panel's scale) was within noise of the others.

What else the records show:
- **Measurement.** In development too, the small-model panel predicts the student's wrong answers better
  than the strongest single model's rating (AUC 0.76 vs 0.70), and the 8 small models alone are as good
  as the extended 15-member panel (FINDINGS #26, #29).
- **Training.** All the targeting variants tried (full panel, small panel only, the rating with or without
  the panel's scale) are within noise of each other in development; the advantage over random is largest
  around 40 updates and fades later as the student outgrows the item pool (FINDINGS #16, #20, #30).
- A second student model (Ministral-8B) showed no PanelProbe advantage (FINDINGS #15).

See the top rows of `docs/FINDINGS.md` for the newest results.

## Notes

- Commit hashes quoted in the documents refer to the private source
  repository.
- Item text and raw model outputs are not published. The item pool includes
  College Board practice items whose licence has not been verified.
- `SYNCED_FROM` records the source commit of the current snapshot.
