"""
编译脚本：验证生成的Lean 4代码能否编译通过

该脚本使用Lean REPL调度器并行编译多个证明，并统计编译结果。
"""
import json
import sys
import os
import pandas as pd
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

from lean_compiler.repl_scheduler import scheduler
import argparse
import random
import numpy as np


def handle(text):
    """
    清理Lean代码：移除import、set_option和open语句，移除maxHeartbeats 0
    
    Args:
        text: 原始Lean代码
        
    Returns:
        清理后的代码
    """
    lines = text.split('\n')
    filtered_lines = []
    for line in lines:
        line_stripped = line.strip()
        if (line_stripped.startswith('import') or 
            line_stripped.startswith('set_option') or 
            line_stripped.startswith('open')):
            continue
        if 'maxHeartbeats' in line_stripped and '0' in line_stripped:
            continue
        filtered_lines.append(line)
    return '\n'.join(filtered_lines).strip()


parser = argparse.ArgumentParser(description='编译验证生成的Lean 4证明代码')
parser.add_argument('--input_path', required=True, type=str, help='输入文件路径（JSON格式，包含生成的代码）')
parser.add_argument('--output_path', required=True, type=str, help='输出文件路径（JSON格式，包含编译结果）')
parser.add_argument('--cpu', default=128, type=int, help='并行编译的CPU线程数（默认128）')
parser.add_argument('--timeout', default=300, type=int, help='每个证明的超时时间（秒，默认300）')
args = parser.parse_args()

input_file_path = args.input_path

with open(input_file_path, 'r') as json_file:
    codes = json.load(json_file)


code_df = pd.DataFrame(codes)
sub_df = code_df

if "problem_id" in sub_df.columns:
    sub_df["name"] = sub_df["problem_id"]
else:
    sub_df["problem_id"] = sub_df["name"]
if "full_code" in sub_df.columns:
    sub_df["code"] = sub_df["full_code"].apply(handle)
codes = sub_df[["name", "code", "problem_id"]].to_dict(orient='records')

random.shuffle(codes)

timeout_seconds = args.timeout
print(f"开始编译，使用 {args.cpu} 个线程，每个证明超时 {timeout_seconds} 秒")
print(f"总共 {len(codes)} 个证明需要编译")

outputs_list = scheduler(codes, num_workers = args.cpu, timeout=timeout_seconds)

with open(args.output_path, 'w') as json_file:
    json.dump(outputs_list, json_file, indent=4)

# 统计编译结果
total = len(outputs_list)
passed = sum(1 for x in outputs_list if x.get('compilation_result', {}).get('pass', False))
failed = total - passed
timeout_count = sum(1 for x in outputs_list 
                   if not x.get('compilation_result', {}).get('pass', False) 
                   and 'timeout' in str(x.get('compilation_result', {})).lower())

print(f"\n编译完成！")
print(f"总证明数: {total}")
print(f"通过编译: {passed} ({passed*100/total:.1f}%)")
print(f"编译失败: {failed} ({failed*100/total:.1f}%)")
if timeout_count > 0:
    print(f"超时证明: {timeout_count} ({timeout_count*100/total:.1f}%)")
