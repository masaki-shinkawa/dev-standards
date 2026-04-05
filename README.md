# dev-standards

社内AIコーディングツール（Codex CLI / Claude Code）の設定を標準化するリポジトリです。

## 構成

```
dev-standards/
├── setup.sh                        # セットアップスクリプト
├── codex/
│   ├── config.toml                 # Outline MCP設定
│   ├── AGENTS.md                   # 全プロジェクト共通インストラクション
│   └── skills/
│       └── create-pr/
│           └── SKILL.md            # PR作成スキル
└── claude/                         # Claude Code用設定（将来追加予定）
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

### create-pr

`/create-pr` でPull Requestを作成します。`.github/pull_request_template.md` が存在するプロジェクトでは自動的にテンプレートが使用されます。

## 今後の追加予定

- Claude Code 用設定（`claude/`）
- Gemini CLI 用設定
- ESLint 共通設定
- GitHub Actions テンプレート
