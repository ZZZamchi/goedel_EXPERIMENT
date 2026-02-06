# 新对话分析提示词

## 完整提示词

```
我正在分析Goedel-Prover-V2项目的MiniF2F实验结果。需要从GitHub下载相关文件并在本地进行分析。

**项目信息**:
- GitHub仓库: https://github.com/ZZZamchi/goedel_EXPERIMENT
- 本地目录: C:\Users\23761\Desktop\LEAN\goedel_experiment
- 实验名称: MiniF2F Pass@32

**实验结果**:
- Pass@32: 91.80% (224/244问题通过)
- 完全通过: 24个问题 (32/32样本通过)
- 部分通过: 200个问题 (1-31/32样本通过)
- 完全未通过: 20个问题 (0/32样本通过)
- 样本通过率: 62.54% (4883/7808样本)

**需要下载的文件** (在 results/run_20260205_085845/ 目录):
1. pass_at_32_results.json - Pass@32详细计算结果
2. pass_at_32_summary.txt - 结果摘要
3. code_compilation_repl.json (65MB, Git LFS) - 编译结果
4. full_records.json (175MB, Git LFS) - 完整推理记录
5. to_inference_codes.json (169MB, Git LFS) - 生成的代码

**分析目标**:
1. 从GitHub克隆项目到本地
2. 下载所有实验结果文件（包括Git LFS大文件）
3. 分析完全通过、部分通过和未通过的问题模式
4. 研究模型生成的代码质量
5. 识别成功和失败的模式

**技术说明**:
- 大文件使用Git LFS存储，需要先安装: git lfs install
- 本地环境: Windows, 目录 C:\Users\23761\Desktop\LEAN\goedel_experiment

请帮助我下载文件并开始分析工作。
```

## 简化版提示词

```
我需要分析Goedel-Prover-V2的MiniF2F实验结果。

**GitHub**: https://github.com/ZZZamchi/goedel_EXPERIMENT
**本地目录**: C:\Users\23761\Desktop\LEAN\goedel_experiment
**实验结果**: Pass@32 = 91.80% (224/244问题通过)

**需要下载**:
- 项目代码
- 实验结果文件 (results/run_20260205_085845/)
- 注意: 大文件使用Git LFS (需要先安装 git lfs install)

**分析目标**:
1. 下载所有文件
2. 分析通过/未通过的问题模式
3. 研究生成的代码质量

请帮助我完成下载和分析。
```

## 关键信息摘要

- **仓库**: https://github.com/ZZZamchi/goedel_EXPERIMENT
- **本地路径**: C:\Users\23761\Desktop\LEAN\goedel_experiment
- **实验目录**: results/run_20260205_085845/
- **Pass@32**: 91.80%
- **Git LFS**: 需要安装以下载大文件
