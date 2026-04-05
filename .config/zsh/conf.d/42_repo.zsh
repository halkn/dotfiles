repo() {
  local root=$HOME/dev
  local cmd="${1:-cd}"; shift

  case "$cmd" in
    get)
      local url="$1"
      [[ -z "$url" ]] && { echo "usage: repo get <url|owner/repo>" >&2; return 1; }

      local host owner name dest

      case "$url" in
        *dev.azure.com*)
          host="dev.azure.com"
          local path="${url#*dev.azure.com/}"
          path="${path#*@dev.azure.com/}"
          local org="${path%%/*}"; path="${path#*/}"
          local project="${path%%/*}"; path="${path#*/}"
          path="${path#_git/}"
          name="${path%%/*}"
          dest=$root/$host/$org/$project/$name
          ;;
        https://*)
          local stripped="${url#https://}"
          host="${stripped%%/*}"; stripped="${stripped#*/}"
          owner="${stripped%%/*}"; stripped="${stripped#*/}"
          name="${stripped%%/*}"; name="${name%.git}"
          dest=$root/$host/$owner/$name
          ;;
        git@*)
          local stripped="${url#git@}"
          host="${stripped%%:*}"; stripped="${stripped#*:}"
          owner="${stripped%%/*}"; name="${stripped#*/}"; name="${name%.git}"
          dest=$root/$host/$owner/$name
          ;;
        */*)
          host="github.com"
          owner="${url%%/*}"; name="${url#*/}"; name="${name%.git}"
          dest=$root/$host/$owner/$name
          url="https://github.com/$owner/$name"
          ;;
        *)
          echo "repo get: cannot parse '$url'" >&2; return 1
          ;;
      esac

      if [[ -d "$dest/.git" ]]; then
        echo "already exists: $dest"
        return 0
      fi
      mkdir -p "${dest:h}"
      git clone "$url" "$dest"
      ;;

    list)
      find $root -maxdepth 5 -name ".git" -type d \
        | sed "s|$root/||; s|/.git$||" \
        | sort
      ;;

    cd)
      command -v fzf &>/dev/null || return
      local rel
      rel=$(repo list | fzf)
      [[ -z "$rel" ]] && return
      cd $root/$rel && la
      ;;

    *)
      echo "usage: repo <get|list|cd>" >&2; return 1
      ;;
  esac
}
