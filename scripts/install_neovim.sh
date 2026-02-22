#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
NVIM_HOME="${HOME}/.local/opt/neovim"

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  echo "${os}-${arch}"
}

# --- neovim ---

nvim_asset_name() {
  case "$(detect_platform)" in
  Linux-x86_64) echo "nvim-linux-x86_64.tar.gz" ;;
  Darwin-arm64) echo "nvim-macos-arm64.tar.gz" ;;
  Darwin-x86_64) echo "nvim-macos-x86_64.tar.gz" ;;
  *)
    echo "Unsupported platform: $(detect_platform)" >&2
    return 1
    ;;
  esac
}

nvim_current_version() {
  if [[ -x "${NVIM_HOME}/bin/nvim" ]]; then
    local out
    out="$("${NVIM_HOME}/bin/nvim" --version)"
    echo "${out%%$'\n'*}"
  else
    echo "not installed"
  fi
}

install_neovim() {
  local asset url tmpdir
  asset="$(nvim_asset_name)"
  url="https://github.com/neovim/neovim/releases/download/nightly/${asset}"

  echo "=== neovim (nightly) ==="
  echo "Current: $(nvim_current_version)"
  echo "Asset:   ${asset}"
  echo ""

  tmpdir="$(mktemp -d)"

  echo "Downloading..."
  curl -sfL -o "${tmpdir}/${asset}" "${url}"

  if [[ -d "${NVIM_HOME}" ]]; then
    mv "${NVIM_HOME}" "${NVIM_HOME}.bak"
  fi

  mkdir -p "${NVIM_HOME}"
  tar xzf "${tmpdir}/${asset}" -C "${NVIM_HOME}" --strip-components=1
  rm -rf "${NVIM_HOME}.bak"

  mkdir -p "${BIN_DIR}"
  ln -sf "${NVIM_HOME}/bin/nvim" "${BIN_DIR}/nvim"
  rm -rf "${tmpdir}"

  echo "Installed: $(nvim_current_version)"
  echo ""
}

# --- tree-sitter ---

ts_asset_name() {
  case "$(detect_platform)" in
  Linux-x86_64) echo "tree-sitter-linux-x64.gz" ;;
  Darwin-arm64) echo "tree-sitter-macos-arm64.gz" ;;
  Darwin-x86_64) echo "tree-sitter-macos-x64.gz" ;;
  *)
    echo "Unsupported platform: $(detect_platform)" >&2
    return 1
    ;;
  esac
}

ts_current_version() {
  if [[ -x "${BIN_DIR}/tree-sitter" ]]; then
    "${BIN_DIR}/tree-sitter" --version 2>/dev/null || echo "unknown"
  else
    echo "not installed"
  fi
}

ts_latest_tag() {
  local response
  response="$(curl -sfL "https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest")"
  echo "${response}" | grep -m1 '"tag_name"' | cut -d'"' -f4
}

install_tree_sitter() {
  local asset tag url tmpdir
  asset="$(ts_asset_name)"
  tag="$(ts_latest_tag)"
  url="https://github.com/tree-sitter/tree-sitter/releases/download/${tag}/${asset}"

  echo "=== tree-sitter (latest: ${tag}) ==="
  echo "Current: $(ts_current_version)"
  echo "Asset:   ${asset}"
  echo ""

  tmpdir="$(mktemp -d)"

  echo "Downloading..."
  curl -sfL -o "${tmpdir}/${asset}" "${url}"

  mkdir -p "${BIN_DIR}"
  gunzip -c "${tmpdir}/${asset}" >"${BIN_DIR}/tree-sitter"
  chmod +x "${BIN_DIR}/tree-sitter"
  rm -rf "${tmpdir}"

  echo "Installed: $(ts_current_version)"
  echo ""
}

# --- main ---

install_neovim
install_tree_sitter

echo "Done. Make sure ${BIN_DIR} is in your PATH."
