#!/bin/bash
# 恢复中断的实验脚本

echo "═══════════════════════════════════════════════════════════"
echo "  恢复中断的实验 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 激活conda环境
source /opt/anaconda3/etc/profile.d/conda.sh
conda activate goedelv2

# 配置 - 使用所有可用资源
# 检测系统资源
TOTAL_CPUS=$(nproc)
TOTAL_GPUS=$(nvidia-smi --list-gpus | wc -l)

# 使用90%的CPU核心（留一些给系统），但不超过450
CPUS="${CPUS:-$((TOTAL_CPUS * 9 / 10))}"
if [ "$CPUS" -gt 450 ]; then
    CPUS=450
fi

# 使用所有GPU
GPUS="${GPUS:-$TOTAL_GPUS}"

COMPILE_TIMEOUT="${COMPILE_TIMEOUT:-300}"

echo "系统资源:"
echo "  CPU核心: $TOTAL_CPUS"
echo "  GPU数量: $TOTAL_GPUS"
echo "配置:"
echo "  使用CPU线程: $CPUS"
echo "  使用GPU数量: $GPUS"
echo ""

export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1

# 实验1: MiniF2F - 继续编译
MINIF2F_RUN="results/run_20260205_085845"
if [ -d "$MINIF2F_RUN" ] && [ -f "$MINIF2F_RUN/to_inference_codes.json" ] && [ ! -f "$MINIF2F_RUN/code_compilation_repl.json" ]; then
    echo "【实验1: MiniF2F】"
    echo "  目录: $MINIF2F_RUN"
    echo "  状态: 继续编译..."
    echo ""
    
    # 检查编译进度
    if [ -f "$MINIF2F_RUN/compile.log" ]; then
        LAST_PROGRESS=$(tail -50 "$MINIF2F_RUN/compile.log" | grep -oP "Progress: \K\d+" | tail -1)
        if [ -n "$LAST_PROGRESS" ]; then
            echo "  上次进度: $LAST_PROGRESS/7808"
        fi
    fi
    
    echo "  开始继续编译..."
    python3 src/compile.py \
        --input_path "$MINIF2F_RUN/to_inference_codes.json" \
        --output_path "$MINIF2F_RUN/code_compilation_repl.json" \
        --cpu "$CPUS" \
        --timeout "$COMPILE_TIMEOUT" 2>&1 | tee -a "$MINIF2F_RUN/compile.log" &
    
    MINIF2F_PID=$!
    echo "  编译进程PID: $MINIF2F_PID"
    echo "$MINIF2F_PID" > "$MINIF2F_RUN/compile.pid"
    echo ""
else
    if [ -f "$MINIF2F_RUN/code_compilation_repl.json" ]; then
        echo "【实验1: MiniF2F】"
        echo "  状态: ✓ 编译已完成"
        echo ""
    else
        echo "【实验1: MiniF2F】"
        echo "  状态: ⚠️  实验目录或输入文件不存在，跳过"
        echo ""
    fi
fi

# 实验2: PutnamBench - 重新启动推理
PUTNAM_RUN="results/run_20260206_025202"
if [ -d "$PUTNAM_RUN" ]; then
    echo "【实验2: PutnamBench】"
    echo "  目录: $PUTNAM_RUN"
    
    # 检查是否已完成推理
    if [ -f "$PUTNAM_RUN/to_inference_codes.json" ]; then
        echo "  状态: ✓ 推理已完成，准备编译..."
        echo ""
        
        if [ ! -f "$PUTNAM_RUN/code_compilation_repl.json" ]; then
            echo "  开始编译..."
            python3 src/compile.py \
                --input_path "$PUTNAM_RUN/to_inference_codes.json" \
                --output_path "$PUTNAM_RUN/code_compilation_repl.json" \
                --cpu "$CPUS" \
                --timeout "$COMPILE_TIMEOUT" 2>&1 | tee "$PUTNAM_RUN/compile.log" &
            
            PUTNAM_COMPILE_PID=$!
            echo "  编译进程PID: $PUTNAM_COMPILE_PID"
            echo "$PUTNAM_COMPILE_PID" > "$PUTNAM_RUN/compile.pid"
        else
            echo "  状态: ✓ 编译已完成"
        fi
    else
        echo "  状态: 重新启动推理..."
        echo ""
        
        # 重新运行推理
        python3 src/inference.py \
            --input_path "dataset/putnambench.jsonl" \
            --model_path "./model_8B/" \
            --output_dir "$PUTNAM_RUN" \
            --n 32 \
            --gpu "$GPUS" \
            --inference_handler "dpskcot" \
            --trunck 1 \
            --max_model_len 40960 \
            --temp 1.0 \
            --correction_round 0 2>&1 | tee -a "$PUTNAM_RUN/inference.log" &
        
        PUTNAM_INFERENCE_PID=$!
        echo "  推理进程PID: $PUTNAM_INFERENCE_PID"
        echo "$PUTNAM_INFERENCE_PID" > "$PUTNAM_RUN/inference.pid"
    fi
    echo ""
else
    echo "【实验2: PutnamBench】"
    echo "  状态: ⚠️  实验目录不存在，跳过"
    echo ""
fi

echo "═══════════════════════════════════════════════════════════"
echo "  实验恢复完成"
echo "  使用 'bash monitor_both_experiments.sh' 监控进度"
echo "═══════════════════════════════════════════════════════════"
