#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# CLIツール管理スクリプト
# tools.json に宣言されたツールを GitHub リリースや公式インストーラーで管理する。
# 依存: bash, curl, jq
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_JSON="${SCRIPT_DIR}/tools.json"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

# ---------------------------------------------------------------------------
# ユーティリティ
# ---------------------------------------------------------------------------

die()     { echo "error: $*" >&2; exit 1; }
info()    { echo "  $*"; }
section() { echo "=== $* ==="; }

check_deps() {
  command -v jq >/dev/null 2>&1   || die "jq is required but not installed."
  command -v curl >/dev/null 2>&1 || die "curl is required but not installed."
}

detect_platform() {
  echo "$(uname -s)-$(uname -m)"
}

# JSON 値中の $HOME を展開する（install_dir / args に使用）
expand_vars() {
  local str="$1"
  echo "${str/\$HOME/$HOME}"
}

# ---------------------------------------------------------------------------
# GitHub API
# ---------------------------------------------------------------------------

# リリース JSON を1回だけ取得する（tag="latest" → /releases/latest、それ以外 → /releases/tags/{tag}）
get_release_json() {
  local repo="$1" tag="$2" url
  if [[ "$tag" == "latest" ]]; then
    url="https://api.github.com/repos/${repo}/releases/latest"
  else
    url="https://api.github.com/repos/${repo}/releases/tags/${tag}"
  fi
  curl -sfL "$url"
}

# リリース JSON から正規表現パターンに一致するアセットの download URL を返す
find_asset_url() {
  local release_json="$1" pattern="$2"
  echo "$release_json" | jq -r --arg p "$pattern" \
    'first(.assets[] | select(.name | test($p)) | .browser_download_url) // empty'
}

# ---------------------------------------------------------------------------
# バックアップ
# ---------------------------------------------------------------------------

backup_existing() { local p="$1"; [[ -e "$p" ]] && mv "$p" "${p}.bak"; true; }
cleanup_backup()  { rm -rf "${1}.bak"; }

# ---------------------------------------------------------------------------
# アーカイブ形式検出（ファイル名の拡張子から判定）
# ---------------------------------------------------------------------------

detect_archive_type() {
  local name="$1"
  case "$name" in
  *.tar.gz | *.tgz) echo "tar" ;;
  *.tar.xz)         echo "tar" ;;
  *.tar.bz2)        echo "tar" ;;
  *.zip)            echo "zip" ;;
  *.gz)             echo "gz"  ;;
  *)                echo "binary" ;;
  esac
}

# ---------------------------------------------------------------------------
# 展開・インストール処理
#
# archive フィールドの有無とアーカイブ形式に応じて処理を切り替える。
#
# archive なし:
#   gz     → gunzip して BIN_DIR/bin に配置
#   binary → そのまま BIN_DIR/bin にコピー
#   zip    → 展開後、bin 名でバイナリを検索して BIN_DIR/bin にコピー
#
# archive あり（install_dir なし）:
#   tar    → strip 後、bin_path を BIN_DIR/bin にコピー
#   zip    → 展開後、bin 名でバイナリを検索して BIN_DIR/bin にコピー
#
# archive あり（install_dir あり）:
#   tar    → install_dir に展開し、bin_path → BIN_DIR/bin をシムリンク
#   zip    → install_dir にコピーし、bin_path → BIN_DIR/bin をシムリンク
# ---------------------------------------------------------------------------

