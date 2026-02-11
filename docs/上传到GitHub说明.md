# 上传到 GitHub（ZZZamchi/goedel_EXPERIMENT）说明

## 已完成的本地操作

- 已提交除模型外的全部相关变更（含 `.gitignore`、`.gitattributes`、部分 results、文档等）。
- 已关闭对 `results/run_*/*.json` 的 LFS（因本机未安装 git-lfs），改为普通文件；超大 result 文件已加入 `.gitignore` 不参与提交。
- 已删除 `.git/hooks/post-commit` 中的 LFS 钩子，避免后续 commit 报错。

## 需要你在本机执行的推送

推送需要 GitHub 凭据，请在**本机**在项目根目录执行：

```bash
cd /home/ningmiao/MingzhiZHANG/Goedel-Prover-V2

# 若使用 HTTPS，需配置 token 或凭据
git push --force origin main
```

若使用 **SSH**，请先确认 remote 为 SSH 地址后再推送：

```bash
git remote set-url origin git@github.com:ZZZamchi/goedel_EXPERIMENT.git
git push --force origin main
```

`--force` 会使远程 `main` 与本地完全一致（全部替换远程内容）。

## 被排除、未上传的内容

- **模型**：`model_8B/`（在 `.gitignore` 中）
- **超大 result 文件**（超过 GitHub 单文件 100MB 限制或体积过大）：
  - `results/run_*/full_records.json`
  - `results/run_*/to_inference_codes.json`
  - `results/run_*/code_compilation_repl.json`
- **备份与日志**：`*.bak`、`*.bak2`、`*.log`、`*.pid` 等（见 `.gitignore`）

其他代码、脚本、配置、小体积 result 摘要（如 `pass_at_32_results.json`、`pass_at_32_summary.txt`）均已包含在提交中。
