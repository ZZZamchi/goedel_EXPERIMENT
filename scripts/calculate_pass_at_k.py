#!/usr/bin/env python3
"""
计算Pass@K指标
Pass@K: 对于每个问题，生成K个样本，如果至少有一个样本通过，则算作通过
"""

import json
import sys
from collections import defaultdict
from pathlib import Path


def calculate_pass_at_k(compilation_file: str, k: int = 32):
    """
    计算Pass@K指标
    
    Args:
        compilation_file: 编译结果JSON文件路径
        k: 每个问题的样本数（默认32）
    
    Returns:
        pass_at_k: Pass@K百分比
        total_problems: 总问题数
        passed_problems: 通过问题数
    """
    # 读取编译结果
    with open(compilation_file, 'r') as f:
        compilation_results = json.load(f)
    
    # 按问题ID分组（去掉_g0, _g1等后缀）
    problem_groups = defaultdict(list)
    for record in compilation_results:
        name = record.get('name', '')
        # 提取原始问题ID（去掉_g0, _g1等后缀）
        if '_g' in name:
            problem_id = name.rsplit('_g', 1)[0]
        else:
            problem_id = name
        
        problem_groups[problem_id].append(record)
    
    # 计算每个问题的样本数分布
    sample_counts = defaultdict(int)
    for problem_id, records in problem_groups.items():
        sample_counts[len(records)] += 1
    
    # 计算pass@k
    passed_problems = 0
    total_problems = len(problem_groups)
    
    problem_stats = []
    for problem_id, records in problem_groups.items():
        # 检查是否有至少一个样本通过编译
        passed_count = sum(
            1 for record in records 
            if record.get('compilation_result', {}).get('pass', False)
        )
        has_passed = passed_count > 0
        
        if has_passed:
            passed_problems += 1
        
        problem_stats.append({
            'problem_id': problem_id,
            'passed_samples': passed_count,
            'total_samples': len(records),
            'passed': has_passed
        })
    
    pass_at_k = (passed_problems / total_problems * 100) if total_problems > 0 else 0
    
    # 计算样本级别的统计
    total_samples = len(compilation_results)
    passed_samples = sum(
        1 for record in compilation_results 
        if record.get('compilation_result', {}).get('pass', False)
    )
    sample_pass_rate = (passed_samples / total_samples * 100) if total_samples > 0 else 0
    
    return {
        'pass_at_k': pass_at_k,
        'total_problems': total_problems,
        'passed_problems': passed_problems,
        'total_samples': total_samples,
        'passed_samples': passed_samples,
        'sample_pass_rate': sample_pass_rate,
        'sample_counts': dict(sample_counts),
        'problem_stats': problem_stats
    }


def main():
    if len(sys.argv) < 2:
        print("用法: python calculate_pass_at_k.py <compilation_file> [k]")
        print("示例: python calculate_pass_at_k.py results/run_20260205_085845/code_compilation_repl.json 32")
        sys.exit(1)
    
    compilation_file = sys.argv[1]
    k = int(sys.argv[2]) if len(sys.argv) > 2 else 32
    
    if not Path(compilation_file).exists():
        print(f"错误: 文件不存在: {compilation_file}")
        sys.exit(1)
    
    print("=" * 60)
    print(f"计算 Pass@{k}")
    print("=" * 60)
    print(f"编译结果文件: {compilation_file}")
    print()
    
    results = calculate_pass_at_k(compilation_file, k)
    
    print("样本数分布:")
    for count in sorted(results['sample_counts'].keys()):
        print(f"  {count}个样本: {results['sample_counts'][count]}个问题")
    print()
    
    print("=" * 60)
    print(f"Pass@{k} 结果:")
    print("=" * 60)
    print(f"总问题数: {results['total_problems']}")
    print(f"通过问题数: {results['passed_problems']}")
    print(f"Pass@{k}: {results['pass_at_k']:.2f}%")
    print()
    print("样本级别统计:")
    print(f"总样本数: {results['total_samples']}")
    print(f"通过样本数: {results['passed_samples']}")
    print(f"样本通过率: {results['sample_pass_rate']:.2f}%")
    print("=" * 60)
    
    # 保存详细结果
    output_file = Path(compilation_file).parent / f"pass_at_{k}_results.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    print(f"\n详细结果已保存到: {output_file}")


if __name__ == "__main__":
    main()
