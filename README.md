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
# 实验管理工具（推荐）
bash experiment_manager.sh

# 详细监控报告
bash monitor_enhanced.sh

# 结果分析
bash analyze_results.sh
```

## 项目结构

```
Goedel-Prover-V2/
├── assets/              # 资源文件
├── dataset/             # 数据集文件
│   ├── minif2f.jsonl
│   └── putnambench.jsonl
├── lean_compiler/       # Lean编译器相关代码
├── mathlib4/            # Mathlib4依赖（git submodule）
├── model_8B/            # 模型文件（不纳入git）
├── results/             # 实验结果目录
│   ├── run_YYYYMMDD_HHMMSS/  # 每次实验的结果
│   │   ├── full_records.json
│   │   ├── to_inference_codes.json
│   │   ├── code_compilation_repl.json
│   │   ├── pass_at_32_results.json
│   │   └── inference.log, compile.log
├── scripts/             # 核心脚本目录
│   ├── pipeline.sh      # 主实验流程脚本
│   ├── run_dataset.sh   # 便捷运行脚本
│   ├── dataset_config.sh # 数据集配置
│   └── monitor_compile.sh # 编译监控
├── src/                 # 源代码
│   ├── inference.py     # 推理生成证明
│   ├── compile.py       # 编译验证代码
│   ├── summarize.py     # 结果汇总
│   └── utils.py         # 工具函数
├── experiment_manager.sh    # 实验管理工具
├── analyze_results.sh        # 结果分析工具
├── monitor_enhanced.sh       # 详细监控脚本
├── resume_experiments.sh     # 通用实验恢复脚本
├── resume_inference.sh       # 推理恢复脚本
├── check_experiment_status.sh  # 实验状态检查
├── cleanup.sh               # 项目清理脚本
├── README.md            # 项目说明（本文件）
├── EXPERIMENT_GUIDE.md  # 实验管理指南
├── DATASET_GUIDE.md     # 数据集使用指南
├── DATASETS.md          # 数据集说明
└── goedelv2.yml        # Conda环境配置
```

## 脚本使用指南

### 📊 监控脚本

#### `experiment_manager.sh` - 实验管理工具（推荐）
**功能**: 显示两个实验的详细状态、进度、资源使用情况

```bash
bash experiment_manager.sh
```

**显示内容**:
- MiniF2F实验状态和Pass@32结果
- PutnamBench推理进度、剩余时间、预计完成时间
- GPU和CPU使用情况（带颜色标识）
- 进度条可视化

#### `monitor_enhanced.sh` - 详细监控报告
**功能**: 显示实验状态和资源使用情况

```bash
bash monitor_enhanced.sh
```

#### `analyze_results.sh` - 结果分析工具
**功能**: 分析实验结果并计算Pass@32

```bash
# 分析所有实验
bash analyze_results.sh

# 分析特定实验
bash analyze_results.sh minif2f
bash analyze_results.sh putnam

# 对比两个实验
bash analyze_results.sh compare
```

### 🔄 恢复脚本

#### `resume_inference.sh` - 推理恢复脚本
**功能**: 恢复PutnamBench推理进程

```bash
bash resume_inference.sh
```

**使用场景**: 实验意外中断后恢复推理

#### `resume_experiments.sh` - 通用实验恢复脚本
**功能**: 恢复中断的实验（包括推理和编译）

```bash
bash resume_experiments.sh
```

**使用场景**: 实验意外中断后的全面恢复

### 🛡️ 工具脚本

#### `check_experiment_status.sh` - 实验状态检查
**功能**: 记录当前实验状态

```bash
bash check_experiment_status.sh
```

**使用场景**: 定期检查或实验中断前记录状态

**保存信息**:
- 当前推理进度
- 状态文件: `results/run_*/experiment_status.txt`

#### `cleanup.sh` - 项目清理脚本
**功能**: 清理临时文件、日志、缓存等

```bash
# 清理所有
bash cleanup.sh --all

# 只清理缓存
bash cleanup.sh --cache

# 只清理日志
bash cleanup.sh --logs

# 清理旧的实验结果（保留最近2个）
bash cleanup.sh --old-results
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
   - 输入: `dataset/*.jsonl`
   - 输出: `results/run_*/to_inference_codes.json`
   - 日志: `results/run_*/inference.log`

2. **编译阶段**: 验证生成的代码能否编译通过
   - 输入: `to_inference_codes.json`
   - 输出: `code_compilation_repl.json`
   - 日志: `results/run_*/compile.log`

3. **结果分析**: 统计实验结果
   - 输入: `code_compilation_repl.json`
   - 输出: `pass_at_32_results.json`, `pass_at_32_summary.txt`

结果保存在 `results/run_YYYYMMDD_HHMMSS/` 目录。

## 重要文件说明

### 源代码
- `src/inference.py`: 使用LLM生成Lean 4证明代码
- `src/compile.py`: 验证生成的代码能否编译通过
- `src/summarize.py`: 汇总实验结果

### 配置文件
- `goedelv2.yml`: Conda环境配置
- `lean-toolchain`: Lean版本
- `lakefile.lean`: Lean项目配置

### 实验结果
- `results/run_*/full_records.json`: 完整记录
- `results/run_*/to_inference_codes.json`: 待编译的代码
- `results/run_*/code_compilation_repl.json`: 编译结果
- `results/run_*/pass_at_32_results.json`: Pass@32详细结果
- `results/run_*/pass_at_32_summary.txt`: Pass@32总结

## 注意事项

1. **模型文件**: `model_8B/` 目录很大，不纳入git管理
2. **实验结果**: 只保留最近的实验结果，旧的会被清理脚本删除
3. **日志文件**: 根目录的临时日志会被清理，但`results/`下的实验日志会保留
4. **Python缓存**: `__pycache__`目录会被自动清理

## 资源使用建议

- **GPU**: 建议使用全部8个GPU以获得最佳性能
- **CPU**: 建议使用450个线程（512核心的88%）
- **内存**: 确保有足够内存（建议>1TB）

## 相关文档

- [EXPERIMENT_GUIDE.md](EXPERIMENT_GUIDE.md) - 实验管理指南（包含当前实验状态和详细操作说明）
- [DATASET_GUIDE.md](DATASET_GUIDE.md) - 数据集使用指南
- [DATASETS.md](DATASETS.md) - 数据集说明

## 联系信息

- GitHub仓库: https://github.com/ZZZamchi/goedel_EXPERIMENT
- 项目位置: `/home/ningmiao/MingzhiZHANG/Goedel-Prover-V2`
