#!/bin/bash
# 实验结果分析脚本
# 功能：计算Pass@32结果并生成报告

set -e

PROJECT_DIR="/home/ningmiao/MingzhiZHANG/Goedel-Prover-V2"
cd "$PROJECT_DIR"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

# 分析实验1: MiniF2F
analyze_minif2f() {
    print_header "分析实验1: MiniF2F"
    
    MINIF2F_RUN=$(ls -td results/run_20260205_* 2>/dev/null | head -1)
    
    if [ -z "$MINIF2F_RUN" ]; then
        echo -e "${YELLOW}未找到MiniF2F实验目录${NC}"
        return
    fi
    
    echo "实验目录: $MINIF2F_RUN"
    
    if [ -f "$MINIF2F_RUN/pass_at_32_summary.txt" ]; then
        echo -e "${GREEN}✅ Pass@32结果已存在${NC}"
        cat "$MINIF2F_RUN/pass_at_32_summary.txt"
    elif [ -f "$MINIF2F_RUN/code_compilation_repl.json" ]; then
        echo -e "${YELLOW}开始计算Pass@32结果...${NC}"
        
        # 检查是否有计算脚本
        if [ -f "scripts/calculate_pass_at_k.py" ]; then
            python3 scripts/calculate_pass_at_k.py "$MINIF2F_RUN/code_compilation_repl.json" 32 \
                | tee "$MINIF2F_RUN/pass_at_32_summary.txt"
        else
            echo -e "${YELLOW}未找到计算脚本，请手动运行计算${NC}"
        fi
    else
        echo -e "${YELLOW}实验尚未完成编译阶段${NC}"
    fi
}

# 分析实验2: PutnamBench
analyze_putnambench() {
    print_header "分析实验2: PutnamBench"
    
    PUTNAM_RUN=$(ls -td results/run_20260206_* 2>/dev/null | head -1)
    
    if [ -z "$PUTNAM_RUN" ]; then
        echo -e "${YELLOW}未找到PutnamBench实验目录${NC}"
        return
    fi
    
    echo "实验目录: $PUTNAM_RUN"
    
    if [ -f "$PUTNAM_RUN/pass_at_32_summary.txt" ]; then
        echo -e "${GREEN}✅ Pass@32结果已存在${NC}"
        cat "$PUTNAM_RUN/pass_at_32_summary.txt"
    elif [ -f "$PUTNAM_RUN/code_compilation_repl.json" ]; then
        echo -e "${YELLOW}开始计算Pass@32结果...${NC}"
        
        # 检查是否有计算脚本
        if [ -f "scripts/calculate_pass_at_k.py" ]; then
            python3 scripts/calculate_pass_at_k.py "$PUTNAM_RUN/code_compilation_repl.json" 32 \
                | tee "$PUTNAM_RUN/pass_at_32_summary.txt"
        else
            echo -e "${YELLOW}未找到计算脚本，请手动运行计算${NC}"
        fi
    elif [ -f "$PUTNAM_RUN/to_inference_codes.json" ]; then
        echo -e "${YELLOW}推理已完成，等待编译完成...${NC}"
    else
        echo -e "${YELLOW}推理仍在进行中...${NC}"
        
        # 显示当前进度
        if [ -f "$PUTNAM_RUN/inference.log" ]; then
            python3 << PYEOF
import re
import os

log_file = "$PUTNAM_RUN/inference.log"
if os.path.exists(log_file):
    with open(log_file, 'r') as f:
        lines = f.readlines()
        for line in reversed(lines[-100:]):
            match = re.search(r'Processed prompts:\s+(\d+)%\|.*?\| (\d+)/(\d+)', line)
            if match:
                percent = match.group(1)
                current = int(match.group(2))
                total = int(match.group(3))
                print(f"当前进度: {current}/{total} ({percent}%)")
                break
PYEOF
        fi
    fi
}

# 主函数
main() {
    if [ "$1" = "minif2f" ]; then
        analyze_minif2f
    elif [ "$1" = "putnam" ]; then
        analyze_putnambench
    else
        analyze_minif2f
        echo ""
        analyze_putnambench
    fi
}

main "$@"
