#!/bin/bash
# 数据集配置
# 用法: source scripts/dataset_config.sh && list_datasets

declare -A DATASET_PATHS
declare -A DATASET_NAMES
declare -A DATASET_SPLITS

DATASET_PATHS["minif2f"]="dataset/minif2f.jsonl"
DATASET_NAMES["minif2f"]="MiniF2F"
DATASET_SPLITS["minif2f"]="test"

DATASET_PATHS["minif2f_20"]="dataset/minif2f_20.jsonl"
DATASET_NAMES["minif2f_20"]="MiniF2F-20"
DATASET_SPLITS["minif2f_20"]="test"

DATASET_PATHS["putnambench"]="dataset/putnambench.jsonl"
DATASET_NAMES["putnambench"]="PutnamBench"
DATASET_SPLITS["putnambench"]="test"

DATASET_PATHS["proofnet"]="dataset/proofnet.jsonl"
DATASET_NAMES["proofnet"]="ProofNet"
DATASET_SPLITS["proofnet"]="test"

DATASET_PATHS["leancat"]="dataset/leancat.jsonl"
DATASET_NAMES["leancat"]="LeanCat"
DATASET_SPLITS["leancat"]="test"

DATASET_PATHS["fate_h"]="dataset/fate_h.jsonl"
DATASET_NAMES["fate_h"]="FATE-H"
DATASET_SPLITS["fate_h"]="test"

DATASET_PATHS["fate_m"]="dataset/fate_m.jsonl"
DATASET_NAMES["fate_m"]="FATE-M"
DATASET_SPLITS["fate_m"]="test"

DATASET_PATHS["fate_x"]="dataset/fate_x.jsonl"
DATASET_NAMES["fate_x"]="FATE-X"
DATASET_SPLITS["fate_x"]="test"

# 列出所有可用的数据集
list_datasets() {
    echo "可用的数据集:"
    for key in "${!DATASET_PATHS[@]}"; do
        echo "  - $key: ${DATASET_NAMES[$key]} (${DATASET_PATHS[$key]})"
    done
}

# 检查数据集是否存在
check_dataset() {
    local dataset_name=$1
    if [ -z "${DATASET_PATHS[$dataset_name]}" ]; then
        echo "❌ 错误: 数据集 '$dataset_name' 未配置"
        echo ""
        list_datasets
        return 1
    fi
    
    local dataset_path="${DATASET_PATHS[$dataset_name]}"
    if [ ! -f "$dataset_path" ]; then
        echo "⚠️  警告: 数据集文件不存在: $dataset_path"
        echo "请确保数据集文件已放置在正确位置"
        return 1
    fi
    
    echo "✅ 数据集检查通过: $dataset_name"
    echo "   路径: $dataset_path"
    echo "   名称: ${DATASET_NAMES[$dataset_name]}"
    return 0
}

# 运行实验
run_experiment() {
    local dataset_name=$1
    shift  # 移除第一个参数，保留其他参数
    
    if [ -z "$dataset_name" ]; then
        echo "用法: run_experiment <dataset_name> [其他参数...]"
        echo ""
        list_datasets
        return 1
    fi
    
    # 检查数据集
    if ! check_dataset "$dataset_name"; then
        return 1
    fi
    
    local dataset_path="${DATASET_PATHS[$dataset_name]}"
    local dataset_display_name="${DATASET_NAMES[$dataset_name]}"
    
    echo "═══════════════════════════════════════════════════════════"
    echo "  开始实验: $dataset_display_name"
    echo "═══════════════════════════════════════════════════════════"
    echo "数据集: $dataset_path"
    echo ""
    
    # 调用pipeline脚本，传递数据集路径和其他参数
    bash scripts/pipeline.sh --data_path "$dataset_path" "$@"
}
