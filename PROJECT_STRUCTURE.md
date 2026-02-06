# 项目结构说明

## 目录结构

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
│   │   └── inference.log, compile.log, summary.log
├── scripts/             # 脚本文件
│   ├── pipeline.sh      # 主实验流程脚本
│   ├── run_dataset.sh   # 便捷运行脚本
│   └── dataset_config.sh # 数据集配置
├── src/                 # 源代码
│   ├── inference.py     # 推理生成证明
│   ├── compile.py        # 编译验证代码
│   ├── summarize.py     # 结果汇总
│   └── utils.py         # 工具函数
├── cleanup.sh           # 项目清理脚本
├── monitor_both_experiments.sh  # 实验监控脚本
├── resume_experiments.sh        # 恢复实验脚本
├── README.md            # 项目说明
└── goedelv2.yml        # Conda环境配置

```

## 主要脚本说明

### 运行实验
```bash
# 使用便捷脚本运行
bash scripts/run_dataset.sh minif2f --gpu 8 --cpu 450 --n 32

# 或使用pipeline脚本
export DATA_PATH="dataset/minif2f.jsonl"
export GPUS=8
export CPUS=450
bash scripts/pipeline.sh
```

### 监控实验
```bash
# 监控并行实验（推荐）
bash monitor_both_experiments.sh
```

### 恢复中断的实验
```bash
# 自动恢复中断的实验
bash resume_experiments.sh
```

### 清理项目
```bash
# 清理缓存和临时文件
bash cleanup.sh

# 清理所有（包括旧实验结果）
bash cleanup.sh --all

# 只清理缓存
bash cleanup.sh --cache

# 只清理日志
bash cleanup.sh --logs

# 只清理旧实验结果
bash cleanup.sh --old-results
```

## 文件说明

### 重要文件
- `src/inference.py`: 使用LLM生成Lean 4证明代码
- `src/compile.py`: 验证生成的代码能否编译通过
- `src/summarize.py`: 汇总实验结果
- `scripts/pipeline.sh`: 完整的实验流程（推理→编译→汇总）

### 配置文件
- `goedelv2.yml`: Conda环境配置
- `lean-toolchain`: Lean版本
- `lakefile.lean`: Lean项目配置

### 实验结果
- `results/run_*/full_records.json`: 完整记录
- `results/run_*/to_inference_codes.json`: 待编译的代码
- `results/run_*/code_compilation_repl.json`: 编译结果

## 注意事项

1. **模型文件**: `model_8B/` 目录很大，不纳入git管理
2. **实验结果**: 只保留最近的实验结果，旧的会被清理脚本删除
3. **日志文件**: 根目录的临时日志会被清理，但`results/`下的实验日志会保留
4. **Python缓存**: `__pycache__`目录会被自动清理

## 资源使用建议

- **GPU**: 建议使用全部8个GPU以获得最佳性能
- **CPU**: 建议使用450个线程（512核心的88%）
- **内存**: 确保有足够内存（建议>1TB）
