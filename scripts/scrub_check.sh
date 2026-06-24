#!/usr/bin/env bash
# 来源指纹 / 禁词扫描：确保提交进 git 的内容里不残留资料来源痕迹。
# 用法： bash scripts/scrub_check.sh
# 退出码：发现来源指纹 / 禁词 → 1；干净 → 0。
#
# 两类检查、两种范围：
#   A. 结构性指纹词（来源: / 出处: / 二维码 / 截图自 …）—— 只扫【知识正文文件】
#      （reference/ 下除 README.md 与 _ 开头的元文件 + 通用知识包.md），
#       因为 README / 模板等说明文档会为讲规则而合法地提到这些词。
#   B. 真实来源禁词（本地清单：平台名 / 作者 ID 等）—— 扫【全仓库所有 .md】
#      （排除 inbox / .git / node_modules），保证这些词在公开仓库里哪都不出现。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_LIST="$ROOT/scripts/.scrub_wordlist.local"

# ---- 知识正文文件的扫描目标（A 类用） ----
KN_TARGETS=()
[ -d "$ROOT/reference" ] && KN_TARGETS+=("$ROOT/reference")
[ -f "$ROOT/通用知识包.md" ] && KN_TARGETS+=("$ROOT/通用知识包.md")
KN_FILTER=(--include='*.md' --exclude='README.md' --exclude='_*')

fail=0

# A) 结构性来源指纹（高信号多字短语，避免与"来源/扫码/门票"等正常分析词误撞）→ 仅知识正文，命中即失败。
#    真正的平台名 / 作者 / 水印由 B 段本地禁词清单把关，这里只拦明显的"社群投放/截图"痕迹。
HARD='原文链接|原帖|转载自|转自微信|二维码|扫码加入|扫码关注|扫码进群|扫码入群|扫码添加|扫码查看|会员专享|付费阅读|付费解锁|付费查看|截图自|长按识别|长按二维码'
if [ ${#KN_TARGETS[@]} -gt 0 ]; then
  if grep -rEn "${KN_FILTER[@]}" "$HARD" "${KN_TARGETS[@]}" 2>/dev/null; then
    echo "✗ 知识正文里出现来源指纹词（上方）。请改写删除后再提交。"
    fail=1
  fi
  # 链接与 @账号：弱提示，不阻断
  HITS=$(grep -rEn "${KN_FILTER[@]}" 'https?://|@[A-Za-z0-9_]{2,}' "${KN_TARGETS[@]}" 2>/dev/null | grep -vE 'example\.com|example-site\.com|example\.org|localhost|127\.0\.0\.1' || true)
  if [ -n "$HITS" ]; then
    echo "⚠ 知识正文检测到链接或 @账号（可能是来源痕迹），请确认是否该保留："
    printf '%s\n' "$HITS" | sed 's/^/    /'
  fi
fi

# B) 本地禁词清单（真实来源词）→ 扫全仓库所有 .md，命中即失败
if [ -f "$LOCAL_LIST" ]; then
  while IFS= read -r w; do
    w="$(printf '%s' "$w" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    case "$w" in ''|\#*) continue ;; esac
    if grep -rFn --include='*.md' --exclude-dir=inbox --exclude-dir=.git --exclude-dir=node_modules "$w" "$ROOT" 2>/dev/null; then
      echo "✗ 命中本地禁词：$w —— 请清除（该词不得出现在任何入库文件里）。"
      fail=1
    fi
  done < "$LOCAL_LIST"
else
  echo "⚠ 未找到本地禁词清单 scripts/.scrub_wordlist.local"
  echo "  复制 scripts/.scrub_wordlist.example 为 .local 并填入要拦截的来源相关词，可获得更强保护。"
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "❌ 扫描未通过：上面有来源指纹 / 禁词，请改写清除后再提交。"
  exit 1
fi
echo "✓ 扫描通过：未发现来源指纹 / 禁词。"
