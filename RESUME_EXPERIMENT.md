# 恢复实验步骤指南

## 1. 重新连接服务器

```bash
# 方法1: 使用配置的别名（推荐）
ssh goedel-server

# 方法2: 直接连接
ssh ningmiao@144.214.210.13
```

## 2. 激活环境并进入项目目录

```bash
conda activate goedelv2
cd /home/ningmiao/MingzhiZHANG/Goedel-Prover-V2
```

## 3. 检查实验状态

### 3.1 查看当前实验进度
```bash
bash monitor_both_experiments.sh
```

### 3.2 检查进程状态
```bash
# 检查推理进程
ps aux | grep inference.py | grep -v grep

# 检查编译进程
ps aux | grep compile.py | grep -v grep

# 检查主进程
if [ -f pipeline.pid ]; then
    PID=$(cat pipeline.pid)
    ps -p $PID
fi
```

### 3.3 查看最新实验目录
```bash
LATEST_RUN=$(ls -td results/run_* 2>/dev/null | head -1)
echo "最新实验目录: $LATEST_RUN"
ls -lah "$LATEST_RUN"
```

## 4. 根据状态继续实验

### 情况A: 实验仍在运行
如果进程还在运行，实验会自动继续，无需操作。

**监控命令**:
```bash
# 实时查看进度（推荐）
bash monitor_both_experiments.sh

# 查看推理日志
tail -f results/run_*/inference.log

# 查看编译日志（如果有）
tail -f results/run_*/compile.log
```

### 情况B: 推理阶段已完成，需要继续编译
如果推理已完成但编译未开始：

```bash
# 找到最新的运行目录
LATEST_RUN=$(ls -td results/run_* 2>/dev/null | head -1)

# 检查是否有to_inference_codes.json
if [ -f "$LATEST_RUN/to_inference_codes.json" ]; then
    echo "开始编译..."
    python3 src/compile.py \
        --input_path "$LATEST_RUN/to_inference_codes.json" \
        --output_path "$LATEST_RUN/code_compilation_repl.json" \
        --cpu 128 \
        --timeout 300 2>&1 | tee "$LATEST_RUN/compile.log"
fi
```

### 情况C: 编译已完成，需要生成总结
如果编译已完成但总结未生成：

```bash
LATEST_RUN=$(ls -td results/run_* 2>/dev/null | head -1)

if [ -f "$LATEST_RUN/code_compilation_repl.json" ]; then
    echo "生成总结..."
    python3 src/summarize.py \
        --input_path "$LATEST_RUN/code_compilation_repl.json" \
        --full_record_path "$LATEST_RUN/full_records.json" \
        --output_dir "$LATEST_RUN/summary_round_0" 2>&1 | tee "$LATEST_RUN/summary.log"
fi
```

### 情况D: 实验已中断，需要重新启动
如果所有进程都已停止：

```bash
# 检查最新运行目录的状态
LATEST_RUN=$(ls -td results/run_* 2>/dev/null | head -1)

# 如果推理未完成，重新运行pipeline
bash scripts/pipeline.sh
```

## 5. 常用监控命令

```bash
# 查看实验进度（推荐）
bash monitor_both_experiments.sh

# 查看GPU使用情况
nvidia-smi

# 查看最新日志
tail -50 results/run_*/inference.log
tail -50 results/run_*/compile.log
```

## 7. 实验信息记录

**当前实验配置**:
- 数据集: dataset/minif2f.jsonl (244个问题)
- 样本数: 32个/问题
- GPU: 4个
- CPU: 128线程
- 编译超时: 300秒

**实验目录**: `results/run_20260205_085845/`

**重要文件**:
- 推理日志: `results/run_*/inference.log`
- 编译日志: `results/run_*/compile.log`

## 注意事项

1. **不要重复启动**: 检查进程状态后再决定是否需要重启
2. **保存PID文件**: 如果进程在运行，PID文件应该存在
3. **查看日志**: 日志文件会显示实验的详细进度
4. **VPN断开**: 如果VPN断开，进程会在服务器上继续运行，重新连接后检查状态即可
