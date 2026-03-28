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

die() {
  echo "error: $*" >&2
  exit 1
}

info() {
  echo "  $*"
}

section() {
  echo "=== $* ==="
}

check_deps() {
  command -v jq >/dev/null 2>&1 || die "jq is required but not installed."
  command -v curl >/dev/null 2>&1 || die "curl is required but not installed."
}

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  echo "${os}-${arch}"
}

# $HOME などの変数を展開する（JSON内で "$HOME/..." と書けるようにする）
expand_vars() {
  local str="$1"
  # $HOME のみ対象（eval は使わない）
  echo "${str/\$HOME/$HOME}"
}

# ---------------------------------------------------------------------------
# GitHub API
# ---------------------------------------------------------------------------

get_latest_tag() {
  local repo="$1"
  local tag
  tag="$(curl -sfL "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')"
  [[ -n "$tag" && "$tag" != "null" ]] || die "Failed to get latest tag for ${repo}"
  echo "$tag"
}

resolve_tag() {
  local tool_json="$1"
  local repo tag
  tag="$(echo "$tool_json" | jq -r '.tag')"
  if [[ "$tag" == "latest" ]]; then
    repo="$(echo "$tool_json" | jq -r '.repo')"
    get_latest_tag "$repo"
  else
    echo "$tag"
  fi
}

get_asset_name() {
  local tool_json="$1"
  local platform="$2"
  local asset
  asset="$(echo "$tool_json" | jq -r --arg p "$platform" '.assets[$p] // empty')"
  if [[ -z "$asset" ]]; then
    local name
    name="$(echo "$tool_json" | jq -r '.name')"
    die "No asset defined for platform '${platform}' in tool '${name}'"
  fi
  echo "$asset"
}

# ---------------------------------------------------------------------------
# バックアップ / ロールバック
# ---------------------------------------------------------------------------

backup_existing() {
  local path="$1"
  if [[ -e "$path" ]]; then
    mv "$path" "${path}.bak"
  fi
}

cleanup_backup() {
  local path="$1"
  rm -rf "${path}.bak"
}

rollback() {
  local path="$1"
  if [[ -e "${path}.bak" ]]; then
    rm -rf "$path"
    mv "${path}.bak" "$path"
    echo "  Rolled back: ${path}" >&2
  fi
}

# ---------------------------------------------------------------------------
# アーカイブ展開
# ---------------------------------------------------------------------------

extract_tar_gz() {
  local src="$1"
  local dest_dir="$2"
  local strip="${3:-0}"
  mkdir -p "$dest_dir"
  tar xzf "$src" -C "$dest_dir" --strip-components="$strip"
}

extract_gz() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  gunzip -c "$src" >"$dest"
  chmod +x "$dest"
}

extract_zip() {
  local src="$1"
  local dest_dir="$2"
  mkdir -p "$dest_dir"
  unzip -q "$src" -d "$dest_dir"
}

install_binary() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  chmod +x "$dest"
}

# ---------------------------------------------------------------------------
# github_release インストール
# ---------------------------------------------------------------------------

