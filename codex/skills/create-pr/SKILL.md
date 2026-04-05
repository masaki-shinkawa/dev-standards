# create-pr

GitHub Pull Requestを作成します。

## 手順

1. **現在のブランチとベースブランチを確認する**
   ```bash
   git branch --show-current
   git remote show origin | grep "HEAD branch"
   ```

2. **変更内容を把握する**
   ```bash
   git log --oneline origin/main..HEAD
   git diff origin/main...HEAD --stat
   ```

3. **PRタイトルと本文を作成する**

   - `.github/pull_request_template.md` が存在する場合はそれに従う
   - 存在しない場合は以下のフォーマットを使用する:

   ```markdown
   ## 変更内容
   <!-- 何を変更したか簡潔に -->

   ## 変更理由
   <!-- なぜこの変更が必要か -->

   ## テスト
   <!-- 動作確認方法 -->
   ```

4. **PRを作成する**

   テンプレートがある場合:
   ```bash
   gh pr create \
     --title "<タイトル>" \
     --body "$(cat .github/pull_request_template.md)" \
     --base main
   ```

   テンプレートがない場合:
   ```bash
   gh pr create \
     --title "<タイトル>" \
     --body "$(cat <<'EOF'
   ## 変更内容
   <内容>

   ## 変更理由
   <理由>

   ## テスト
   <確認方法>
   EOF
   )" \
     --base main
   ```

## 注意事項

- `gh` CLI がインストールされ、認証済みであること（`gh auth status` で確認）
- ブランチが remote にプッシュ済みであること（未プッシュの場合は `git push -u origin <branch>` を先に実行）
- ドラフトPRにする場合は `--draft` フラグを追加
- レビュアーを指定する場合は `--reviewer <username>` を追加
