# Virtual-student analysis

Experiment: `artifacts/olmo3sft_grpo_pt16`

Primary metric: **final_accuracy**

## Runs

| run | status | policy | condition | seed | AULC | final accuracy |
|---|---|---|---|---|---|---|
| pp-outcome-grpo-s000-2dbc997d | complete | pp | outcome | 0 | 0.6825 | 0.6994 |
| pp-outcome-grpo-s001-4bdc9c53 | complete | pp | outcome | 1 | 0.6857 | 0.6919 |
| pp-outcome-grpo-s002-63fa6406 | complete | pp | outcome | 2 | 0.6833 | 0.6881 |
| pt-outcome-grpo-s000-3783a148 | complete | pt | outcome | 0 | 0.6822 | 0.6913 |
| pt-outcome-grpo-s001-269b78a1 | complete | pt | outcome | 1 | 0.6833 | 0.6956 |
| pt-outcome-grpo-s002-6ad8117e | complete | pt | outcome | 2 | 0.6830 | 0.6944 |
| r-outcome-grpo-s000-c717e145 | complete | r | outcome | 0 | 0.6800 | 0.6875 |
| r-outcome-grpo-s001-830dfea6 | complete | r | outcome | 1 | 0.6816 | 0.6887 |
| r-outcome-grpo-s002-a6f256db | complete | r | outcome | 2 | 0.6840 | 0.6906 |

## Family S

| contrast | vs | pairs | Δ | 95% CI (pct) | BCa | p | p (Holm) | targeting ratio |
|---|---|---|---|---|---|---|---|---|
| pp | r | 3 | 0.0042 | [-0.0025, 0.0119] | [-0.0025, 0.0090] | 0.298 | 0.298 | 0.8696 |
| pt | r | 3 | 0.0048 | [0.0037, 0.0069] | [0.0037, 0.0058] | 0.000 | 0.000 | — |