do_extract() {
  local asset_path="$1"
  local asset_name="$2"
  local archive_json="$3"
  local bin="$4"

  local arch_type
  arch_type="$(detect_archive_type "$asset_name")"
  mkdir -p "$BIN_DIR"

  # archive フィールドなし
  if [[ -z "$archive_json" ]]; then
    case "$arch_type" in
    gz)
      gunzip -c "$asset_path" > "${BIN_DIR}/${bin}"
      chmod +x "${BIN_DIR}/${bin}"
      ;;
    binary)
      cp "$asset_path" "${BIN_DIR}/${bin}"
      chmod +x "${BIN_DIR}/${bin}"
      ;;
    zip)
      local tmpdir
      tmpdir="$(mktemp -d)"
      unzip -q "$asset_path" -d "$tmpdir"
      local found
      found="$(find "$tmpdir" -name "$bin" -type f | head -1)"
      if [[ -z "$found" ]]; then
        rm -rf "$tmpdir"
        die "Binary '${bin}' not found in zip archive"
      fi
      cp "$found" "${BIN_DIR}/${bin}"
      chmod +x "${BIN_DIR}/${bin}"
      rm -rf "$tmpdir"
      ;;
    *)
      die "archive field required for ${arch_type} archives"
      ;;
    esac
    return
  fi

  # archive フィールドあり
  local strip bin_path install_dir_raw install_dir
  strip="$(echo "$archive_json" | jq -r '.strip_components // 0')"
  bin_path="$(echo "$archive_json" | jq -r '.bin_path // empty')"
  install_dir_raw="$(echo "$archive_json" | jq -r '.install_dir // empty')"
  install_dir=""
  [[ -n "$install_dir_raw" ]] && install_dir="$(expand_vars "$install_dir_raw")"

  case "$arch_type" in
  tar)
    if [[ -n "$install_dir" ]]; then
      mkdir -p "$install_dir"
      tar xf "$asset_path" -C "$install_dir" --strip-components="$strip"
      ln -sf "${install_dir}/${bin_path}" "${BIN_DIR}/${bin}"
    else
      [[ -n "$bin_path" ]] || die "bin_path required in archive field for tar archives"
      local tmpdir
      tmpdir="$(mktemp -d)"
      tar xf "$asset_path" -C "$tmpdir" --strip-components="$strip"
      cp "${tmpdir}/${bin_path}" "${BIN_DIR}/${bin}"
      chmod +x "${BIN_DIR}/${bin}"
      rm -rf "$tmpdir"
    fi
    ;;
  zip)
    # zip は install_dir の有無によらずバイナリを名前で検索する
    # （サブディレクトリ名にバージョンが入るケースに対応）
    local tmpdir
    tmpdir="$(mktemp -d)"
    unzip -q "$asset_path" -d "$tmpdir"
    if [[ -n "$install_dir" ]]; then
      mkdir -p "$install_dir"
      cp -r "$tmpdir"/. "$install_dir/"
      [[ -n "$bin_path" ]] || die "bin_path required in archive field for zip with install_dir"
      ln -sf "${install_dir}/${bin_path}" "${BIN_DIR}/${bin}"
    else
      local found
      found="$(find "$tmpdir" -name "$bin" -type f | head -1)"
      if [[ -z "$found" ]]; then
        rm -rf "$tmpdir"
        die "Binary '${bin}' not found in zip archive"
      fi
      cp "$found" "${BIN_DIR}/${bin}"
      chmod +x "${BIN_DIR}/${bin}"
    fi
    rm -rf "$tmpdir"
    ;;
  *)
    die "Unsupported archive type '${arch_type}' with archive field"
    ;;
  esac
}

# ---------------------------------------------------------------------------
# github_release インストール
# ---------------------------------------------------------------------------

install_github_release() {
  local tool_json="$1"
  local platform
  platform="$(detect_platform)"

  local name repo tag bin
  name="$(echo "$tool_json" | jq -r '.name')"
  repo="$(echo "$tool_json" | jq -r '.repo')"
  tag="$(echo "$tool_json" | jq -r '.tag')"
  bin="$(echo "$tool_json" | jq -r '.bin')"

  # プラットフォームに対応するパターンを取得（なければスキップ）
  local pattern
  pattern="$(echo "$tool_json" | jq -r --arg p "$platform" '.asset_patterns[$p] // empty')"
  if [[ -z "$pattern" ]]; then
    echo "  Skipping ${name}: no asset defined for platform '${platform}'"
    echo ""
    return
  fi

  # GitHub API から リリース JSON を1回取得
  info "Fetching release info..."
  local release_json resolved_tag
  release_json="$(get_release_json "$repo" "$tag")"
  resolved_tag="$(echo "$release_json" | jq -r '.tag_name // empty')"
  [[ -n "$resolved_tag" ]] || die "Failed to get release for ${repo}@${tag}"

  # パターンにマッチするアセットの URL を取得
  local url asset_name
  url="$(find_asset_url "$release_json" "$pattern")"
  [[ -n "$url" ]] || die "No asset matching '${pattern}' in ${repo}@${resolved_tag}"
  asset_name="$(basename "$url")"

  local archive_json
  archive_json="$(echo "$tool_json" | jq -c '.archive // empty')"

  section "${name} (${resolved_tag})"
  info "Repo:  ${repo}"
  info "Asset: ${asset_name}"
  echo ""

  # ダウンロード
  local tmpdir
  tmpdir="$(mktemp -d)"
  info "Downloading..."
  curl -sfL -o "${tmpdir}/${asset_name}" "$url"

  # バックアップ対象を決定
  local backup_target
  if [[ -n "$archive_json" ]]; then
    local install_dir_raw
    install_dir_raw="$(echo "$archive_json" | jq -r '.install_dir // empty')"
    if [[ -n "$install_dir_raw" ]]; then
      backup_target="$(expand_vars "$install_dir_raw")"
    else
      backup_target="${BIN_DIR}/${bin}"
    fi
  else
    backup_target="${BIN_DIR}/${bin}"
  fi

  backup_existing "$backup_target"
  do_extract "${tmpdir}/${asset_name}" "$asset_name" "$archive_json" "$bin"
  cleanup_backup "$backup_target"

  rm -rf "$tmpdir"
  info "Installed: ${BIN_DIR}/${bin}"
  echo ""
}

