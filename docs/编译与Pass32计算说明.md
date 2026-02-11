# 编译结果与 Pass@32 计算说明

本文档说明项目内**如何编译推理结果**以及**如何计算 Pass@32**，便于在新机器上复现或排查问题。不涉及运行大型程序。

---

## 一、整体流程

1. **推理** → 生成 `to_inference_codes.json`
2. **编译** → 读取上述 JSON，用 Lean REPL 验证每条代码，写出 `code_compilation_repl.json`
3. **Pass@32** → 读取编译结果 JSON，按问题分组，计算“至少有一个样本通过”的问题占比

---

## 二、编译（compile）

### 2.1 输入

- **文件**：`<run_dir>/to_inference_codes.json`
- **来源**：`src/inference.py` 在推理结束后写入该路径（见 `output_file_path_inference_codes`）。
- **格式**：JSON 列表，每条至少包含：
  - `problem_id` 或 `name`（如 `induction_12dvd4expnp1p20_g0`）
  - `full_code` 或 `code`（Lean 4 完整代码，含定理声明与证明）

### 2.2 命令（当时用法）

来自 `scripts/pipeline.sh`：

```bash
python3 src/compile.py \
  --input_path "<run_dir>/to_inference_codes.json" \
  --output_path "<run_dir>/code_compilation_repl.json" \
  --cpu <线程数> \
  --timeout 300
```

- `--cpu` 默认在 `pipeline.sh` 里是 128，在 `run_dataset.sh` 里也可通过 `--cpu N` 传入。**线程数过高会导致内存溢出**，新机器建议调低（例如 8、16、32）。
- `--timeout` 为每个证明的 REPL 超时秒数，默认 300。

**注意**：`compile.py` 只接受上述四个参数。若把日志文件等当作参数传入（例如 `run.log`），会报错：`error: unrecognized arguments: run.log`（如 `results/run_20260206_025202/compile_re` 中记录）。

### 2.3 编译脚本在做什么（src/compile.py）

1. 读入 `to_inference_codes.json`，转成 DataFrame。
2. 统一列名：有 `problem_id` 则用作 `name`，否则用 `name`；有 `full_code` 则用 `handle(full_code)` 得到 `code`，否则用 `code`。
3. `handle()` 会：去掉 `import`/`set_option`/`open`、去掉 `maxHeartbeats 0`，并做少量“重复/缺失 `:= by`”的修复。
4. 打乱顺序后，调用 `lean_compiler.repl_scheduler.scheduler(codes, num_workers=args.cpu, timeout=timeout_seconds)`。
5. 将返回的列表原样写入 `code_compilation_repl.json`。

### 2.4 REPL 调度器（lean_compiler/repl_scheduler.py）

- 在 **mathlib4/** 工作目录下，对每个 worker 启动：`lake exe repl`（通过 bash）。
- 每个 proof 以 JSON 命令形式发给 REPL，等待双换行结束的 JSON 响应；超时由 `PROOF_TIMEOUT`（默认 300）或 `compile.py --timeout` 控制。
- 依赖：本机已安装 elan、Lean 4、lake，且 `mathlib4` 已能正常 `lake exe repl`。**新机器若环境未装好或路径不同，容易出现大量 JSONDECODE / TIMEOUT**。

### 2.5 输出格式（code_compilation_repl.json）

JSON **数组**，每项形如：

```json
{
  "name": "induction_12dvd4expnp1p20_g31",
  "code": "theorem ...",
  "compilation_result": {
    "pass": true 或 false,
    "complete": ...,
    "system_errors": "..."   // 失败时可能有 TIMEOUT / JSONDECODE 等
  },
  "verify_time": 0.6
}
```

Pass@32 只关心 **`compilation_result.pass`** 是否为 `true`。

---

## 三、Pass@32 计算（calculate_pass_at_k）

### 3.1 输入

- **文件**：`<run_dir>/code_compilation_repl.json`（即上一步编译输出）。

### 3.2 命令（当时用法）

来自 `analyze_results.sh` 或直接运行：

```bash
python3 scripts/calculate_pass_at_k.py "<run_dir>/code_compilation_repl.json" 32
```

第二个参数为 K，默认 32，即 Pass@32。

### 3.3 计算逻辑（scripts/calculate_pass_at_k.py）

1. 读取编译结果列表，按 **问题 ID** 分组：
   - 从每条记录的 `name` 中去掉后缀 `_g0`, `_g1`, ...（即 `name.rsplit('_g', 1)[0]`）得到 `problem_id`，同一 `problem_id` 的样本归为一组。
2. **问题级别**：若某问题下**至少有一个**样本满足 `compilation_result.pass == True`，则该问题计为“通过”。
3. **Pass@32** = `通过问题数 / 总问题数 * 100`（总问题数 = 不同 `problem_id` 的个数）。
4. 同时会统计并打印：
   - 每个问题有多少个样本（如 32 个样本）、样本数分布；
   - 总样本数、通过样本数、样本通过率。

### 3.4 输出

- 终端打印：样本数分布、总/通过问题数、Pass@32%、总/通过样本数、样本通过率。
- 文件：**`<run_dir>/pass_at_32_results.json`**，内含 `pass_at_k`、`total_problems`、`passed_problems`、`problem_stats` 等。
- 若通过 `analyze_results.sh` 分析，还会把终端输出 tee 到 **`<run_dir>/pass_at_32_summary.txt`**。

---

## 四、新机器上“无法正确编译”的常见原因

1. **编译命令写错**  
   只应传 4 个参数：`--input_path`、`--output_path`、`--cpu`、`--timeout`。不要传入 `run.log` 等。

2. **输入文件不对**  
   编译的输入必须是 **`to_inference_codes.json`**（推理产出），不是 `inference.log` 或其它日志。

3. **CPU 线程数过高**  
   `--cpu` 过大（如 128）容易导致内存溢出。建议新机器先用较小值（如 8 或 16）试跑。

4. **Lean/REPL 环境未就绪**  
   - `mathlib4/` 下能执行 `lake exe repl`；
   - 若 REPL 未正确安装或输出格式不一致，会出现大量 `JSONDECODE ERROR` 或 `TIMEOUT`，导致 `compilation_result.pass` 几乎全为 false。

5. **编译未跑完或中断**  
   若因 OOM/中断导致 `code_compilation_repl.json` 不完整或缺失大量条目，再算 Pass@32 会得到偏少或失真的结果。应保证编译阶段完整跑完再计算 Pass@32。

---

## 五、快速检查清单（不运行大型程序）

- [ ] 编译命令是否为：  
  `python3 src/compile.py --input_path <run_dir>/to_inference_codes.json --output_path <run_dir>/code_compilation_repl.json --cpu <较小值> --timeout 300`
- [ ] 输入文件 `<run_dir>/to_inference_codes.json` 是否存在且为推理输出。
- [ ] Pass@32 命令是否为：  
  `python3 scripts/calculate_pass_at_k.py <run_dir>/code_compilation_repl.json 32`
- [ ] 编译结果 JSON 是否为列表，且每项含 `name`、`compilation_result.pass`。
- [ ] 新机器上 `mathlib4` 目录下执行 `lake exe repl` 是否正常、环境是否与当时一致。

按上述流程，在新机器上用**较低的 `--cpu`** 重新编译 `to_inference_codes.json`，得到完整的 `code_compilation_repl.json` 后再运行 `calculate_pass_at_k.py`，即可复现当时的 Pass@32 计算方式。
