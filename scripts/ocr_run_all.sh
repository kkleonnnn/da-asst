#!/usr/bin/env bash
# 并行本地 OCR：把 inbox/ 所有图片型 PDF → inbox/_ocr/<同名>.txt（已存在则跳过，可断点续跑）。
# medium 模型（准），多进程分片吃满多核。输出文本含来源指纹，只留本地、绝不入库。
# 用法： bash scripts/ocr_run_all.sh      （可用环境变量 P / OCR_DPI / OCR_THREADS 调参）
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
export OCR_DPI="${OCR_DPI:-110}"
export OCR_THREADS="${OCR_THREADS:-2}"
P="${P:-10}"
mkdir -p inbox/_ocr

echo "并行度 P=$P  DPI=$OCR_DPI  线程/进程=$OCR_THREADS  开始 $(date +%H:%M:%S)"
find inbox -maxdepth 1 -name '*.pdf' -print0 \
  | xargs -0 -P "$P" -n 5 env \
      OCR_DPI="$OCR_DPI" OCR_THREADS="$OCR_THREADS" PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True \
      .venv-ocr/bin/python scripts/ocr_pdf.py --out inbox/_ocr
echo "完成 $(date +%H:%M:%S)  已产出 $(ls inbox/_ocr/*.txt 2>/dev/null | wc -l | tr -d ' ') 个 txt / 共 $(ls inbox/*.pdf | wc -l | tr -d ' ') 个 pdf"
