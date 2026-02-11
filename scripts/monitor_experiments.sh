#!/bin/bash
# 监控两个实验（MiniF2F、PutnamBench）的推理与编译进度
# 用法: bash scripts/monitor_experiments.sh

cd "$(dirname "$0")/.."
RESULTS_DIR="${RESULTS_DIR:-results}"
PROJECT_ROOT=$(pwd)

echo "═══════════════════════════════════════════════════════════"
echo "  实验进度监控 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 根据进程列出当前正在运行的 run（推理用 GPU、编译用 CPU）
running_inference_runs=""
running_compile_runs=""
while read -r line; do
    if echo "$line" | grep -q "inference.py.*--output_dir"; then
        run_dir=$(echo "$line" | grep -oP '\-\-output_dir\s+\S+' | awk '{print $2}')
        [ -n "$run_dir" ] && running_inference_runs="$running_inference_runs $run_dir"
    fi
    if echo "$line" | grep -q "compile.py.*--input_path"; then
        path=$(echo "$line" | grep -oP '\-\-input_path\s+\S+' | awk '{print $2}')
        [ -n "$path" ] && run_dir=$(dirname "$path")
        [ -n "$run_dir" ] && running_compile_runs="$running_compile_runs $run_dir"
    fi
done < <(ps aux 2>/dev/null | grep -E "inference\.py|compile\.py" | grep -v grep)

# 去重并显示
running_inference_runs=$(echo $running_inference_runs | tr ' ' '\n' | sort -u)
running_compile_runs=$(echo $running_compile_runs | tr ' ' '\n' | sort -u)
if [ -n "$running_inference_runs" ] || [ -n "$running_compile_runs" ]; then
    echo "【当前运行中】"
    for r in $running_inference_runs; do
        [ -d "$r" ] && echo "  推理: $r"
    done
    for r in $running_compile_runs; do
        [ -d "$r" ] && echo "  编译: $r"
    done
    echo ""
fi

# 检测实验目录：按 to_inference_codes 条数区分 MiniF2F(7808) / PutnamBench(21504)
detect_run() {
    local total=$1
    if [ "$total" -eq 7808 ] 2>/dev/null; then echo "minif2f"; return; fi
    if [ "$total" -eq 21504 ] 2>/dev/null; then echo "putnam"; return; fi
    echo ""
}

