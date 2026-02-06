"""
结果总结脚本：统计编译结果并生成汇总报告

该脚本分析编译结果，按问题分组统计通过率和解决数量。
"""
import pandas as pd
import numpy as np
import argparse
import os

parser = argparse.ArgumentParser(description='统计编译结果并生成汇总报告')
parser.add_argument('--input_path', required=True, type=str, help='编译结果文件路径（JSON格式）')
parser.add_argument('--full_record_path', required=True, type=str, help='完整记录文件路径（JSON格式）')
parser.add_argument('--output_dir', required=True, type=str, help='输出目录')
parser.add_argument('--field', default="complete", choices=["complete", "pass"], type=str, 
                    help='统计字段：complete（完整通过）或pass（编译通过）')
args = parser.parse_args()


input_file= args.input_path
df = pd.read_json(input_file)
df_full = pd.read_json(args.full_record_path)
ids_lookup = dict(zip(df_full.problem_id, df_full.id_maps))

import numpy as np

# 获取ID映射的层级数量
ids_num_ = np.unique(df_full.id_maps.apply(lambda x: len(x)))
assert len(ids_num_) == 1, "所有记录的id_maps长度必须一致"
ids_num = ids_num_[0]
first_element = df_full.id_maps[0]

# 判断每个证明是否正确（编译通过且不包含apply?或exact?标记）
df["correct"] = df.apply(
    lambda row: int(
        row["compilation_result"][args.field] and 
        "apply?" not in row["code"] and 
        "exact?" not in row["code"]
    ), 
    axis=1
)

import os
os.makedirs(args.output_dir, exist_ok=True)

meta_result = []
name_list = []
for i in range(ids_num):
  names = [k for k, _ in first_element[i].items()]
  assert len(names) == 1
  name = names[0]
  name_list.append(name)
  df[name] =  df["name"].apply(lambda x: ids_lookup[x][i][name])
  df_grp = df[[name, "correct"]].groupby(name)["correct"].aggregate(["sum", "count"]).reset_index()
  df_grp.to_csv(f"{args.output_dir}/{name}_summarize.csv", index=False, header=True, sep='\t', quoting=1, na_rep='Missing')
  meta_result.append({
    "level": f"{name}", 
    "value": {
        "problem_num": len(df_grp),
        "solved_num": sum(df_grp["sum"]>0),
        "solved_ratio": f"{sum(df_grp['sum']>0) / len(df_grp) * 100:.2f}"
      }
  })
  
pd.DataFrame(meta_result).to_json(f"{args.output_dir}/meta_summarize.json", indent=4, orient="records")
print(f"Summary saved to {args.output_dir}")