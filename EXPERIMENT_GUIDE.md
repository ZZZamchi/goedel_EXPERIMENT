# Goedel-Prover-V2 实验管理指南

## 当前实验状态

### 实验1: MiniF2F
- ✅ **状态**: 编译已完成
- **Pass@32**: 91.80% (224/244问题通过)
- **结果目录**: `results/run_20260205_085845/`
- **结果文件**: 
  - `pass_at_32_results.json` (32K)
  - `pass_at_32_summary.txt`
  - `code_compilation_repl.json` (65M)

### 实验2: PutnamBench
- ⏳ **状态**: 推理进行中
- **当前进度**: ~6652/21504 (约31%)
- **预计完成时间**: 2026-02-09 00:44:16 (约1.8天后)
- **结果目录**: `results/run_20260206_025202/`
- **配置**: 
  - 8个GPU全部使用 (93-95%利用率)
  - 推理进程: 11个
  - 处理速度: 输入 ~33 toks/s, 输出 ~1550 toks/s
  - 平均速度: ~341 prompts/小时

## 可用工具

### 1. 实验管理工具
```bash
bash experiment_manager.sh
```
功能：
- 显示两个实验的详细状态
- 实时进度监控（包含进度条）
- GPU/CPU资源使用情况
- 预计完成时间计算

### 2. 增强监控脚本
```bash
bash monitor_enhanced.sh
```
功能：
- 实验状态概览
- 资源使用情况
- 进程监控

### 3. 结果分析工具
```bash
# 分析所有实验
bash analyze_results.sh

# 分析特定实验
bash analyze_results.sh minif2f
bash analyze_results.sh putnam

# 对比两个实验
bash analyze_results.sh compare
```

## 常用命令

### 监控实验
```bash
# 查看实验管理报告
bash experiment_manager.sh

# 查看推理日志（实时）
tail -f results/run_20260206_025202/inference.log

# 查看GPU状态
nvidia-smi

# 查看推理进程
ps aux | grep inference
```

### 检查实验状态
```bash
# 检查MiniF2F结果
ls -lh results/run_20260205_085845/

# 检查PutnamBench进度
ls -lh results/run_20260206_025202/
tail -20 results/run_20260206_025202/inference.log
```

### 实验恢复
```bash
# 恢复推理（如果中断）
bash resume_inference.sh

# 恢复整个实验流程
bash resume_experiments.sh
```

## 实验流程

### 阶段1: 推理 (Inference)
- 输入: `dataset/putnambench.jsonl`
- 输出: `results/run_YYYYMMDD_HHMMSS/to_inference_codes.json`
- 状态: 当前进行中

### 阶段2: 编译 (Compilation)
- 输入: `to_inference_codes.json`
- 输出: `code_compilation_repl.json`
- 状态: 等待推理完成

### 阶段3: 结果分析 (Analysis)
- 输入: `code_compilation_repl.json`
- 输出: `pass_at_32_results.json`, `pass_at_32_summary.txt`
- 状态: 等待编译完成

## 资源监控

### GPU状态
- 8个NVIDIA L40 GPU
- 当前利用率: 93-95%
- 显存使用: ~42.8GB / 46GB (93%)
- 温度: 59-63°C

### CPU状态
- 512核心
- 当前使用率: ~1.3%
- 推理进程: 11个

### 磁盘空间
- 总容量: 73TB
- 已使用: 15%
- 可用: 60TB

## 实验中断处理

### 📋 如果实验意外中断

如果推理进程因任何原因中断（如系统重启、进程崩溃等），可以使用以下方法恢复：

#### 1. 检查实验状态

运行状态检查脚本：

```bash
bash check_experiment_status.sh
```

**功能**：
- ✅ 记录当前推理进度
- ✅ 保存状态到 `results/run_*/experiment_status.txt`
- ✅ 检查是否有已保存的输出文件
- ✅ 检查推理进程状态

#### 2. 恢复实验

运行恢复脚本：

```bash
bash resume_inference.sh
```

**功能**：
- ✅ 自动检测实验状态
- ✅ 如果推理已完成，提示可以开始编译
- ✅ 如果推理未完成，检查已保存的结果
- ✅ 询问是否重新启动推理进程

### ⚠️ 重要说明

**当前推理脚本不支持断点续传**

这意味着：
1. **已保存的结果不会丢失** - 推理脚本在每个chunk处理完后会保存到 `full_records.json` 和 `to_inference_codes.json`
2. **未保存的当前chunk会丢失** - 如果进程在chunk处理中途中断
3. **重新启动会从头开始** - 但已保存的结果文件会被保留（不会被覆盖，因为推理脚本会追加）

### 💡 建议

1. **定期检查状态**使用 `bash check_experiment_status.sh` 记录进度
2. **如果中断**运行 `bash resume_inference.sh` 恢复推理
3. **定期监控**使用 `bash experiment_manager.sh` 查看进度

## 下一步工作

1. **监控PutnamBench推理进度**
   - 预计还需约1.8天完成
   - 定期检查日志确保正常运行

2. **推理完成后进行编译**
   - 自动或手动运行编译脚本
   - 监控编译进度

3. **计算PutnamBench的Pass@32结果**
   - 使用 `analyze_results.sh putnam`
   - 生成结果报告

4. **分析两个数据集的实验结果对比**
   - 使用 `analyze_results.sh compare`
   - 生成对比报告

## 注意事项

1. **不要中断推理进程**
   - 推理进程正在使用所有8个GPU
   - 中断会导致需要重新开始

2. **定期检查日志**
   - 确保没有错误
   - 监控进度是否正常

3. **磁盘空间充足**
   - 当前有60TB可用空间
   - 足够存储所有结果

4. **结果备份**
   - 重要结果已上传到GitHub
   - 建议定期备份新结果

## 故障排查

### 如果推理进程停止
```bash
# 检查进程状态
ps aux | grep inference

# 检查日志错误
tail -100 results/run_20260206_025202/inference.log | grep -i error

# 恢复推理
bash resume_inference.sh
```

### 如果GPU使用率异常
```bash
# 检查GPU状态
nvidia-smi

# 检查是否有其他进程占用GPU
fuser -v /dev/nvidia*

# 重启推理（谨慎操作）
bash resume_inference.sh
```

## 联系信息

- GitHub仓库: https://github.com/ZZZamchi/goedel_EXPERIMENT
- 项目位置: `/home/ningmiao/MingzhiZHANG/Goedel-Prover-V2`
