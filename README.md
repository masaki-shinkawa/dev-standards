# dev-standards

社内AIコーディングツール（Codex CLI / Claude Code）の設定を標準化するリポジトリです。

## 構成

```
dev-standards/
├── setup.sh                        # セットアップスクリプト（設定リンク + convert.sh 呼び出し）
├── convert.sh                      # スキルを各ツールのネイティブ形式に変換
├── skills/                         # ツール共通スキル（YAML frontmatter 付き SKILL.md）
│   └── create-pr/
│       └── SKILL.md
├── codex/                          # Codex CLI 設定  -> ~/.codex/
│   ├── config.toml                 #   Outline MCP設定
│   └── AGENTS.md                   #   全プロジェクト共通インストラクション
├── claude/                         # Claude Code 設定 -> ~/.claude/  （将来追加予定）
├── gemini/                         # Gemini CLI 設定  -> ~/.gemini/  （将来追加予定）
└── copilot/                        # Copilot CLI 設定 -> ~/.copilot/ （将来追加予定）
```

## オンボーディング手順

### 1. リポジトリをクローン

```bash
git clone git@github.com:masaki-shinkawa/dev-standards.git ~/dev-standards
cd ~/dev-standards
```

### 2. setup.sh を実行

```bash
bash setup.sh
```

`codex/` 以下のファイルが `~/.codex/` にシンボリックリンクされます。

### 3. 環境変数を追加

`~/.bashrc` または `~/.zshrc` に以下を追加してください:

```bash
export OUTLINE_API_KEY="your-api-key-here"
```

その後、シェルを再読み込みします:

```bash
source ~/.bashrc   # または source ~/.zshrc
```

Outline APIキーは社内の管理者から取得してください。

### 4. 動作確認

```bash
codex config show
```

Outline MCP サーバーが表示されれば設定完了です。

## MCP サーバー

### Outline

社内wikiのOutlineをAIコーディングツールから参照できます。

- **必要な環境変数**: `OUTLINE_API_KEY`
- **用途**: 設計ドキュメント・仕様書の参照

## スキル

スキルは `skills/*/SKILL.md` に YAML frontmatter 付きで記述します。`setup.sh`（内部で `convert.sh` を呼び出す）を実行すると、各ツールのネイティブ形式に自動変換されます。

| 変換先 | 配置パス |
|---|---|
| Codex CLI | `~/.codex/skills/<name>/SKILL.md` |
| Claude Code | `~/.claude/commands/<name>.md`（slash command） |
| Gemini CLI | `~/.gemini/skills/<name>/SKILL.md` |
| Copilot CLI | `~/.copilot/agents/<name>.md` |

特定ツールだけ再変換したい場合:

```bash
./convert.sh --tool claude
./convert.sh --tool codex
# 変更内容の確認だけしたい場合
./convert.sh --dry-run
```

### create-pr

`/create-pr` でPull Requestを作成します。`.github/pull_request_template.md` が存在するプロジェクトでは自動的にテンプレートが使用されます。

## 対応ツール

| ディレクトリ | ツール | インストール先 | 状態 |
|---|---|---|---|
| `codex/` | Codex CLI | `~/.codex/` | 設定済み |
| `claude/` | Claude Code | `~/.claude/` | 準備中 |
| `gemini/` | Gemini CLI | `~/.gemini/` | 準備中 |
| `copilot/` | GitHub Copilot CLI | `~/.copilot/` | 準備中 |

## 今後の追加予定

- Claude Code 用設定（`settings.json`、`CLAUDE.md`、カスタムコマンド）
- Gemini CLI 用設定（`settings.json`、`GEMINI.md`）
- GitHub Copilot CLI 用設定（`mcp-config.json`、カスタムエージェント）
- ESLint 共通設定
- GitHub Actions テンプレート
