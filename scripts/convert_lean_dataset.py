#!/usr/bin/env python3
"""
将Lean格式的数据集转换为项目需要的JSONL格式
支持：ProofNet, LeanCat, FATE
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional


def extract_theorem_from_lean(lean_content: str, file_path: str) -> List[Dict]:
    """
    从Lean文件中提取定理
    
    Args:
        lean_content: Lean文件内容
        file_path: 文件路径（用于生成problem_id）
    
    Returns:
        定理列表，每个定理包含name, formal_statement, lean4_code等
    """
    theorems = []
    
    # 提取文件基础名称
    base_name = Path(file_path).stem
    
    # 提取所有import和open语句
    imports = []
    opens = []
    for line in lean_content.split('\n'):
        if line.strip().startswith('import '):
            imports.append(line.strip())
        elif line.strip().startswith('open '):
            opens.append(line.strip())
        elif line.strip().startswith('open_locale '):
            opens.append(line.strip())
    
    # 提取定理声明
    # 匹配 theorem, lemma, def 等声明
    theorem_pattern = r'(theorem|lemma|def|example)\s+([a-zA-Z0-9_]+)\s*[:(].*?(?=\n\s*(theorem|lemma|def|example|$))'
    
    matches = re.finditer(theorem_pattern, lean_content, re.DOTALL)
    
    for match in matches:
        decl_type = match.group(1)
        name = match.group(2)
        
        # 提取完整声明（包括类型签名）
        full_match = re.search(
            rf'{decl_type}\s+{name}\s*[:(].*?(?=\n\s*(theorem|lemma|def|example|$))',
            lean_content[match.start():],
            re.DOTALL
        )
        
        if full_match:
            formal_statement = full_match.group(0).strip()
            
            # 提取代码部分（包括sorry）
            code_match = re.search(r':=\s*(.*?)(?=\n\s*(theorem|lemma|def|example|$))', formal_statement, re.DOTALL)
            if code_match:
                code_part = code_match.group(1).strip()
            else:
                code_part = "sorry"
            
            # 构建完整的lean4_code
            lean4_code_parts = []
            lean4_code_parts.extend(imports)
            if opens:
                lean4_code_parts.extend(opens)
                lean4_code_parts.append("")
            
            # 提取注释作为informal_prefix
            informal_prefix = ""
            comment_match = re.search(r'/-.*?-\/', formal_statement, re.DOTALL)
            if comment_match:
                informal_prefix = comment_match.group(0)
            
            # 构建完整的代码
            if informal_prefix:
                lean4_code_parts.append(informal_prefix)
            lean4_code_parts.append(formal_statement)
            
            lean4_code = '\n'.join(lean4_code_parts)
            
            # 生成problem_id
            problem_id = f"{base_name}_{name}"
            
            theorem_data = {
                "name": name,
                "problem_id": problem_id,
                "informal_prefix": informal_prefix,
                "formal_statement": formal_statement,
                "lean4_code": lean4_code,
                "split": "test"  # 默认test split
            }
            
            theorems.append(theorem_data)
    
    # 如果没有找到定理，尝试提取整个文件作为一个问题
    if not theorems:
        # 检查是否有sorry（表示未完成的证明）
        if 'sorry' in lean_content or ':=' in lean_content:
            # 提取第一个定理声明
            first_theorem = re.search(r'(theorem|lemma|def)\s+([a-zA-Z0-9_]+)', lean_content)
            if first_theorem:
                name = first_theorem.group(2)
                problem_id = f"{base_name}_{name}"
            else:
                name = base_name
                problem_id = base_name
            
            # 提取注释
            informal_prefix = ""
            comment_match = re.search(r'/-.*?-\/', lean_content, re.DOTALL)
            if comment_match:
                informal_prefix = comment_match.group(0)
            
            theorem_data = {
                "name": name,
                "problem_id": problem_id,
                "informal_prefix": informal_prefix,
                "formal_statement": lean_content.strip(),
                "lean4_code": lean_content.strip(),
                "split": "test"
            }
            theorems.append(theorem_data)
    
    return theorems


def convert_leancat_dataset(source_dir: str, output_path: str):
    """转换LeanCat数据集"""
    source_path = Path(source_dir)
    statements_dir = source_path / "CAT_statement"
    
    if not statements_dir.exists():
        print(f"错误: 找不到 {statements_dir}")
        return
    
    all_theorems = []
    
    # 读取metadata.json（如果存在）
    metadata = {}
    metadata_path = source_path / "metadata.json"
    if metadata_path.exists():
        with open(metadata_path, 'r') as f:
            metadata = json.load(f)
    
    # 遍历所有.lean文件
    for lean_file in statements_dir.glob("*.lean"):
        with open(lean_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        theorems = extract_theorem_from_lean(content, str(lean_file))
        
        # 添加metadata信息
        file_id = lean_file.stem
        if file_id in metadata:
            meta = metadata[file_id]
            for thm in theorems:
                thm["domain"] = meta.get("domain", [])
                thm["level"] = meta.get("level", "Unknown")
                thm["tag"] = meta.get("tag", [])
        
        all_theorems.extend(theorems)
    
    # 写入JSONL文件
    with open(output_path, 'w', encoding='utf-8') as f:
        for thm in all_theorems:
            f.write(json.dumps(thm, ensure_ascii=False) + '\n')
    
    print(f"✅ LeanCat: 转换了 {len(all_theorems)} 个问题到 {output_path}")


def convert_fate_dataset(source_dir: str, output_path: str, difficulty: str = "H"):
    """转换FATE数据集"""
    source_path = Path(source_dir)
    
    # FATE有三个难度级别：FATE-M, FATE-H, FATE-X
    fate_dir = source_path / f"FATE-{difficulty}" / f"FATE{difficulty}"
    
    if not fate_dir.exists():
        print(f"错误: 找不到 {fate_dir}")
        return
    
    all_theorems = []
    
    # 遍历所有.lean文件
    for lean_file in fate_dir.glob("*.lean"):
        with open(lean_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        theorems = extract_theorem_from_lean(content, str(lean_file))
        
        # 添加FATE特定信息
        for thm in theorems:
            thm["difficulty"] = difficulty
            thm["dataset"] = "FATE"
        
        all_theorems.extend(theorems)
    
    # 写入JSONL文件
    with open(output_path, 'w', encoding='utf-8') as f:
        for thm in all_theorems:
            f.write(json.dumps(thm, ensure_ascii=False) + '\n')
    
    print(f"✅ FATE-{difficulty}: 转换了 {len(all_theorems)} 个问题到 {output_path}")


def convert_proofnet_dataset(source_dir: str, output_path: str):
    """转换ProofNet数据集"""
    source_path = Path(source_dir)
    
    # ProofNet的结构可能不同，需要根据实际结构调整
    # 这里假设有benchmark目录
    benchmark_dir = source_path / "benchmark" / "benchmark_to_publish" / "formal"
    
    if not benchmark_dir.exists():
        # 尝试其他可能的位置
        benchmark_dir = source_path / "formal"
        if not benchmark_dir.exists():
            print(f"错误: 找不到ProofNet的formal目录")
            return
    
    all_theorems = []
    
    # 遍历所有.lean文件
    for lean_file in benchmark_dir.rglob("*.lean"):
        with open(lean_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        theorems = extract_theorem_from_lean(content, str(lean_file))
        
        # 添加ProofNet特定信息
        for thm in theorems:
            thm["dataset"] = "ProofNet"
            # 从路径提取来源（如Rudin, Artin等）
            path_parts = lean_file.parts
            if len(path_parts) > 1:
                thm["source"] = path_parts[-2] if len(path_parts) > 1 else "unknown"
        
        all_theorems.extend(theorems)
    
    # 写入JSONL文件
    with open(output_path, 'w', encoding='utf-8') as f:
        for thm in all_theorems:
            f.write(json.dumps(thm, ensure_ascii=False) + '\n')
    
    print(f"✅ ProofNet: 转换了 {len(all_theorems)} 个问题到 {output_path}")


def main():
    if len(sys.argv) < 4:
        print("用法: python convert_lean_dataset.py <dataset_type> <source_dir> <output_path> [options]")
        print("数据集类型: leancat, fate, proofnet")
        print("示例:")
        print("  python convert_lean_dataset.py leancat benchmarks/leancat dataset/leancat.jsonl")
        print("  python convert_lean_dataset.py fate benchmarks/fate dataset/fate_h.jsonl --difficulty H")
        print("  python convert_lean_dataset.py proofnet benchmarks/proofnet dataset/proofnet.jsonl")
        sys.exit(1)
    
    dataset_type = sys.argv[1].lower()
    source_dir = sys.argv[2]
    output_path = sys.argv[3]
    
    # 解析选项
    difficulty = "H"  # FATE默认难度
    if len(sys.argv) > 4:
        for i in range(4, len(sys.argv)):
            if sys.argv[i] == "--difficulty" and i + 1 < len(sys.argv):
                difficulty = sys.argv[i + 1]
    
    if dataset_type == "leancat":
        convert_leancat_dataset(source_dir, output_path)
    elif dataset_type == "fate":
        convert_fate_dataset(source_dir, output_path, difficulty)
    elif dataset_type == "proofnet":
        convert_proofnet_dataset(source_dir, output_path)
    else:
        print(f"错误: 未知的数据集类型 {dataset_type}")
        sys.exit(1)


if __name__ == "__main__":
    main()
