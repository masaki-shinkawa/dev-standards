#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ツールごとの設定: "リポジトリ内ディレクトリ:インストール先"
declare -A TOOL_MAP=(
  [codex]="${HOME}/.codex"
  [claude]="${HOME}/.claude"
  [gemini]="${HOME}/.gemini"
  [copilot]="${HOME}/.copilot"
)

# -------------------------------------------------------------------
# シンボリックリンクを作成するヘルパー関数
# usage: link_dir <src_dir> <dest_dir>
# -------------------------------------------------------------------
link_dir() {
  local src="$1"
  local dest="$2"
  local tool
  tool="$(basename "${src}")"

  # ソースディレクトリが空（.keep のみ）なら設定未整備としてスキップ
  local file_count
  file_count=$(find "${src}" -not -name ".keep" -not -path "${src}" | wc -l)
  if [ "${file_count}" -eq 0 ]; then
    echo "  [skip] ${tool}: 設定ファイルがありません（将来追加予定）"
    return
  fi

  mkdir -p "${dest}"

  for item in "${src}"/*; do
    local name
    name="$(basename "${item}")"
    # .keep ファイルは配布しない
    [ "${name}" = ".keep" ] && continue

    local link_dest="${dest}/${name}"
    if [ -L "${link_dest}" ]; then
      echo "  [skip] ${link_dest} (シンボリックリンク既存)"
    elif [ -e "${link_dest}" ]; then
      echo "  [warn] ${link_dest} は既存ファイルのためスキップ"
      echo "         手動で削除してから再実行してください"
    else
      ln -s "${item}" "${link_dest}"
      echo "  [link] ${link_dest}"
      echo "      -> ${item}"
    fi
  done
}

# -------------------------------------------------------------------
# メイン処理
# -------------------------------------------------------------------
echo "dev-standards セットアップを開始します..."
echo ""

for tool in "${!TOOL_MAP[@]}"; do
  src="${SCRIPT_DIR}/${tool}"
  dest="${TOOL_MAP[$tool]}"

  if [ ! -d "${src}" ]; then
    echo "  [skip] ${tool}: ディレクトリが存在しません"
    continue
  fi

  echo "[${tool}] -> ${dest}"
  link_dir "${src}" "${dest}"
  echo ""
done

echo "セットアップ完了。"
echo ""
echo "次のステップ:"
echo "  1. 以下を ~/.bashrc または ~/.zshrc に追記してください:"
echo "       export OUTLINE_API_KEY=\"your-api-key-here\""
echo "  2. シェルを再読み込み: source ~/.bashrc"
echo ""
echo "動作確認:"
echo "  Codex CLI  : codex config show"
echo "  Claude Code: claude config list"
echo "  Gemini CLI : gemini --version"
echo "  Copilot CLI: gh copilot --version"
