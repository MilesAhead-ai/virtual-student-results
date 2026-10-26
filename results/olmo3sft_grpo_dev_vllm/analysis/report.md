# Virtual-student analysis

Experiment: `artifacts/olmo3sft_grpo_dev_vllm`

## Runs

| run | status | policy | condition | seed | AULC |
|---|---|---|---|---|---|
| pp-outcome-grpo-s000-d6c44c2b | complete | pp | outcome | 0 | 0.7555 |
| pp-outcome-grpo-s001-a8531baa | complete | pp | outcome | 1 | 0.7615 |
| r-outcome-grpo-s000-92c2d71e | complete | r | outcome | 0 | 0.7578 |
| r-outcome-grpo-s001-fae6d103 | complete | r | outcome | 1 | 0.7580 |

## Family S

| contrast | vs | pairs | ΔAULC | 95% CI (pct) | BCa | p | p (Holm) | targeting ratio |
|---|---|---|---|---|---|---|---|---|
| pp | r | 2 | 0.0006 | [-0.0023, 0.0035] | — | 0.501 | 0.501 | fewer than two complete seed triples |
