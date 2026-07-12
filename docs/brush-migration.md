# brush デフォルトシェル移行プラン

macOS と WSL/Ubuntu のデフォルトシェルを [brush](https://github.com/reubeno/brush)
(bash 互換の Rust 製シェル) へ段階的に移行するためのプラン。

## 決定事項

2026-07-12 に確認済み:

- **段階移行**: ログインシェルは当面 zsh のまま。opt-in で brush へ exec して日常検証し、安定後に chsh
- **zsh 設定は当面併存**: brush 用設定を新規追加。zsh 設定・zsh プラグイン bootstrap の削除は安定後の別 PR
- **代替を用意する機能**: `auto_pushd` 系のみ(`cd` を `pushd` ラッパー化。brush 上で動作検証済み)
- **破棄する機能**: 履歴の重複除去(`hist_ignore_all_dups` 等)、`share_history`、補完のメニュー選択・
  大小文字無視 matcher、`numeric_glob_sort` / `mark_dirs` / `list_packed` 等の等価物がない zsh options
- **移植する fzf 関数**: `repo` / `dot`、git 系(`fgb` `fga` `fgl` `fgw`)、`frm`。
  `fcd` / `fh` は破棄(`fh` は brush 内蔵 Ctrl-R と `fzf --bash` の Ctrl-R で代替)

## 調査・検証サマリ(brush v0.4.0)

### 起動ファイルの読み込み順(ソース `brush-core/src/shell/initscripts.rs` で確認)

| モード | 読み込み |
|--------|---------|
| ログインシェル | `/etc/profile` → `~/.bash_profile` / `~/.bash_login` / `~/.profile`(最初の 1 つ) |
| 非ログイン・対話 | システム rc → `~/.bashrc` → `~/.brushrc` |

bash と同じ流儀。ログインシェルでは rc を読まないため、`~/.profile` から `~/.bashrc` を
source する必要がある(Ubuntu の既定 `.profile` と同じパターン)。

### 実機検証の結果(このリポジトリの開発コンテナ、brush 0.4.0 を crates.io からビルド)

動作確認済み:

- `HISTFILE` / `HISTSIZE`(履歴ファイルへの書き出しを確認)
- ログインシェルでの `~/.profile` 読み込み、`brush -n`(構文チェック)、`exec`(herdr 起動パターン)
- `source <(cmd)`(`fzf --bash` の読み込みパターン)、`PROMPT_COMMAND`(mise / starship が使用)、
  `trap ... DEBUG`(starship が使用)
- `mapfile`、`read -r -d ''`、`shopt -s nullglob/extglob/globstar`、`[[ $- == *i* ]]`
- `set -o ignoreeof`(`ignore_eof` 相当)、`bind "set bell-style none"`(`no_beep` 相当)
- `cd() { builtin pushd "$@" >/dev/null; }` による `auto_pushd` 代替(`dirs` スタック動作確認)

未実装を確認(bash と挙動が異なる):

- `shopt -s autocd`: オプション名は受理されるが機能しない(ディレクトリ名の直接入力は
  command not found になる)
- `command_not_found_handle`: 呼ばれない(autocd の自前実装も不可)
- `HISTCONTROL`: 未実装(重複除去・ignorespace 不可)

公式ドキュメント記載の既知の制約:

- `select` 文、`wait -n`、`disown` / `logout` 未実装。`$!` が背景ジョブ直後に空になることがある
- signal trap(`SIGINT` 等)は開発中(`DEBUG` / `ERR` / `EXIT` は動作)
- `fzf --bash` は Ctrl-R は動作するが「一部キーコンボは未対応」(公式デモに明記)
- bash-completion 互換の補完、starship、reedline による autosuggestion / syntax highlighting は内蔵

## zsh 設定の移行マッピング

| 現在(zsh) | brush での扱い |
|------------|----------------|
| `.zshenv` の環境変数・XDG・PATH | 共通 POSIX ファイル `.config/shell/env.sh` に抽出し zsh / bash 両方から source(重複ドリフト防止) |
| history options 群 | `HISTFILE=$XDG_DATA_HOME/bash/history`・`HISTSIZE` のみ。重複除去・共有は破棄 |
| `ignore_eof` / `no_beep` / `no_flow_control` | `set -o ignoreeof` / `bind "set bell-style none"` / `stty -ixon` |
| `auto_cd` | 破棄(brush 未実装・フックも不可)。`..` alias と `repo` / `dot` で代替、upstream の実装を追う |
| `auto_pushd` + `pushd_ignore_dups` | `cd` の `pushd` ラッパー(ignore_dups はラッパー内で先頭重複をスキップ) |
| `extended_glob` / `interactive_comments` | `shopt -s extglob globstar` / bash では既定で有効 |
| `list_*` / `numeric_glob_sort` / `mark_dirs` / `complete_in_word` | 破棄 |
| `bindkey -e` | reedline の既定が emacs 風のため不要 |
| compinit + zstyle 群 | bash-completion(mac: `brew install bash-completion@2`、Ubuntu: `bash-completion` パッケージ)を source |
| aliases / `dot()` | そのまま移植(bash 互換構文のみ) |
| zsh-autosuggestions / fast-syntax-highlighting | brush 内蔵(reedline)。`config.toml` で highlighting 有効化 |
| `mise activate zsh` | `mise activate bash`(PROMPT_COMMAND 経由、機構は検証済み) |
| uv 補完キャッシュ | `uv generate-shell-completion bash` で同じキャッシュ方式 |
| eza / nvim / hunk ブロック | そのまま移植 |
| fzf: `fzf --zsh` + lib/ | `fzf --bash` + `lib/*.bash`(`repo` `dot` `fgb` `fga` `fgl` `fgw` `frm` のみ、zsh 固有構文を書き換え) |
| `fcd` / `fh` | 破棄 |
| herdr auto-exec | `[[ -o interactive ]]` → `[[ $- == *i* ]]` に変えて移植 |
| `starship init zsh` | `starship init bash`(公式サポート、依存機構は検証済み) |
| `.zshrc.local` / `.zshenv.local` | `.config/bash/bashrc.local` / `.config/shell/env.local.sh`(gitignore 追加) |

## 新しいファイル構成

`~/.config` はリポジトリの `.config` へ丸ごと symlink 済みのため、`.config/` 配下は
ファイルを置くだけで反映される。home 直下の stub のみ `mise.toml` の `[dotfiles]` に追加する。

```text
.config/shell/env.sh          # POSIX 共通環境変数(zsh .zshenv からも source)
.config/bash/bashrc           # 本体(bash でも brush でも動く内容のみ)
.config/bash/lib/fzf-core.bash
.config/bash/lib/fzf-git.bash
.config/bash/lib/fzf-repo.bash
.config/bash/lib/frm.bash
.config/brush/config.toml     # [ui] syntax-highlighting 等
.bashrc                       # stub: ~/.config/bash/bashrc を source
.profile                      # stub: env.sh + 対話時に ~/.bashrc を source
.brushrc                      # brush 固有設定(当面ほぼ空)
```

`mise.toml` への追加:

```toml
[dotfiles]
"~/.bashrc" = { source = ".bashrc" }
"~/.profile" = { source = ".profile" }
"~/.brushrc" = { source = ".brushrc" }
```

brush 固有の設定は `~/.brushrc` に置くため、`~/.bashrc` は素の bash でもそのまま使える
(Phase 3 の復旧経路を兼ねる)。

## brush のインストール

| 環境 | 方法 |
|------|------|
| macOS | `brew install brush`(chsh 用に安定パス `/opt/homebrew/bin/brush` が得られる) |
| WSL/Ubuntu | mise ubi backend: `.config/mise/config.toml` に `"ubi:reubeno/brush" = "latest"`(mise.lock でバージョン固定)。chsh 用には `~/.local/bin/brush` へ symlink を張る |

## フェーズと検証手順

### Phase 0: インストールと素の動作確認(dotfiles 変更なし)

1. 各マシンに brush をインストール
2. 検証: `brush --version` / `brush --norc --noprofile --no-config`
   で起動し、`echo $0`・簡単なコマンド・Ctrl-C・Ctrl-Z / `fg` を確認

### Phase 1: 設定ファイル追加(この PR 以降の実装)

1. 上記ファイル構成を作成、`mise.toml` の `[dotfiles]` と lint / fmt タスクに bash 系を追加
   (`bash -n` + `brush -n` + `shfmt`)
2. `mise bootstrap --dry-run` で symlink 差分を確認してから `mise run setup`
3. 検証:
   - `mise run lint` が通る
   - `brush -n ~/.bashrc ~/.profile` および `bash -n` が通る
   - `brush`(非ログイン対話)を手動起動し、次のチェックリストを 1 周:

| 項目 | 確認方法 |
|------|---------|
| starship プロンプト | 起動直後に表示。`cd` でセグメント更新 |
| mise activate | mise プロジェクトへ `cd` → `mise current` / ツールのバージョン切替 |
| 補完 | `git swi<TAB>`、`git switch <TAB>` でブランチ名 |
| fzf | Ctrl-R で履歴検索(Ctrl-T / Alt-C は未対応の可能性あり。結果を記録) |
| 自作関数 | `repo` `dot` `fgb` `fga` `fgl` `fgw` `frm` を一通り実行 |
| 履歴 | exit 後に `$XDG_DATA_HOME/bash/history` へ書き出されること |
| autosuggestion / highlighting | 入力中に表示されること |
| ジョブ制御 | `sleep 100` → Ctrl-Z → `jobs` → `fg` |
| herdr | brush から herdr が auto-exec し、pane 内シェルが正常なこと |

### Phase 2: 日常利用(opt-in exec)

1. `.zshrc` の先頭に opt-in ゲートを追加:
   フラグファイル(例: `~/.config/brush/enabled`)が存在し brush が実行可能なら `exec brush`
2. ロールバックはフラグファイルを消すだけ。zsh 側は無変更で残る
3. 1〜2 週間、両マシンで日常利用。問題は都度このドキュメントに記録
4. 特に注視: signal trap 未完によるスクリプトの Ctrl-C 挙動、`fzf --bash` の未対応キー、
   補完 UI の使用感(破棄したメニュー選択の代替が必要かの最終判断)

### Phase 3: chsh(正式切替)

1. 事前に別ターミナルを開いたままにする(復旧用)
2. macOS: `/opt/homebrew/bin/brush` を `/etc/shells` に追記 → `chsh -s /opt/homebrew/bin/brush`
3. WSL/Ubuntu: `~/.local/bin/brush` を `/etc/shells` に追記 → `chsh -s ~/.local/bin/brush`
   (mise 管理の実体への symlink。brew / mise の更新でパスが変わらないことを確認しておく)
4. 検証: 新規ターミナル / `wsl.exe` 起動でログインシェルとして brush が立ち上がり、
   `~/.profile` 経由で環境変数と rc が読まれること(`echo $0` が `-brush` 相当、`shopt login_shell`)
5. 復旧手順(壊れた場合):
   - macOS: Terminal.app の設定でシェルコマンドを `/bin/zsh` に指定して起動 → `chsh -s /bin/zsh`
   - WSL: `wsl.exe -e /bin/bash` で入り `chsh -s /usr/bin/zsh`
   - brush 起動はするが rc が壊れた場合: `brush --norc --noprofile` で入って修正

### Phase 4: zsh 撤去(安定後の別 PR)

- `.config/zsh/`・`.zshenv`・`[bootstrap.repos]` の zsh プラグイン・`lint:zsh` / shfmt 対象を削除
- `.zshenv.local` / `.zshrc.local` の内容を bash 側 local ファイルへ移すよう各マシンで手動対応

## 撤退条件

Phase 2 の間に以下が発生し許容できない場合は chsh へ進まず、フラグファイル削除で zsh に戻す:

- 日常のスクリプト・CLI ツールが signal trap / `$!` / `select` 等の未実装機能で誤動作する
- fzf / 補完の使用感が zsh 比で許容できない
- brush 本体のクラッシュや履歴破損

upstream は活発(compat テスト 1700+、bash 5.3 互換目標)のため、ブロッカーは
[issues](https://github.com/reubeno/brush/issues) を確認し、必要なら報告して次版を待つ。
