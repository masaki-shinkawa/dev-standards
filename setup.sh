#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_SRC="${SCRIPT_DIR}/codex"
CODEX_DEST="${HOME}/.codex"

echo "Setting up dev-standards..."

# Create ~/.codex if it doesn't exist
mkdir -p "${CODEX_DEST}"

# Create symlinks for each item in codex/
for item in "${CODEX_SRC}"/*; do
  name="$(basename "${item}")"
  dest="${CODEX_DEST}/${name}"

  if [ -L "${dest}" ]; then
    echo "  [skip] ${dest} (symlink already exists)"
  elif [ -e "${dest}" ]; then
    echo "  [warn] ${dest} already exists and is not a symlink — skipping"
    echo "         Remove it manually if you want to replace it."
  else
    ln -s "${item}" "${dest}"
    echo "  [link] ${dest} -> ${item}"
  fi
done

echo ""
echo "Done. Next steps:"
echo "  1. Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
echo "       export OUTLINE_API_KEY=\"your-api-key-here\""
echo "  2. Reload your shell: source ~/.bashrc  (or restart the terminal)"
echo "  3. Verify Codex can see the config: codex config show"
