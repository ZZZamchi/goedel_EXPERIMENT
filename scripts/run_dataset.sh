#!/bin/bash
# 便捷的数据集实验运行脚本
# 用法: bash scripts/run_dataset.sh <dataset_name> [--gpu N] [--cpu N] [--n N]

source scripts/dataset_config.sh

DATASET_NAME=$1
if [ -z "$DATASET_NAME" ]; then
    echo "用法: bash scripts/run_dataset.sh <dataset_name> [选项]"
    echo ""
    echo "选项:"
    echo "  --gpu N      GPU数量 (默认: 4)"
    echo "  --cpu N      CPU线程数 (默认: 128)"
    echo "  --n N        每个问题的样本数 (默认: 32)"
    echo "  --timeout N  编译超时秒数 (默认: 300)"
    echo ""
    list_datasets
    exit 1
fi

shift  # 移除数据集名称参数

# 解析参数
GPUS=4
CPUS=128
NUM_SAMPLES=32
TIMEOUT=300

while [[ $# -gt 0 ]]; do
    case $1 in
        --gpu)
            GPUS="$2"
            shift 2
            ;;
        --cpu)
            CPUS="$2"
            shift 2
            ;;
        --n)
            NUM_SAMPLES="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 检查数据集
if ! check_dataset "$DATASET_NAME"; then
    exit 1
fi

DATASET_PATH="${DATASET_PATHS[$DATASET_NAME]}"
DATASET_DISPLAY_NAME="${DATASET_NAMES[$DATASET_NAME]}"

# 运行实验
echo "═══════════════════════════════════════════════════════════"
echo "  实验配置"
echo "═══════════════════════════════════════════════════════════"
echo "数据集: $DATASET_DISPLAY_NAME ($DATASET_NAME)"
echo "数据路径: $DATASET_PATH"
echo "GPU数量: $GPUS"
echo "CPU线程: $CPUS"
echo "样本数/问题: $NUM_SAMPLES"
echo "编译超时: $TIMEOUT 秒"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 修改pipeline.sh的配置并运行
export DATA_PATH="$DATASET_PATH"
export GPUS="$GPUS"
export CPUS="$CPUS"
export NUM_SAMPLES_INITIAL="$NUM_SAMPLES"
export COMPILE_TIMEOUT="$TIMEOUT"

bash scripts/pipeline.sh
