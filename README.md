# Goedel-Prover-V2

自动定理证明实验框架，使用大语言模型生成Lean 4证明。

## 快速开始

### 运行实验

```bash
# 使用默认配置
bash scripts/pipeline.sh

# 使用自定义数据集
export DATA_PATH="dataset/minif2f.jsonl"
export GPUS=4
export CPUS=128
bash scripts/pipeline.sh

# 使用便捷脚本
bash scripts/run_dataset.sh minif2f --gpu 4 --cpu 128 --n 32
```

### 查看可用数据集

```bash
source scripts/dataset_config.sh && list_datasets
```

### 监控实验

```bash
# 监控并行实验（推荐）
bash monitor_both_experiments.sh

# 或使用便捷脚本
bash scripts/run_dataset.sh minif2f --gpu 8 --cpu 450 --n 32
```

## 项目结构

```
Goedel-Prover-V2/
├── dataset/              # 数据集目录
├── model_8B/            # 模型文件
├── scripts/             # 脚本文件
│   ├── pipeline.sh      # 主实验流程
│   ├── dataset_config.sh # 数据集配置
│   └── run_dataset.sh   # 便捷运行脚本
├── src/                 # 源代码
│   ├── inference.py    # 推理生成证明
│   ├── compile.py      # 编译验证证明
│   └── summarize.py    # 结果总结
├── results/            # 实验结果
└── mathlib4/           # Lean数学库
```

## 数据集配置

数据集文件应为JSONL格式，每行包含：
- `name`: 问题名称
- `problem_id`: 问题ID
- `lean4_code`: Lean 4代码

添加新数据集：
1. 将文件放在 `dataset/` 目录
2. 运行验证：`python3 scripts/validate_dataset.py dataset/your_dataset.jsonl`
3. 编辑 `scripts/dataset_config.sh` 添加配置

详细说明见 `DATASET_GUIDE.md`

## 配置参数

可通过环境变量配置：
- `DATA_PATH`: 数据集路径
- `GPUS`: GPU数量
- `CPUS`: CPU线程数
- `NUM_SAMPLES_INITIAL`: 每个问题的样本数
- `COMPILE_TIMEOUT`: 编译超时（秒）

## 实验流程

1. **推理阶段**: 使用模型生成证明代码
2. **编译阶段**: 验证生成的代码能否编译通过
3. **总结阶段**: 统计实验结果

结果保存在 `results/run_YYYYMMDD_HHMMSS/` 目录。
