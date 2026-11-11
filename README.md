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

## Current state (2026-11-11)

Three pre-registered confirmatory studies are complete.

1. **Confirmatory v1 (2026-10-29): both hypotheses supported**
   ([`docs/CONFIRMATORY_V1_RESULTS.md`](docs/CONFIRMATORY_V1_RESULTS.md)). With difficulty from a panel of
   8 small local models, PanelProbe selection beats random selection by +1.9 points of final held-out
   accuracy after 40 updates (95% CI +0.9 to +3.0; 16 seeds, 600 held-out items). An oracle that measures
   the student directly reaches +3.2.
2. **Confirmatory DC (2026-11-07): H1 not supported, H2 and H3 supported**
   ([`docs/CONFIRMATORY_DC_RESULTS.md`](docs/CONFIRMATORY_DC_RESULTS.md)). On a fresh, topic-disjoint
   held-out set (600 items, 24 seeds per arm): targeting by the panel's difficulty beats random (+1.0, CI
   +0.5 to +1.6), and so does targeting by Claude Opus 5.5's direct rating (+0.9, CI +0.4 to +1.4); the
   panel's difficulty does not beat the rating in training (+0.1, CI −0.5 to +0.7).
3. **Confirmatory MV (2026-11-11): H1 supported** ([`docs/CONFIRMATORY_MV_RESULTS.md`](docs/CONFIRMATORY_MV_RESULTS.md)).
   On 1,199 held-out items (E1 + E2), difficulty from the panel of 8 small open models predicts which items
   trained students get wrong better than Claude Opus 5.5's direct rating: mean within-skill correlation
   0.44 vs 0.32, difference +0.12 (CI +0.07 to +0.17), on each set separately as well.

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
