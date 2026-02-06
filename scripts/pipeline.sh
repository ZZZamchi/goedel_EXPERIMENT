#!/bin/bash

# Configuration
# 可以通过环境变量覆盖这些配置
DATA_PATH="${DATA_PATH:-dataset/minif2f.jsonl}"
MODEL_PATH="${MODEL_PATH:-./model_8B/}"
OUTPUT_BASE_DIR="${OUTPUT_BASE_DIR:-./results}"
GPUS="${GPUS:-4}"
CPUS="${CPUS:-128}"
NUM_SAMPLES_INITIAL="${NUM_SAMPLES_INITIAL:-32}"
MAX_CORRECTION_ROUNDS="${MAX_CORRECTION_ROUNDS:-0}"
INFERENCE_HANDLER="${INFERENCE_HANDLER:-dpskcot}"
COMPILE_TIMEOUT="${COMPILE_TIMEOUT:-300}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_DIR="${OUTPUT_BASE_DIR}/run_${TIMESTAMP}"
mkdir -p "${RUN_DIR}"

echo "Starting experiment at ${RUN_DIR}"
echo "Data: ${DATA_PATH}"
echo "Model: ${MODEL_PATH}"
echo "Samples per problem: ${NUM_SAMPLES_INITIAL}"
echo "GPUs: ${GPUS}, CPUs: ${CPUS}"

export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1

echo "Step 1: Running inference..."
python3 src/inference.py \
    --input_path "${DATA_PATH}" \
    --model_path "${MODEL_PATH}" \
    --output_dir "${RUN_DIR}" \
    --n "${NUM_SAMPLES_INITIAL}" \
    --gpu "${GPUS}" \
    --inference_handler "${INFERENCE_HANDLER}" \
    --trunck 1 \
    --max_model_len 40960 \
    --temp 1.0 \
    --correction_round 0 2>&1 | tee "${RUN_DIR}/inference.log"

echo "Step 2: Compiling generated code..."
python3 src/compile.py \
    --input_path "${RUN_DIR}/to_inference_codes.json" \
    --output_path "${RUN_DIR}/code_compilation_repl.json" \
    --cpu "${CPUS}" \
    --timeout "${COMPILE_TIMEOUT}" 2>&1 | tee "${RUN_DIR}/compile.log"

echo "Step 3: Generating summary..."
python3 src/summarize.py \
    --input_path "${RUN_DIR}/code_compilation_repl.json" \
    --full_record_path "${RUN_DIR}/full_records.json" \
    --output_dir "${RUN_DIR}/summary_round_0" 2>&1 | tee "${RUN_DIR}/summary.log"

echo "Experiment completed. Results in ${RUN_DIR}"
