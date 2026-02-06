#!/bin/bash
# 监控编译进度

LATEST_RUN=$(ls -td results/run_* 2>/dev/null | head -1)

if [ -z "$LATEST_RUN" ]; then
    echo "❌ 未找到运行目录"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "  编译监控 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
echo "运行目录: $LATEST_RUN"
echo ""

# 检查编译进程
COMPILE_COUNT=$(ps aux | grep -E "compile.py.*$LATEST_RUN" | grep -v grep | wc -l)
if [ "$COMPILE_COUNT" -gt 0 ]; then
    echo "✅ 编译进程运行中 ($COMPILE_COUNT 个进程)"
else
    echo "ℹ️  编译进程未运行（可能已完成或未开始）"
fi

# 检查编译结果文件
if [ -f "$LATEST_RUN/code_compilation_repl.json" ]; then
    echo ""
    echo "【编译结果统计】"
    python3 << PYEOF
import json
try:
    with open('$LATEST_RUN/code_compilation_repl.json', 'r') as f:
        data = json.load(f)
    total = len(data)
    passed = sum(1 for x in data if x.get('compilation_result', {}).get('pass', False))
    failed = total - passed
    timeout_count = sum(1 for x in data 
                       if not x.get('compilation_result', {}).get('pass', False) 
                       and 'timeout' in str(x.get('compilation_result', {})).lower())
    
    print(f"  总证明数: {total}")
    print(f"  ✅ 通过: {passed} ({passed*100/total:.1f}%)")
    print(f"  ❌ 失败: {failed} ({failed*100/total:.1f}%)")
    if timeout_count > 0:
        print(f"  ⏱️  超时: {timeout_count} ({timeout_count*100/total:.1f}%)")
except Exception as e:
    print(f"  ⚠️  无法读取结果: {e}")
PYEOF
else
    echo "⏳ 编译结果文件尚未生成"
    
    # 检查编译日志
    if [ -f "$LATEST_RUN/compile.log" ]; then
        echo ""
        echo "【编译日志（最后5行）】"
        tail -5 "$LATEST_RUN/compile.log" | sed 's/^/  /'
        
        # 检查是否有超时或错误
        if grep -qi "timeout\|error\|exception" "$LATEST_RUN/compile.log" | tail -1; then
            echo ""
            echo "  ⚠️  检测到可能的错误或超时"
        fi
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
