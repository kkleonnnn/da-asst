#!/usr/bin/env bash
# 由 reference/ 自动生成「通用知识包.md」——任何 AI / 人都能直接读用。
# 用法： bash scripts/build_pack.sh
# 注意：通用知识包.md 是生成物，请勿手改；改知识请改 reference/ 后重新跑本脚本。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/通用知识包.md"

# 收集 reference/ 下的知识文件：排除 README.md 与以 _ 开头的辅助文件（如 _消化日志.md）
FILES=$(find "$ROOT/reference" -type f -name '*.md' ! -name 'README.md' ! -name '_*' 2>/dev/null | sort)

{
  echo "# 数据分析助理 · 通用知识包"
  echo
  echo "> 本文件由 \`scripts/build_pack.sh\` 从 reference/ 自动生成，**请勿手改**。"
  echo "> 内容为对外部资料的消化改写，已抹除来源信息；**任何 AI 模型**都可作为上下文使用。"
  echo "> 以各文件标注的时间基准 / 可信度为准。"
  echo
  echo "## 目录"
  if [ -z "$FILES" ]; then
    echo "- （reference/ 暂无已消化知识，先按 CONTRIBUTING.md 投喂 + 消化）"
  else
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      echo "- ${f#"$ROOT"/}"
    done <<< "$FILES"
  fi
  echo
  echo "---"
  echo
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    echo "# 【${f#"$ROOT"/}】"
    echo
    cat "$f"
    echo
    echo
    echo "---"
    echo
  done <<< "$FILES"
} > "$OUT"

COUNT=$(printf '%s\n' "$FILES" | grep -c . || true)
echo "已生成 $OUT （纳入 $COUNT 个知识文件）"

# 生成后自动跑来源指纹 / 禁词扫描，确保产出干净
if [ -f "$ROOT/scripts/scrub_check.sh" ]; then
  echo "→ 运行来源指纹 / 禁词扫描…"
  bash "$ROOT/scripts/scrub_check.sh"
fi