# ---------------------------------------------------------------------------
# installer インストール（curl | sh 形式）
# ---------------------------------------------------------------------------

install_installer() {
  local tool_json="$1"
  local name url
  name="$(echo "$tool_json" | jq -r '.name')"
  url="$(echo "$tool_json" | jq -r '.url')"

  section "${name}"
  info "URL: ${url}"
  echo ""

  # .args が定義されていれば sh -s -- <args> として渡す（$HOME 等を展開）
  local has_args
  has_args="$(echo "$tool_json" | jq -r 'if .args then "yes" else "no" end')"
  if [[ "$has_args" == "yes" ]]; then
    local -a args_arr=()
    while IFS= read -r arg; do
      args_arr+=("$(expand_vars "$arg")")
    done < <(echo "$tool_json" | jq -r '.args[]')
    curl -fsSL "$url" | sh -s -- "${args_arr[@]}"
  else
    curl -fsSL "$url" | sh
  fi

  info "Done."
  echo ""
}

# ---------------------------------------------------------------------------
# ディスパッチ
# ---------------------------------------------------------------------------

install_tool() {
  local name="$1"
  local tool_json kind
  tool_json="$(jq -c --arg n "$name" '.tools[] | select(.name == $n)' "$TOOLS_JSON")"
  [[ -n "$tool_json" ]] || die "Tool '${name}' not found in ${TOOLS_JSON}"
  kind="$(echo "$tool_json" | jq -r '.kind')"

  case "$kind" in
  github_release) install_github_release "$tool_json" ;;
  installer)      install_installer "$tool_json" ;;
  *)              die "Unknown kind '${kind}' for tool '${name}'" ;;
  esac
}

install_all() {
  local -a names
  mapfile -t names < <(jq -r '.tools[].name' "$TOOLS_JSON")
  for name in "${names[@]}"; do
    install_tool "$name"
  done
}

list_tools() {
  printf "%-25s %-15s %s\n" "NAME" "KIND" "REPO / URL"
  printf "%-25s %-15s %s\n" "----" "----" "----------"
  jq -r '.tools[] | [.name, .kind, (.repo // .url // "-")] | @tsv' "$TOOLS_JSON" \
    | while IFS=$'\t' read -r name kind src; do
        printf "%-25s %-15s %s\n" "$name" "$kind" "$src"
      done
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TOOL...]

管理対象のCLIツールをインストールする。

Options:
  -l, --list    管理ツール一覧を表示
  -h, --help    このヘルプを表示

Arguments:
  TOOL    インストールするツール名（省略時は全ツール）

Examples:
  $(basename "$0")                          # 全ツールをインストール
  $(basename "$0") neovim                   # neovim のみ
  $(basename "$0") neovim tree-sitter rg
  $(basename "$0") --list
EOF
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

main() {
  check_deps

  if [[ $# -eq 0 ]]; then
    install_all
    echo "Done. Make sure ${BIN_DIR} is in your PATH."
    return
  fi

  case "$1" in
  -l | --list) list_tools ;;
  -h | --help) usage ;;
  -*)          die "Unknown option: $1" ;;
  *)
    for name in "$@"; do
      install_tool "$name"
    done
    echo "Done. Make sure ${BIN_DIR} is in your PATH."
    ;;
  esac
}

main "$@"
