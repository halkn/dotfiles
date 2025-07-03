#!/bin/bash

# mise 管理スクリプト（インストール・更新対応）
# WSL Ubuntu環境用

set -euo pipefail

# 設定
INSTALL_DIR="$XDG_BIN_HOME"
BINARY_NAME="mise"
ARCH=$(uname -m)
OS="linux"

# 使用方法表示
show_usage() {
  echo "Usage: $0 [install|update|check|version]"
  echo "  install  - mise をインストール"
  echo "  update   - mise を最新版に更新"
  echo "  check    - 現在のバージョンと最新版を比較"
  echo "  version  - 現在インストールされているバージョンを表示"
  exit 1
}

# curl の存在確認
check_dependencies() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed." >&2
    echo "Please install curl first:" >&2
    echo "  sudo apt update && sudo apt install curl" >&2
    exit 1
  fi
}

# GitHub APIから最新バージョンを取得
get_latest_version() {
  echo "Fetching latest version from GitHub API..." >&2
  local latest_version
  local json_response

  json_response=$(curl -fsSL "https://api.github.com/repos/jdx/mise/releases/latest")

  if [ -z "$json_response" ]; then
    echo "Error: Failed to fetch data from GitHub API" >&2
    exit 1
  fi

  # JSONから tag_name を抽出（複数の方法でフォールバック）
  latest_version=$(echo "$json_response" | grep '"tag_name":' | head -n1 | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')

  # 別の方法でも試行
  if [ -z "$latest_version" ]; then
    latest_version=$(echo "$json_response" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
  fi

  # AWKを使った方法
  if [ -z "$latest_version" ]; then
    latest_version=$(echo "$json_response" | awk -F'"' '/"tag_name":/ {print $4; exit}')
  fi

  if [ -z "$latest_version" ]; then
    echo "Error: Failed to parse version from GitHub API response" >&2
    echo "Response preview: $(echo "$json_response" | head -c 200)..." >&2
    exit 1
  fi

  echo "$latest_version"
}

# 現在インストールされているバージョンを取得
get_current_version() {
  if [ -x "$INSTALL_DIR/$BINARY_NAME" ]; then
    "$INSTALL_DIR/$BINARY_NAME" --version 2>/dev/null | head -n1 | awk '{print $2}' || echo ""
  else
    echo ""
  fi
}

# アーキテクチャの判定
get_arch_suffix() {
  case $ARCH in
  x86_64)
    echo "x64"
    ;;
  aarch64 | arm64)
    echo "arm64"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
  esac
}

# mise をダウンロード・インストール
install_mise() {
  local version="$1"
  local arch_suffix
  arch_suffix=$(get_arch_suffix)

  local download_url="https://github.com/jdx/mise/releases/download/${version}/mise-${version}-${OS}-${arch_suffix}.tar.gz"
  local temp_dir
  temp_dir=$(mktemp -d)
  local tar_file="${temp_dir}/mise.tar.gz"

  echo "=== mise インストール ==="
  echo "Version: $version"
  echo "Architecture: $ARCH ($arch_suffix)"
  echo "Install Directory: $INSTALL_DIR"
  echo "Download URL: $download_url"
  echo

  # インストールディレクトリ作成
  mkdir -p "$INSTALL_DIR"

  # ダウンロード
  echo "Downloading mise binary..."
  curl -fsSL "$download_url" -o "$tar_file"

  # 展開とインストール
  echo "Extracting and installing..."
  cd "$temp_dir"
  tar -xzf "$tar_file"

  # バイナリをインストールディレクトリにコピー
  if [ -f "mise/bin/mise" ]; then
    cp "mise/bin/mise" "$INSTALL_DIR/$BINARY_NAME"
  elif [ -f "mise" ]; then
    cp "mise" "$INSTALL_DIR/$BINARY_NAME"
  else
    echo "Error: mise binary not found in archive"
    rm -rf "$temp_dir"
    exit 1
  fi

  # 実行権限付与
  chmod +x "$INSTALL_DIR/$BINARY_NAME"

  # クリーンアップ
  rm -rf "$temp_dir"

  # バージョン確認のため一時的にホームディレクトリに移動
  local original_pwd="$PWD"
  cd "$HOME"

  echo "✓ Installation successful!"
  if "$INSTALL_DIR/$BINARY_NAME" --version >/dev/null 2>&1; then
    echo "Installed version: $("$INSTALL_DIR/$BINARY_NAME" --version | head -n1)"
  else
    echo "Installed version: (version check failed, but binary is installed)"
  fi

  # 元のディレクトリに戻る（存在する場合のみ）
  if [ -d "$original_pwd" ]; then
    cd "$original_pwd"
  fi
}

