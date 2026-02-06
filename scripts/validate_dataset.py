#!/usr/bin/env python3
"""
数据集格式验证脚本
用法: python3 scripts/validate_dataset.py <dataset_path>
注意: 请从项目根目录运行此脚本，或使用绝对路径
"""
import json
import sys
import os

# 获取脚本所在目录，支持从任何目录运行
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

def validate_dataset(dataset_path):
    """验证数据集格式"""
    # 如果是相对路径，尝试从项目根目录解析
    if not os.path.isabs(dataset_path):
        # 尝试从当前目录
        if not os.path.exists(dataset_path):
            # 尝试从项目根目录
            project_path = os.path.join(PROJECT_ROOT, dataset_path)
            if os.path.exists(project_path):
                dataset_path = project_path
            else:
                # 尝试从dataset目录
                dataset_dir_path = os.path.join(PROJECT_ROOT, "dataset", os.path.basename(dataset_path))
                if os.path.exists(dataset_dir_path):
                    dataset_path = dataset_dir_path
    
    if not os.path.exists(dataset_path):
        print(f"❌ 错误: 文件不存在: {dataset_path}")
        print(f"提示: 请确保文件路径正确，或从项目根目录运行脚本")
        return False
    
    required_fields = ['name', 'problem_id', 'lean4_code']
    optional_fields = ['informal_prefix', 'formal_statement', 'split']
    
    print(f"验证数据集: {dataset_path}")
    print("=" * 60)
    
    total = 0
    valid = 0
    issues = []
    
    with open(dataset_path, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            total += 1
            try:
                data = json.loads(line.strip())
                
                # 检查必需字段
                missing_fields = [field for field in required_fields if field not in data]
                if missing_fields:
                    issues.append(f"行 {line_num}: 缺少必需字段 {missing_fields}")
                    continue
                
                # 检查字段类型
                if not isinstance(data['name'], str):
                    issues.append(f"行 {line_num}: 'name' 必须是字符串")
                    continue
                if not isinstance(data['problem_id'], str):
                    issues.append(f"行 {line_num}: 'problem_id' 必须是字符串")
                    continue
                if not isinstance(data['lean4_code'], str):
                    issues.append(f"行 {line_num}: 'lean4_code' 必须是字符串")
                    continue
                
                # 检查代码是否为空
                if not data['lean4_code'].strip():
                    issues.append(f"行 {line_num}: 'lean4_code' 为空")
                    continue
                
                valid += 1
                
                # 显示前3个样本的信息
                if valid <= 3:
                    print(f"\n样本 {valid}:")
                    print(f"  名称: {data['name']}")
                    print(f"  问题ID: {data['problem_id']}")
                    print(f"  代码长度: {len(data['lean4_code'])} 字符")
                    if 'split' in data:
                        print(f"  划分: {data['split']}")
                
            except json.JSONDecodeError as e:
                issues.append(f"行 {line_num}: JSON 解析错误 - {e}")
            except Exception as e:
                issues.append(f"行 {line_num}: 错误 - {e}")
    
    print("\n" + "=" * 60)
    print(f"验证结果:")
    print(f"  总记录数: {total}")
    print(f"  有效记录: {valid} ({valid*100/total:.1f}%)")
    print(f"  无效记录: {total-valid} ({(total-valid)*100/total:.1f}%)")
    
    if issues:
        print(f"\n发现 {len(issues)} 个问题:")
        for issue in issues[:10]:  # 只显示前10个问题
            print(f"  - {issue}")
        if len(issues) > 10:
            print(f"  ... 还有 {len(issues)-10} 个问题")
        return False
    else:
        print("\n✅ 数据集格式验证通过！")
        return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 scripts/validate_dataset.py <dataset_path>")
        sys.exit(1)
    
    dataset_path = sys.argv[1]
    success = validate_dataset(dataset_path)
    sys.exit(0 if success else 1)
