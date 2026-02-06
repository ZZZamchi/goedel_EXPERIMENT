# 数据集说明

本项目支持以下数据集，所有数据集都已转换为统一的JSONL格式。

## 数据集列表

### 1. MiniF2F
- **文件**: `dataset/minif2f.jsonl`
- **问题数**: 244
- **描述**: 高中数学竞赛问题基准，包含 AMC、AIME 等竞赛题目
- **来源**: [miniF2F](https://github.com/roozbeh-yz/miniF2F_v2)
- **特点**: 包含选择题和证明题

### 2. MiniF2F-20
- **文件**: `dataset/minif2f_20.jsonl`
- **问题数**: 20
- **描述**: MiniF2F 的子集，用于快速测试

### 3. PutnamBench
- **文件**: `dataset/putnambench.jsonl`
- **问题数**: 672
- **描述**: Putnam 数学竞赛问题基准（1962-2025）
- **来源**: [PutnamBench](https://github.com/trishullab/PutnamBench)
- **特点**: 本科竞赛数学，难度较高

### 4. ProofNet
- **文件**: `dataset/proofnet.jsonl`
- **问题数**: 133
- **描述**: 本科数学自动形式化基准
- **来源**: [ProofNet](https://github.com/zhangir-azerbayev/proofnet)
- **特点**: 涵盖线性代数、实分析、抽象代数等

### 5. LeanCat
- **文件**: `dataset/leancat.jsonl`
- **问题数**: 152
- **描述**: 范畴论形式化基准
- **来源**: [LeanCat](https://github.com/sciencraft/LeanCat)
- **特点**: 研究级范畴论问题，测试抽象推理能力

### 6. FATE-H (High)
- **文件**: `dataset/fate_h.jsonl`
- **问题数**: 100
- **描述**: 形式化代数定理评估基准 - 高难度
- **来源**: [FATE](https://github.com/frenzymath/FATE)
- **特点**: 高级抽象代数和交换代数问题

### 7. FATE-M (Medium)
- **文件**: `dataset/fate_m.jsonl`
- **问题数**: 150
- **描述**: 形式化代数定理评估基准 - 中等难度
- **来源**: [FATE](https://github.com/frenzymath/FATE)
- **特点**: 中等难度的抽象代数问题

### 8. FATE-X (eXtreme)
- **文件**: `dataset/fate_x.jsonl`
- **问题数**: 109
- **描述**: 形式化代数定理评估基准 - 极高难度
- **来源**: [FATE](https://github.com/frenzymath/FATE)
- **特点**: 博士资格考试级别的抽象代数问题

## 数据集统计

| 数据集 | 问题数 | 难度 | 领域 |
|--------|--------|------|------|
| MiniF2F | 244 | 中等 | 高中数学竞赛 |
| MiniF2F-20 | 20 | 中等 | 高中数学竞赛 |
| PutnamBench | 672 | 高 | 本科竞赛数学 |
| ProofNet | 133 | 中等 | 本科数学 |
| LeanCat | 152 | 高 | 范畴论 |
| FATE-H | 100 | 高 | 抽象代数 |
| FATE-M | 150 | 中等 | 抽象代数 |
| FATE-X | 109 | 极高 | 抽象代数 |
| **总计** | **1,580** | - | - |

## 数据格式

所有数据集都使用统一的JSONL格式，每行一个JSON对象，包含以下字段：

```json
{
  "name": "问题名称",
  "problem_id": "唯一问题ID",
  "informal_prefix": "非形式化描述（可选）",
  "formal_statement": "形式化陈述",
  "lean4_code": "完整的Lean 4代码（包含import和theorem）",
  "split": "数据集划分（test/train/val）"
}
```

## 使用方法

### 查看可用数据集

```bash
source scripts/dataset_config.sh && list_datasets
```

### 运行实验

```bash
# 使用ProofNet数据集
bash scripts/run_dataset.sh proofnet --gpu 8 --cpu 450 --n 32

# 使用LeanCat数据集
bash scripts/run_dataset.sh leancat --gpu 8 --cpu 450 --n 32

# 使用FATE-H数据集
bash scripts/run_dataset.sh fate_h --gpu 8 --cpu 450 --n 32
```

## 添加新数据集

如果需要添加新的数据集，可以使用转换脚本：

```bash
# 转换Lean格式的数据集
python3 scripts/convert_lean_dataset.py <dataset_type> <source_dir> <output_path> [options]

# 示例：
python3 scripts/convert_lean_dataset.py leancat benchmarks/leancat dataset/leancat.jsonl
python3 scripts/convert_lean_dataset.py fate benchmarks/fate dataset/fate_h.jsonl --difficulty H
python3 scripts/convert_lean_dataset.py proofnet benchmarks/proofnet dataset/proofnet.jsonl
```

然后在 `scripts/dataset_config.sh` 中添加配置。

## 数据来源

所有数据集来自 [lean-benchmark](https://github.com/ZZZamchi/lean-benchmark) 项目，该项目收集了多个形式化数学基准数据集。

## 许可证

- MiniF2F: Apache-2.0
- PutnamBench: Apache-2.0 (Lean 4)
- ProofNet: MIT
- LeanCat: MIT
- FATE: MIT
