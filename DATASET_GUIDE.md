# 数据集配置指南

## 当前可用数据集

- **minif2f**: MiniF2F数据集 (244个问题)
- **minif2f_20**: MiniF2F测试集 (20个问题)
- **mobench**: MOBench数据集 (360个问题)

查看所有数据集：
```bash
source scripts/dataset_config.sh && list_datasets
```

## 数据集格式

数据集必须是JSONL格式，每行一个JSON对象，包含：

**必需字段**:
- `name` (str): 问题名称
- `problem_id` (str): 问题ID
- `lean4_code` (str): Lean 4代码

**可选字段**:
- `informal_prefix`: 问题描述
- `formal_statement`: 形式化陈述
- `split`: 数据集划分

## 添加新数据集

### 步骤1: 准备数据文件
将JSONL文件放在 `dataset/` 目录：
```bash
cp your_dataset.jsonl dataset/
```

### 步骤2: 验证格式
```bash
python3 scripts/validate_dataset.py dataset/your_dataset.jsonl
```

### 步骤3: 添加到配置
编辑 `scripts/dataset_config.sh`，添加：
```bash
DATASET_PATHS["your_dataset"]="dataset/your_dataset.jsonl"
DATASET_NAMES["your_dataset"]="Your Dataset Name"
DATASET_SPLITS["your_dataset"]="test"
```

### 步骤4: 运行实验
```bash
bash scripts/run_dataset.sh your_dataset
```

## 运行实验

```bash
# 使用便捷脚本
bash scripts/run_dataset.sh minif2f --gpu 4 --cpu 128 --n 32

# 使用环境变量
export DATA_PATH="dataset/minif2f.jsonl"
bash scripts/pipeline.sh
```
