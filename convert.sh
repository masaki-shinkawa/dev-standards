#!/usr/bin/env bash
# convert.sh
# canonical な skills/*/SKILL.md を各AIツールのネイティブ形式に変換・配置する。
#
# 参考: alirezarezvani/claude-skills の scripts/convert.sh
#
# 対応ツール:
#   codex   -> ~/.codex/skills/<name>/SKILL.md
#   claude  -> ~/.claude/commands/<name>.md    (slash command)
#   gemini  -> ~/.gemini/skills/<name>/SKILL.md
#   copilot -> ~/.copilot/agents/<name>.md
#   all     (デフォルト)
#
# 使い方:
#   ./convert.sh [--tool <name>] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"

# --- カラー出力 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

info()    { echo -e "${BLUE}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[done]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }

# --- 引数パース ---
TARGET_TOOL="all"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TARGET_TOOL="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) error "不明なオプション: $1"; exit 1 ;;
  esac
done

VALID_TOOLS=(codex claude gemini copilot)

if [[ "${TARGET_TOOL}" != "all" ]]; then
  valid=false
  for t in "${VALID_TOOLS[@]}"; do
    [[ "${TARGET_TOOL}" == "${t}" ]] && valid=true && break
  done
  if ! "${valid}"; then
    error "不明なツール: ${TARGET_TOOL}"
    echo "有効なツール: ${VALID_TOOLS[*]} all"
    exit 1
  fi
fi

# -------------------------------------------------------------------
# YAML frontmatter パーサー (awk)
# -------------------------------------------------------------------

# frontmatter からフィールド値を取得
# usage: get_frontmatter_field <skill_file> <field>
get_frontmatter_field() {
  local file="$1"
  local field="$2"
  awk -v field="${field}" '
    /^---$/ { if (fm_start) { exit } else { fm_start=1; next } }
    fm_start && /^[^#]/ {
      split($0, kv, /: */)
      key = kv[1]
      val = substr($0, index($0, kv[2]))
      gsub(/^[ \t"'"'"']+|[ \t"'"'"']+$/, "", val)
      if (key == field) { print val; exit }
    }
  ' "${file}"
}

# frontmatter を除いた本文を取得
# usage: get_body <skill_file>
get_body() {
  local file="$1"
  awk '
    /^---$/ {
      count++
      if (count == 2) { in_body=1; next }
      next
    }
    in_body { print }
  ' "${file}"
}

# -------------------------------------------------------------------
# ファイル書き込みヘルパー
# -------------------------------------------------------------------
write_file() {
  local dest="$1"
  local content="$2"
  if "${DRY_RUN}"; then
    echo "  [dry-run] would write: ${dest}"
    return
  fi
  mkdir -p "$(dirname "${dest}")"
  printf '%s\n' "${content}" > "${dest}"
}

# -------------------------------------------------------------------
# 変換関数
# -------------------------------------------------------------------

# Codex CLI: ~/.codex/skills/<name>/SKILL.md
# SKILL.md をそのままコピー（Codex は YAML frontmatter ごと読む）
convert_codex() {
  local skill_file="$1"
  local name="$2"
  local dest="${HOME}/.codex/skills/${name}/SKILL.md"
  write_file "${dest}" "$(cat "${skill_file}")"
  success "codex  : ${dest}"
}

# Claude Code: ~/.claude/commands/<name>.md
# frontmatter の description を allowed-tools ヘッダーに変換したスラッシュコマンド形式
convert_claude() {
  local skill_file="$1"
  local name="$2"
  local description
  local tools
  description="$(get_frontmatter_field "${skill_file}" "description")"
  tools="$(get_frontmatter_field "${skill_file}" "tools")"
  local body
  body="$(get_body "${skill_file}")"

  local header=""
  if [[ -n "${tools}" ]]; then
    # tools: [bash, read] -> allowed-tools: Bash,Read
    local allowed
    allowed="$(echo "${tools}" | tr -d '[] ' | tr ',' '\n' \
      | awk '{print toupper(substr($0,1,1)) substr($0,2)}' | paste -sd ',' -)"
    header="allowed-tools: ${allowed}"$'\n'
  fi
  [[ -n "${description}" ]] && header+="description: ${description}"$'\n'

  local content
  if [[ -n "${header}" ]]; then
    content="---"$'\n'"${header}""---"$'\n\n'"${body}"
  else
    content="${body}"
  fi

  local dest="${HOME}/.claude/commands/${name}.md"
  write_file "${dest}" "${content}"
  success "claude : ${dest}"
}

# Gemini CLI: ~/.gemini/skills/<name>/SKILL.md
# Codex と同じく SKILL.md をそのまま配置
convert_gemini() {
  local skill_file="$1"
  local name="$2"
  local dest="${HOME}/.gemini/skills/${name}/SKILL.md"
  write_file "${dest}" "$(cat "${skill_file}")"
  success "gemini : ${dest}"
}

# GitHub Copilot CLI: ~/.copilot/agents/<name>.md
# frontmatter を Copilot 形式（description ヘッダー）に変換
convert_copilot() {
  local skill_file="$1"
  local name="$2"
  local description
  description="$(get_frontmatter_field "${skill_file}" "description")"
  local body
  body="$(get_body "${skill_file}")"

  local content
  if [[ -n "${description}" ]]; then
    content="# ${name}"$'\n\n'"${description}"$'\n\n'"${body}"
  else
    content="${body}"
  fi

  local dest="${HOME}/.copilot/agents/${name}.md"
  write_file "${dest}" "${content}"
  success "copilot: ${dest}"
}

# -------------------------------------------------------------------
# メイン: skills/*/SKILL.md をスキャンして変換
# -------------------------------------------------------------------
echo ""
info "スキルを変換します (tool=${TARGET_TOOL}, dry-run=${DRY_RUN})"
echo ""

converted=0
skipped=0

for skill_file in "${SKILLS_DIR}"/*/SKILL.md; do
  [[ -f "${skill_file}" ]] || continue

  skill_dir="$(dirname "${skill_file}")"
  name="$(basename "${skill_dir}")"

  info "▶ ${name}"

  case "${TARGET_TOOL}" in
    all)
      convert_codex  "${skill_file}" "${name}"
      convert_claude "${skill_file}" "${name}"
      convert_gemini "${skill_file}" "${name}"
      convert_copilot "${skill_file}" "${name}"
      ;;
    codex)   convert_codex  "${skill_file}" "${name}" ;;
    claude)  convert_claude "${skill_file}" "${name}" ;;
    gemini)  convert_gemini "${skill_file}" "${name}" ;;
    copilot) convert_copilot "${skill_file}" "${name}" ;;
  esac

  echo ""
  (( converted++ )) || true
done

if [[ "${converted}" -eq 0 ]]; then
  warn "変換対象のスキルが見つかりませんでした（skills/*/SKILL.md）"
else
  info "完了: ${converted} スキルを変換しました"
fi
