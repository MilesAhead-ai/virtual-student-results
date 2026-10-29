# Virtual-student evaluation of PanelProbe: experiment records

Does choosing training items by **PanelProbe** difficulty make an LLM student
learn faster? PanelProbe calibrates each item's difficulty with an 8-model
panel. This repository is the public record of the experiments: settings,
data versions, validity, results and reports. It is a read-only mirror of
`docs/`, `results/` and `configs/confirmatory/` from the (private) source repository; the code is not
included.

## Start here

| file | what it is |
|---|---|
| [`docs/EXPERIMENT_REGISTRY.md`](docs/EXPERIMENT_REGISTRY.md) | **Every experiment**: settings, data version, evaluation mode, validity, headline numbers, current reference settings, comparability rules, and generated per-run tables |
| [`docs/FINDINGS.md`](docs/FINDINGS.md) | What each result means, newest first |
| [`docs/OPEN_DECISIONS.md`](docs/OPEN_DECISIONS.md) | Decisions that fixed the settings (E1–E10) and open questions |
| `docs/DEV_RUN*.md`, `docs/STUDENT_SCREEN.md` | Full report for each experiment |
| [`results/registry/runs.csv`](results/registry/runs.csv) | One row per run: all parameters and metrics |
| `results/<experiment>/` | Per-run config, metrics, manifest and analysis |
| [`docs/PREREGISTRATION_CONFIRMATORY_V1.md`](docs/PREREGISTRATION_CONFIRMATORY_V1.md) | The confirmatory study, frozen before any held-out data was seen |
| [`configs/confirmatory/v1/`](configs/confirmatory/v1/) | Its 40 frozen run configs, `FROZEN.json` (hashes) and `topic_twins.json` |

## Current state

**Confirmatory v1 is complete (2026-10-29): both pre-registered hypotheses are
supported** ([`docs/CONFIRMATORY_V1_RESULTS.md`](docs/CONFIRMATORY_V1_RESULTS.md)).
On 600 held-out items with 16 fresh seeds, PanelProbe selection beats random
selection by +1.9 points of final accuracy (95% CI +0.9 to +3.0). An oracle
that measures the student directly reaches +3.2. See the top rows of
`docs/FINDINGS.md` for everything else.

## Notes

- Commit hashes quoted in the documents refer to the private source
  repository.
- Item text and raw model outputs are not published. The item pool includes
  College Board practice items whose licence has not been verified.
- `SYNCED_FROM` records the source commit of the current snapshot.
