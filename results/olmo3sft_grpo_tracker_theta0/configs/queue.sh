#!/usr/bin/env bash
# Start the θ0 = 1.0 PP runs once all eight KL-strength runs have finished.
cd /home/ubuntu/workspace/virtual-student
K=artifacts/olmo3sft_grpo_kl_strength
E=artifacts/olmo3sft_grpo_tracker_theta0
while true; do
  n=$(grep -l '"complete"\|"failed' $K/*-outcome-*/status.json 2>/dev/null | wc -l)
  [ "$n" -ge 8 ] && break; sleep 120
done
for p in 8100 8101 8102; do  # servers can die on the GPU while HTTP stays up
  curl -sf -m 60 127.0.0.1:$p/v1/completions -H 'Content-Type: application/json' \
    -d '{"model":"allenai/Olmo-3-7B-Instruct-SFT","prompt":"Hi","max_tokens":2,"temperature":0}' >/dev/null \
    || { echo "server $p unhealthy" >&2; exit 1; }
done
gpu=3
for s in 0 1 2 3; do
  CUDA_VISIBLE_DEVICES=$gpu PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    uv run --extra train virtual-student run execute $E/configs/pp_theta1_s$s.yaml > $E/configs/pp_theta1_s$s.log 2>&1 &
  gpu=$((gpu+1)); sleep 10
done
wait
