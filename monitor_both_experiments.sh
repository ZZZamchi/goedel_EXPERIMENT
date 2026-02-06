#!/bin/bash
# 监控两个并行实验的脚本

echo "═══════════════════════════════════════════════════════════"
echo "  并行实验监控 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
echo ""

# minif2f实验
echo "【实验1: MiniF2F】"
MINIF2F_RUN=$(ls -td results/run_20260205_* 2>/dev/null | head -1)
if [ -n "$MINIF2F_RUN" ]; then
    echo "  目录: $MINIF2F_RUN"
    if [ -f "$MINIF2F_RUN/code_compilation_repl.json" ]; then
        echo "  状态: ✓ 编译已完成"
    elif [ -f "$MINIF2F_RUN/to_inference_codes.json" ]; then
        COMPILE_PROGRESS=$(tail -20 "$MINIF2F_RUN/compile.log" 2>/dev/null | grep -oP "Progress: \K\d+" | tail -1)
        if [ -n "$COMPILE_PROGRESS" ]; then
            echo "  状态: ⏳ 编译进行中 ($COMPILE_PROGRESS/7808)"
        else
            echo "  状态: ⏳ 编译阶段"
        fi
    else
        echo "  状态: ⏳ 推理进行中"
    fi
    COMPILE_COUNT=$(ps aux | grep "compile.py" | grep "$MINIF2F_RUN" | grep -v grep | wc -l)
    echo "  编译进程: $COMPILE_COUNT 个"
else
    echo "  状态: 未找到实验目录"
fi
echo ""

# PutnamBench实验
echo "【实验2: PutnamBench】"
PUTNAM_RUN=$(ls -td results/run_20260206_* 2>/dev/null | head -1)
if [ -n "$PUTNAM_RUN" ]; then
    echo "  目录: $PUTNAM_RUN"
    if [ -f "$PUTNAM_RUN/code_compilation_repl.json" ]; then
        echo "  状态: ✓ 编译已完成"
    elif [ -f "$PUTNAM_RUN/to_inference_codes.json" ]; then
        echo "  状态: ⏳ 推理完成，编译阶段"
    else
        INFERENCE_COUNT=$(ps aux | grep "inference.py" | grep -v grep | wc -l)
        echo "  状态: ⏳ 推理进行中"
        echo "  推理进程: $INFERENCE_COUNT 个"
    fi
else
    echo "  状态: 未找到实验目录"
fi
echo ""

# 资源使用
echo "【资源使用情况】"
echo "  GPU使用:"
nvidia-smi --query-gpu=index,utilization.gpu,memory.used --format=csv,noheader,nounits | \
    awk -F', ' '{printf "    GPU %s: %s%% 使用, 显存 %s MB\n", $1, $2, $3}'
echo ""
echo "  CPU使用:"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "    CPU使用率: ${CPU_USAGE}%"
INFERENCE_COUNT=$(ps aux | grep "inference.py" | grep -v grep | wc -l)
COMPILE_COUNT=$(ps aux | grep "compile.py" | grep -v grep | wc -l)
echo "    推理进程: $INFERENCE_COUNT 个"
echo "    编译进程: $COMPILE_COUNT 个"
echo ""

echo "═══════════════════════════════════════════════════════════"
