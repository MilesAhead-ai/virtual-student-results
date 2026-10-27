# Virtual-student analysis

Experiment: `artifacts/olmo3sft_grpo_kl05_seeds`

Primary metric: **final_accuracy**

## Runs

| run | status | policy | condition | seed | AULC | final accuracy |
|---|---|---|---|---|---|---|
| pp-outcome-grpo-s000-28c3455b | complete | pp | outcome | 0 | 0.7099 | 0.7400 |
| pp-outcome-grpo-s001-da85649c | complete | pp | outcome | 1 | 0.7179 | 0.7525 |
| pp-outcome-grpo-s002-833f9d80 | complete | pp | outcome | 2 | 0.7114 | 0.7450 |
| pp-outcome-grpo-s003-5e38b191 | complete | pp | outcome | 3 | 0.7091 | 0.7338 |
| pp-outcome-grpo-s004-f7c06cf5 | complete | pp | outcome | 4 | 0.7155 | 0.7550 |
| pp-outcome-grpo-s005-0da61dd0 | complete | pp | outcome | 5 | 0.7118 | 0.7462 |
| pp-outcome-grpo-s006-160dd0bf | complete | pp | outcome | 6 | 0.7112 | 0.7238 |
| pt-outcome-grpo-s000-7e9e5d1f | complete | pt | outcome | 0 | 0.7141 | 0.7469 |
| pt-outcome-grpo-s001-2743a788 | complete | pt | outcome | 1 | 0.7189 | 0.7431 |
| pt-outcome-grpo-s002-6dce279a | complete | pt | outcome | 2 | 0.7149 | 0.7488 |
| r-outcome-grpo-s000-354a61dc | complete | r | outcome | 0 | 0.7018 | 0.7294 |
| r-outcome-grpo-s001-07388563 | complete | r | outcome | 1 | 0.7044 | 0.7231 |
| r-outcome-grpo-s002-c495cda2 | complete | r | outcome | 2 | 0.7075 | 0.7244 |
| r-outcome-grpo-s003-903ae2bd | complete | r | outcome | 3 | 0.7010 | 0.7169 |
| r-outcome-grpo-s004-3b3f4856 | complete | r | outcome | 4 | 0.6987 | 0.7175 |
| r-outcome-grpo-s005-68a04d45 | complete | r | outcome | 5 | 0.7025 | 0.7256 |
| r-outcome-grpo-s006-9db5f845 | complete | r | outcome | 6 | 0.7066 | 0.7250 |

## Family S

| contrast | vs | pairs | Δ | 95% CI (pct) | BCa | p | p (Holm) | targeting ratio |
|---|---|---|---|---|---|---|---|---|
| pp | r | 7 | 0.0192 | [0.0104, 0.0277] | [0.0094, 0.0271] | 0.000 | 0.000 | 0.9798 |
| pt | r | 3 | 0.0206 | [0.0175, 0.0244] | [0.0175, 0.0229] | 0.000 | 0.000 | — |
|  ↳ unpaired: r-outcome-grpo-s003-903ae2bd, r-outcome-grpo-s004-3b3f4856, r-outcome-grpo-s005-68a04d45, r-outcome-grpo-s006-9db5f845; incomplete: — |||||||||