install_github_release() {
  local tool_json="$1"
  local platform
  platform="$(detect_platform)"

  local name repo bin
  name="$(echo "$tool_json" | jq -r '.name')"
  repo="$(echo "$tool_json" | jq -r '.repo')"
  bin="$(echo "$tool_json" | jq -r '.bin')"

  local asset tag url
  asset="$(get_asset_name "$tool_json" "$platform")"
  tag="$(resolve_tag "$tool_json")"
  url="https://github.com/${repo}/releases/download/${tag}/${asset}"

  # archive フィールドを取得（null なら binary 扱い）
  local archive_json archive_type
  archive_json="$(echo "$tool_json" | jq -r '.archive // empty')"
  if [[ -z "$archive_json" ]]; then
    archive_type="binary"
  else
    archive_type="$(echo "$archive_json" | jq -r '.type')"
  fi

  section "${name} (${tag})"
  info "Repo:    ${repo}"
  info "Asset:   ${asset}"
  info "Archive: ${archive_type}"
  echo ""

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  info "Downloading..."
  curl -sfL -o "${tmpdir}/${asset}" "$url"

  mkdir -p "$BIN_DIR"

  case "$archive_type" in
  tar.gz | tgz)
    local install_dir strip bin_path
    install_dir="$(expand_vars "$(echo "$archive_json" | jq -r '.install_dir')")"
    strip="$(echo "$archive_json" | jq -r '.strip_components // 0')"
    bin_path="$(echo "$archive_json" | jq -r '.bin_path')"

    backup_existing "$install_dir"
    trap 'rollback "$install_dir"' ERR

    extract_tar_gz "${tmpdir}/${asset}" "$install_dir" "$strip"
    ln -sf "${install_dir}/${bin_path}" "${BIN_DIR}/${bin}"

    cleanup_backup "$install_dir"
    ;;

  gz)
    local dest="${BIN_DIR}/${bin}"
    backup_existing "$dest"
    trap 'rollback "$dest"' ERR

    extract_gz "${tmpdir}/${asset}" "$dest"

    cleanup_backup "$dest"
    ;;

  zip)
    local install_dir bin_path
    install_dir="$(expand_vars "$(echo "$archive_json" | jq -r '.install_dir')")"
    bin_path="$(echo "$archive_json" | jq -r '.bin_path')"

    backup_existing "$install_dir"
    trap 'rollback "$install_dir"' ERR

    extract_zip "${tmpdir}/${asset}" "$install_dir"
    ln -sf "${install_dir}/${bin_path}" "${BIN_DIR}/${bin}"

    cleanup_backup "$install_dir"
    ;;

  binary)
    local dest="${BIN_DIR}/${bin}"
    backup_existing "$dest"
    trap 'rollback "$dest"' ERR

    install_binary "${tmpdir}/${asset}" "$dest"

    cleanup_backup "$dest"
    ;;

  *)
    die "Unknown archive type: ${archive_type}"
    ;;
  esac

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

  curl -fsSL "$url" | sh

  info "Done."
  echo ""
}

# ---------------------------------------------------------------------------
# ディスパッチ
# ---------------------------------------------------------------------------

install_tool() {
  local name="$1"
  local tool_json
  tool_json="$(jq -c --arg n "$name" '.tools[] | select(.name == $n)' "$TOOLS_JSON")"

  if [[ -z "$tool_json" ]]; then
    die "Tool '${name}' not found in ${TOOLS_JSON}"
  fi

  local kind
  kind="$(echo "$tool_json" | jq -r '.kind')"

  case "$kind" in
  github_release) install_github_release "$tool_json" ;;
  installer) install_installer "$tool_json" ;;
  *) die "Unknown kind '${kind}' for tool '${name}'" ;;
  esac
}

install_all() {
  local names
  mapfile -t names < <(jq -r '.tools[].name' "$TOOLS_JSON")
  for name in "${names[@]}"; do
    install_tool "$name"
  done
}

list_tools() {
  printf "%-20s %-15s %s\n" "NAME" "KIND" "REPO / URL"
  printf "%-20s %-15s %s\n" "----" "----" "----------"
  jq -r '.tools[] | [.name, .kind, (.repo // .url // "-")] | @tsv' "$TOOLS_JSON" \
    | while IFS=$'\t' read -r name kind src; do
        printf "%-20s %-15s %s\n" "$name" "$kind" "$src"
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
  $(basename "$0")               # 全ツールをインストール
  $(basename "$0") neovim        # neovim のみインストール
  $(basename "$0") neovim tree-sitter
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
  -l | --list)
    list_tools
    ;;
  -h | --help)
    usage
    ;;
  -*)
    die "Unknown option: $1"
    ;;
  *)
    for name in "$@"; do
      install_tool "$name"
    done
    echo "Done. Make sure ${BIN_DIR} is in your PATH."
    ;;
  esac
}

main "$@"