# バージョン比較（セマンティックバージョニング対応）
version_compare() {
  local current="$1"
  local latest="$2"

  # vプレフィックスを除去
  current="${current#v}"
  latest="${latest#v}"

  if [ "$current" = "$latest" ]; then
    return 0 # 同じ
  fi

  # バージョン文字列を数値として比較
  # 例: 2024.6.6 と 2024.6.7 を比較
  local current_parts latest_parts
  local max_parts=3

  # 配列への安全な分割
  IFS='.' read -ra current_parts <<<"$current"
  IFS='.' read -ra latest_parts <<<"$latest"

  # 各部分を比較
  for i in $(seq 0 $((max_parts - 1))); do
    local current_part="${current_parts[$i]:-0}"
    local latest_part="${latest_parts[$i]:-0}"

    # 数値として比較
    if [ "$current_part" -lt "$latest_part" ]; then
      return 1 # 更新が必要
    elif [ "$current_part" -gt "$latest_part" ]; then
      return 0 # 現在の方が新しい
    fi
  done

  return 0 # 同じ
}

# メイン処理
main() {
  # 依存関係チェック
  check_dependencies

  local command="${1:-install}"

  case "$command" in
  "install")
    local latest_version
    latest_version=$(get_latest_version)
    install_mise "$latest_version"

    # PATH設定の確認
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
      echo
      echo "Warning: $INSTALL_DIR is not in your PATH"
      echo "Add the following line to your ~/.bashrc or ~/.zshrc:"
      echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    echo
    echo "Next steps:"
    echo "1. Add mise to your shell profile:"
    echo "   echo 'eval \"\$(mise activate bash)\"' >> ~/.bashrc"
    echo "   # or for zsh: echo 'eval \"\$(mise activate zsh)\"' >> ~/.zshrc"
    echo "2. Reload your shell: source ~/.bashrc"
    ;;

  "update")
    local current_version
    local latest_version

    current_version=$(get_current_version)
    if [ -z "$current_version" ]; then
      echo "mise is not installed. Use 'install' command first."
      exit 1
    fi

    latest_version=$(get_latest_version)

    if version_compare "$current_version" "$latest_version"; then
      echo "mise is already up to date (v$current_version)"
    else
      echo "Updating mise from v$current_version to $latest_version"
      install_mise "$latest_version"
    fi
    ;;

  "check")
    local current_version
    local latest_version

    current_version=$(get_current_version)
    latest_version=$(get_latest_version)

    if [ -z "$current_version" ]; then
      echo "mise is not installed"
      echo "Latest version: $latest_version"
    elif version_compare "$current_version" "$latest_version"; then
      echo "✓ mise is up to date"
      echo "Current version: v$current_version"
    else
      echo "Update available!"
      echo "Current version: v$current_version"
      echo "Latest version:  $latest_version"
      echo "Run '$0 update' to update"
    fi
    ;;

  "version")
    local current_version
    current_version=$(get_current_version)
    if [ -z "$current_version" ]; then
      echo "mise is not installed"
      exit 1
    else
      echo "v$current_version"
    fi
    ;;

  *)
    show_usage
    ;;
  esac
}

# スクリプト実行
main "$@"
