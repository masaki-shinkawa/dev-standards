#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ツールごとの設定: ディレクトリ名 -> インストール先
declare -A TOOL_MAP=(
  [codex]="${HOME}/.codex"
  [claude]="${HOME}/.claude"
  [gemini]="${HOME}/.gemini"
  [copilot]="${HOME}/.copilot"
)

VALID_TOOLS=(codex claude gemini copilot)

# -------------------------------------------------------------------
# 使い方
# -------------------------------------------------------------------
usage() {
  cat <<EOF
使い方: setup.sh --all | --tool <name>[,<name>...] [--help]

オプション:
  --all          すべてのツールをセットアップ
  --tool <name>  セットアップ対象のツールをカンマ区切りで指定
                 有効な値: ${VALID_TOOLS[*]}
  --help         このヘルプを表示

例:
  ./setup.sh --all                  # すべてのツールをセットアップ
  ./setup.sh --tool claude          # Claude Code のみ
  ./setup.sh --tool codex,claude    # Codex CLI と Claude Code
EOF
}

# -------------------------------------------------------------------
# 引数パース
# -------------------------------------------------------------------
TARGET_TOOLS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      TARGET_TOOLS=("${VALID_TOOLS[@]}")
      shift
      ;;
    --tool)
      IFS=',' read -ra TARGET_TOOLS <<< "$2"
      shift 2
      ;;
    --help|-h)
      usage; exit 0
      ;;
    *)
      echo "不明なオプション: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# 引数なしはヘルプを表示して終了
if [[ ${#TARGET_TOOLS[@]} -eq 0 ]]; then
  usage; exit 0
fi

# 指定ツール名のバリデーション
for t in "${TARGET_TOOLS[@]}"; do
  valid=false
  for v in "${VALID_TOOLS[@]}"; do
    [[ "${t}" == "${v}" ]] && valid=true && break
  done
  if ! "${valid}"; then
    echo "エラー: 不明なツール '${t}'" >&2
    echo "有効な値: ${VALID_TOOLS[*]}" >&2
    exit 1
  fi
done

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
  local has_content=false
  for f in "${src}"/*; do
    [[ -e "${f}" && "${f##*/}" != ".keep" ]] && has_content=true && break
  done
  if ! "${has_content}"; then
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
echo "=== dev-standards セットアップ (対象: ${TARGET_TOOLS[*]}) ==="
echo ""

# 1. ツール設定のシンボリックリンク
echo "--- 設定ファイルをリンク ---"
for tool in "${TARGET_TOOLS[@]}"; do
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

# 2. スキルを各ツールのネイティブ形式に変換・配置
echo "--- スキルを変換・配置 ---"
if [ -d "${SCRIPT_DIR}/skills" ]; then
  for tool in "${TARGET_TOOLS[@]}"; do
    bash "${SCRIPT_DIR}/convert.sh" --tool "${tool}"
  done
else
  echo "  [skip] skills/ ディレクトリが存在しません"
fi

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  1. 以下を ~/.bashrc または ~/.zshrc に追記してください:"
echo "       export OUTLINE_API_KEY=\"your-api-key-here\""
echo "  2. シェルを再読み込み: source ~/.bashrc"
