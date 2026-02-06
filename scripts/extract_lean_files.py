#!/usr/bin/env python3
"""
提取问题的Lean格式文件，按通过情况分类
"""

import json
import os
from pathlib import Path
from collections import defaultdict


def extract_lean_code(record, full_records_dict):
    """从记录中提取Lean代码"""
    problem_id = record.get('name', '').rsplit('_g', 1)[0] if '_g' in record.get('name', '') else record.get('name', '')
    
    # 优先使用full_records中的代码
    if problem_id in full_records_dict:
        full_record = full_records_dict[problem_id]
        # 找到对应的生成样本
        for gen_id in range(32):
            gen_problem_id = f"{problem_id}_g{gen_id}"
            if full_record.get('problem_id') == gen_problem_id or any(
                m.get('generation_id') == gen_problem_id 
                for m in full_record.get('id_maps', [])
            ):
                return full_record.get('full_code', '')
    
    # 如果没有找到，使用compilation_result中的code
    return record.get('code', '')


def main():
    # 读取文件
    compilation_file = 'results/run_20260205_085845/code_compilation_repl.json'
    full_records_file = 'results/run_20260205_085845/full_records.json'
    output_dir = Path('results/run_20260205_085845/lean_files')
    
    with open(compilation_file, 'r') as f:
        compilation_results = json.load(f)
    
    with open(full_records_file, 'r') as f:
        full_records = json.load(f)
    
    # 创建problem_id到记录的映射
    full_records_dict = {}
    for r in full_records:
        problem_id = r.get('problem_id', '')
        if '_g' in problem_id:
            base_id = problem_id.rsplit('_g', 1)[0]
        else:
            base_id = problem_id
        full_records_dict[problem_id] = r
        full_records_dict[base_id] = r  # 也保存基础ID
    
    # 按问题分组
    problem_groups = defaultdict(list)
    for record in compilation_results:
        name = record.get('name', '')
        if '_g' in name:
            problem_id = name.rsplit('_g', 1)[0]
        else:
            problem_id = name
        problem_groups[problem_id].append(record)
    
    # 创建输出目录
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / 'fully_passed').mkdir(exist_ok=True)
    (output_dir / 'partially_passed').mkdir(exist_ok=True)
    (output_dir / 'fully_failed').mkdir(exist_ok=True)
    
    # 分类并提取
    fully_passed = []
    partially_passed = []
    fully_failed = []
    
    for problem_id, records in problem_groups.items():
        passed_count = sum(1 for r in records if r.get('compilation_result', {}).get('pass', False))
        total = len(records)
        
        # 找到第一个通过的样本（如果有）
        passed_sample = None
        for r in records:
            if r.get('compilation_result', {}).get('pass', False):
                passed_sample = r
                break
        
        # 如果没有通过的，使用第一个样本
        if not passed_sample:
            passed_sample = records[0] if records else None
        
        if passed_sample:
            lean_code = extract_lean_code(passed_sample, full_records_dict)
            if not lean_code:
                lean_code = passed_sample.get('code', '')
            
            if passed_count == total and total == 32:
                fully_passed.append((problem_id, lean_code))
                file_path = output_dir / 'fully_passed' / f"{problem_id}.lean"
            elif passed_count > 0:
                partially_passed.append((problem_id, lean_code, passed_count, total))
                file_path = output_dir / 'partially_passed' / f"{problem_id}_{passed_count}of{total}.lean"
            else:
                fully_failed.append((problem_id, lean_code))
                file_path = output_dir / 'fully_failed' / f"{problem_id}.lean"
            
            # 写入文件
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(lean_code)
    
    # 生成报告
    report = {
        'summary': {
            'fully_passed': len(fully_passed),
            'partially_passed': len(partially_passed),
            'fully_failed': len(fully_failed),
            'total': len(problem_groups)
        },
        'fully_passed_problems': [p[0] for p in fully_passed],
        'partially_passed_problems': [{'problem_id': p[0], 'passed': p[2], 'total': p[3]} for p in partially_passed],
        'fully_failed_problems': [p[0] for p in fully_failed]
    }
    
    with open(output_dir / 'extraction_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"✅ 提取完成:")
    print(f"   完全通过: {len(fully_passed)} 个问题 -> {output_dir / 'fully_passed'}")
    print(f"   部分通过: {len(partially_passed)} 个问题 -> {output_dir / 'partially_passed'}")
    print(f"   完全未通过: {len(fully_failed)} 个问题 -> {output_dir / 'fully_failed'}")
    print(f"   报告: {output_dir / 'extraction_report.json'}")


if __name__ == "__main__":
    main()
