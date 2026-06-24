# scripts

| 脚本 / 文件 | 作用 |
|---|---|
| `build_pack.sh` | 由 `reference/` 生成 `通用知识包.md`（生成后自动跑禁词扫描） |
| `scrub_check.sh` | 来源指纹 / 禁词扫描，命中即报错（用于提交前自检） |
| `ocr_pdf.py` | 本地 OCR：图片型 PDF → 文本（PaddleOCR，需 `.venv-ocr` + poppler）。输出含指纹，只留本地不入库 |
| `ocr_run_all.sh` | 并行批量 OCR：`inbox/*.pdf` → `inbox/_ocr/*.txt`（多进程吃满多核，断点续跑） |
| `.scrub_wordlist.example` | 禁词清单模板；复制为 `.scrub_wordlist.local` 填入要拦截的来源相关词 |
| `.scrub_wordlist.local` | 你的真实禁词清单（已 `.gitignore`，**不入库**） |

```bash
# 首次：建立本地禁词清单（不入库）
cp scripts/.scrub_wordlist.example scripts/.scrub_wordlist.local
# 编辑 .local，逐行填入要拦截的来源相关词（平台名、作者 ID 等）

# 日常：改完 reference/ 后重新生成 + 自检
bash scripts/build_pack.sh
```
