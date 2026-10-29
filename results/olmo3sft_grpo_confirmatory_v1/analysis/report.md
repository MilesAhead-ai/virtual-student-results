# Virtual-student analysis

Experiment: `artifacts/olmo3sft_grpo_confirmatory_v1`

Primary metric: **final_accuracy**

## Runs

| run | status | policy | condition | seed | AULC | final accuracy |
|---|---|---|---|---|---|---|
| pp-outcome-grpo-s100-c1b7675e | complete | pp | outcome | 100 | 0.7236 | 0.7533 |
| pp-outcome-grpo-s101-02d8bc60 | complete | pp | outcome | 101 | 0.7186 | 0.7533 |
| pp-outcome-grpo-s102-41da1354 | complete | pp | outcome | 102 | 0.7030 | 0.7633 |
| pp-outcome-grpo-s103-3702ac88 | complete | pp | outcome | 103 | 0.7180 | 0.7267 |
| pp-outcome-grpo-s104-01078304 | complete | pp | outcome | 104 | 0.7209 | 0.7467 |
| pp-outcome-grpo-s105-11ce62e5 | complete | pp | outcome | 105 | 0.7225 | 0.7583 |
| pp-outcome-grpo-s106-219fbd52 | complete | pp | outcome | 106 | 0.7112 | 0.7183 |
| pp-outcome-grpo-s107-ed22ccbf | complete | pp | outcome | 107 | 0.7201 | 0.7567 |
| pp-outcome-grpo-s108-efa738e8 | complete | pp | outcome | 108 | 0.7255 | 0.7533 |
| pp-outcome-grpo-s109-fa2d54aa | complete | pp | outcome | 109 | 0.7252 | 0.7617 |
| pp-outcome-grpo-s110-44898b43 | complete | pp | outcome | 110 | 0.7284 | 0.7467 |
| pp-outcome-grpo-s111-a2cba09b | complete | pp | outcome | 111 | 0.7282 | 0.7700 |
| pp-outcome-grpo-s112-aefbe702 | complete | pp | outcome | 112 | 0.7161 | 0.7567 |
| pp-outcome-grpo-s113-9d26a577 | complete | pp | outcome | 113 | 0.7194 | 0.7417 |
| pp-outcome-grpo-s114-d6a60f0b | complete | pp | outcome | 114 | 0.7263 | 0.7550 |
| pp-outcome-grpo-s115-426975d0 | complete | pp | outcome | 115 | 0.7209 | 0.7433 |
| pt-outcome-grpo-s100-199421d1 | complete | pt | outcome | 100 | 0.7230 | 0.7367 |
| pt-outcome-grpo-s101-ac44d1d9 | complete | pt | outcome | 101 | 0.7242 | 0.7550 |
| pt-outcome-grpo-s102-a1d1486f | complete | pt | outcome | 102 | 0.7148 | 0.7583 |
| pt-outcome-grpo-s103-cef1ca8d | complete | pt | outcome | 103 | 0.7221 | 0.7750 |
| pt-outcome-grpo-s104-efde5497 | complete | pt | outcome | 104 | 0.7226 | 0.7567 |
| pt-outcome-grpo-s105-0db29609 | complete | pt | outcome | 105 | 0.7151 | 0.7500 |
| pt-outcome-grpo-s106-e42d1c3d | complete | pt | outcome | 106 | 0.7234 | 0.7600 |
| pt-outcome-grpo-s107-e68ff554 | complete | pt | outcome | 107 | 0.7278 | 0.7700 |
| r-outcome-grpo-s100-a108ef90 | complete | r | outcome | 100 | 0.7064 | 0.7167 |
| r-outcome-grpo-s101-5c793f28 | complete | r | outcome | 101 | 0.7118 | 0.7433 |
| r-outcome-grpo-s102-53ad9011 | complete | r | outcome | 102 | 0.7020 | 0.7033 |
| r-outcome-grpo-s103-7b338eea | complete | r | outcome | 103 | 0.7081 | 0.7350 |
| r-outcome-grpo-s104-3d6fdc07 | complete | r | outcome | 104 | 0.7131 | 0.7150 |
| r-outcome-grpo-s105-dd738def | complete | r | outcome | 105 | 0.7094 | 0.7250 |
| r-outcome-grpo-s106-2601bfc7 | complete | r | outcome | 106 | 0.7109 | 0.7233 |
| r-outcome-grpo-s107-288bb017 | complete | r | outcome | 107 | 0.7071 | 0.7450 |
| r-outcome-grpo-s108-85bbcc58 | complete | r | outcome | 108 | 0.7073 | 0.7317 |
| r-outcome-grpo-s109-0c86ad19 | complete | r | outcome | 109 | 0.7030 | 0.7133 |
| r-outcome-grpo-s110-be0e00e6 | complete | r | outcome | 110 | 0.7131 | 0.7417 |
| r-outcome-grpo-s111-9907e82d | complete | r | outcome | 111 | 0.7144 | 0.7350 |
| r-outcome-grpo-s112-08fb8adb | complete | r | outcome | 112 | 0.7085 | 0.7450 |
| r-outcome-grpo-s113-f1f88f3b | complete | r | outcome | 113 | 0.7015 | 0.7383 |
| r-outcome-grpo-s114-b91bdc69 | complete | r | outcome | 114 | 0.7114 | 0.7433 |
| r-outcome-grpo-s115-78deeb36 | complete | r | outcome | 115 | 0.7171 | 0.7450 |

## Family S

| contrast | vs | pairs | Δ | 95% CI (pct) | BCa | p | p (Holm) | targeting ratio |
|---|---|---|---|---|---|---|---|---|
| pp | r | 16 | 0.0191 | [0.0103, 0.0285] | [0.0106, 0.0290] | 0.000 | 0.000 | 0.6667 |
| pt | r | 8 | 0.0319 | [0.0227, 0.0408] | [0.0231, 0.0412] | 0.000 | 0.000 | — |
|  ↳ unpaired: r-outcome-grpo-s108-85bbcc58, r-outcome-grpo-s109-0c86ad19, r-outcome-grpo-s110-be0e00e6, r-outcome-grpo-s111-9907e82d, r-outcome-grpo-s112-08fb8adb, r-outcome-grpo-s113-f1f88f3b, r-outcome-grpo-s114-b91bdc69, r-outcome-grpo-s115-78deeb36; incomplete: — |||||||||
