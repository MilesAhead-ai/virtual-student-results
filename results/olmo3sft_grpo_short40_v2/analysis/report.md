# Virtual-student analysis

Experiment: `artifacts/olmo3sft_grpo_short40_v2`

Primary metric: **final_accuracy**

## Runs

| run | status | policy | condition | seed | AULC | final accuracy |
|---|---|---|---|---|---|---|
| pp-outcome-grpo-s000-aad294ce | complete | pp | outcome | 0 | 0.6806 | 0.6931 |
| pp-outcome-grpo-s001-a53177c3 | complete | pp | outcome | 1 | 0.6833 | 0.6919 |
| pp-outcome-grpo-s002-7c0cc154 | complete | pp | outcome | 2 | 0.6801 | 0.6881 |
| r-outcome-grpo-s000-71fd0302 | complete | r | outcome | 0 | 0.6825 | 0.6887 |
| r-outcome-grpo-s001-de459d9f | complete | r | outcome | 1 | 0.6852 | 0.6937 |
| r-outcome-grpo-s002-4ef49185 | complete | r | outcome | 2 | 0.6808 | 0.6906 |

## Family S

| contrast | vs | pairs | Δ | 95% CI (pct) | BCa | p | p (Holm) | targeting ratio |
|---|---|---|---|---|---|---|---|---|
| pp | r | 3 | 0.0000 | [-0.0025, 0.0044] | [-0.0025, 0.0023] | 1.000 | 1.000 | fewer than two complete seed triples |