show_inference_progress() {
    local run_dir=$1
    local total=$2
    # 若该 run 已生成完整编译结果，则推理一定已完成（先推理后编译）
    if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
        if [ -f "$run_dir/code_compilation_repl.json" ]; then
            local count=0
            count=$(python3 -c "
import json
try:
    with open('$run_dir/code_compilation_repl.json') as f:
        print(len(json.load(f)))
except Exception: print(0)
" 2>/dev/null) || count=0
            if [ "${count:-0}" -eq "$total" ] 2>/dev/null; then
                echo "  推理: 已完成"
                return
            fi
        fi
    fi
    local log="$run_dir/inference.log"
    if [ ! -f "$log" ]; then
        echo "  （无 inference.log）"
        return
    fi
    if grep -q "Script finished\|Processing Chunks.*100%" "$log" 2>/dev/null; then
        echo "  推理: 已完成"
        return
    fi
    local last_line
    last_line=$(grep -E "Processed prompts:" "$log" 2>/dev/null | tail -1)
    if [ -n "$last_line" ]; then
        if echo "$last_line" | grep -q "100%"; then
            local total
            total=$(echo "$last_line" | grep -oP '\d+/\d+' | tail -1)
            echo "  推理: 已完成 $total"
        else
            local pct current total remaining eta
            pct=$(echo "$last_line" | grep -oP '\d+%' | head -1)
            current=$(echo "$last_line" | grep -oP '\d+/\d+' | tail -1 | cut -d'/' -f1)
            total=$(echo "$last_line" | grep -oP '\d+/\d+' | tail -1 | cut -d'/' -f2)
            remaining=$((total - current))
            eta=$(echo "$last_line" | grep -oP '\[[\d:]+<[\d:]+' | tail -1)
            echo "  推理: $current/$total ($pct) | 剩余 $remaining | $eta"
        fi
    else
        if grep -q "Preparing data" "$log" 2>/dev/null; then
            echo "  推理: 准备中或刚启动"
        else
            echo "  推理: 进行中（暂无进度条）"
        fi
    fi
}

show_compile_progress() {
    local run_dir=$1
    local total=$2
    if [ -f "$run_dir/code_compilation_repl.json" ]; then
        local count=0
        count=$(python3 -c "
import json
try:
    with open('$run_dir/code_compilation_repl.json') as f:
        print(len(json.load(f)))
except Exception: print(0)
" 2>/dev/null) || count=0
        if [ "${count:-0}" -eq "$total" ] 2>/dev/null; then
            local passed=0
            passed=$(python3 -c "
import json
try:
    with open('$run_dir/code_compilation_repl.json') as f:
        d=json.load(f)
    print(sum(1 for x in d if x.get('compilation_result',{}).get('pass',False)))
except Exception: print(0)
" 2>/dev/null) || passed=0
            pct_rate=$((passed * 100 / total))
            echo "  编译: 已完成 | 通过 $passed/$total (${pct_rate}%)"
        else
            echo "  编译: 已生成 $count/$total（可能未写完）"
        fi
    else
        local clog
        for clog in "$run_dir/compile_rerun2.log" "$run_dir/compile_rerun.log" "$run_dir/compile.log"; do
            if [ -f "$clog" ]; then
                local prog
                prog=$(grep -oP "Progress: \d+/$total" "$clog" 2>/dev/null | tail -1)
                if [ -n "$prog" ]; then
                    local current
                    current=$(echo "$prog" | grep -oP '\d+' | head -1)
                    local pct=$((current * 100 / total))
                    echo "  编译: $prog (${pct}%)"
                else
                    if grep -q "编译完成\|All proofs processed" "$clog" 2>/dev/null; then
                        echo "  编译: 已完成（等待结果文件写入）"
                    else
                        echo "  编译: 进行中（见 $(basename "$clog")）"
                    fi
                fi
                return
            fi
        done
        echo "  编译: 未开始或无日志"
    fi
}

# 遍历所有 run_* 目录（含仅有 inference.log 尚未生成 to_inference_codes 的 run）
for run_dir in "$RESULTS_DIR"/run_*; do
    [ -d "$run_dir" ] || continue
    run_name=$(basename "$run_dir")
    to_inference="$run_dir/to_inference_codes.json"
    total=0
    if [ -f "$to_inference" ]; then
        total=$(python3 -c "
import json
try:
    with open('$to_inference') as f:
        print(len(json.load(f)))
except Exception: print(0)
" 2>/dev/null) || total=0
    else
        # 推理进行中、尚未写入 to_inference_codes：从 inference.log 推断总数
        if [ -f "$run_dir/inference.log" ]; then
            total=$(grep -oP "Total items for LLM: \K\d+" "$run_dir/inference.log" 2>/dev/null | head -1)
            [ -z "$total" ] && total=$(grep -oP "\d+/\d+" "$run_dir/inference.log" 2>/dev/null | tail -1 | cut -d'/' -f2)
        fi
    fi
    kind=$(detect_run "$total")
    # 仅有 inference.log 且进程在跑：按 log 里 7808 判定为 MiniF2F
    if [ -z "$kind" ] && [ -f "$run_dir/inference.log" ]; then
        if grep -q "7808\|minif2f" "$run_dir/inference.log" 2>/dev/null; then
            kind="minif2f"
            total=7808
        elif grep -q "21504\|putnam" "$run_dir/inference.log" 2>/dev/null; then
            kind="putnam"
            total=21504
        fi
    fi
    case "$kind" in
        minif2f)  label="【实验: MiniF2F】" ;;
        putnam)   label="【实验: PutnamBench】" ;;
        *)        [ -z "$total" ] && total=0; label="【其他: $run_name】" ;;
    esac
    # 无 to_inference 且无法从 log 推断 kind 的 run 跳过
    if [ -z "$kind" ] && [ ! -f "$to_inference" ]; then
        continue
    fi
    echo "$label"
    echo "  目录: $run_dir"
    show_inference_progress "$run_dir" "$total"
    show_compile_progress "$run_dir" "$total"
    # 进程简要
    inf_pid=$(cat "$run_dir/inference.pid" 2>/dev/null)
    comp_pid=$(cat "$run_dir/compile.pid" 2>/dev/null)
    if [ -n "$inf_pid" ] && ps -p "$inf_pid" -o pid= >/dev/null 2>&1; then
        echo "  推理进程: 运行中 (PID $inf_pid)"
    fi
    if [ -n "$comp_pid" ] && ps -p "$comp_pid" -o pid= >/dev/null 2>&1; then
        echo "  编译进程: 运行中 (PID $comp_pid)"
    fi
    echo ""
done

echo "───────────────────────────────────────────────────────────"
echo "  资源"
echo "───────────────────────────────────────────────────────────"
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "  GPU:"
    nvidia-smi --query-gpu=index,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | \
        awk -F', ' '{printf "    GPU %s: %s%% 显存 %s/%s MB\n", $1, $2, $3, $4}'
fi
echo "═══════════════════════════════════════════════════════════"
