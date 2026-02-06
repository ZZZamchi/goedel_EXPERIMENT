#!/bin/bash
# 项目清理脚本
# 用法: bash cleanup.sh [选项]
# 选项:
#   --all: 清理所有（包括旧的实验结果）
#   --cache: 只清理缓存文件
#   --logs: 只清理日志文件
#   --old-results: 只清理旧的实验结果（保留最近2个）

set -e

CLEAN_ALL=false
CLEAN_CACHE=false
CLEAN_LOGS=false
CLEAN_OLD_RESULTS=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CLEAN_ALL=true
            shift
            ;;
        --cache)
            CLEAN_CACHE=true
            shift
            ;;
        --logs)
            CLEAN_LOGS=true
            shift
            ;;
        --old-results)
            CLEAN_OLD_RESULTS=true
            shift
            ;;
        *)
            echo "未知选项: $1"
            echo "用法: bash cleanup.sh [--all|--cache|--logs|--old-results]"
            exit 1
            ;;
    esac
done

# 如果没有指定选项，默认清理缓存和日志
if [ "$CLEAN_ALL" = false ] && [ "$CLEAN_CACHE" = false ] && [ "$CLEAN_LOGS" = false ] && [ "$CLEAN_OLD_RESULTS" = false ]; then
    CLEAN_CACHE=true
    CLEAN_LOGS=true
fi

echo "═══════════════════════════════════════════════════════════"
echo "  项目清理脚本"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 清理Python缓存
if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_CACHE" = true ]; then
    echo "清理Python缓存文件..."
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    echo "  ✓ Python缓存已清理"
fi

# 清理根目录日志和PID文件
if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_LOGS" = true ]; then
    echo "清理临时日志和PID文件..."
    rm -f auto_check.log auto_check.pid 2>/dev/null || true
    rm -f pipeline.pid pipeline_run.log 2>/dev/null || true
    rm -f putnambench.pid putnambench_run.log 2>/dev/null || true
    rm -f progress_check.log 2>/dev/null || true
    echo "  ✓ 临时文件已清理"
fi

# 清理旧的实验结果（保留最近2个）
if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_OLD_RESULTS" = true ]; then
    echo "清理旧的实验结果目录..."
    if [ -d "results" ]; then
        # 获取最新的2个实验目录
        LATEST_DIRS=$(ls -td results/run_* 2>/dev/null | head -2)
        
        # 删除其他旧目录
        for dir in results/run_*; do
            if [ -d "$dir" ]; then
                is_latest=false
                for latest in $LATEST_DIRS; do
                    if [ "$dir" = "$latest" ]; then
                        is_latest=true
                        break
                    fi
                done
                if [ "$is_latest" = false ]; then
                    echo "  删除: $dir"
                    rm -rf "$dir" 2>/dev/null || true
                fi
            fi
        done
        echo "  ✓ 旧的实验结果已清理（保留最新2个）"
    fi
fi

# 清理其他临时文件
if [ "$CLEAN_ALL" = true ]; then
    echo "清理其他临时文件..."
    find . -name "*.bak" -delete 2>/dev/null || true
    find . -name "*.old" -delete 2>/dev/null || true
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*~" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    echo "  ✓ 其他临时文件已清理"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  清理完成！"
echo "═══════════════════════════════════════════════════════════"
