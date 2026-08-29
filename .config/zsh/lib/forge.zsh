# forge - what the remote hosting knows: the URL a spec clones from, the
# repositories of your own account, and the open pull requests of the
# repository you stand in.
#
# GitHub is the only forge with a listing here, because `gh` is the only one
# that answers without being told an organisation and a project first. An Azure
# Repos URL still clones: that path goes through _ck_repo_dest and the URL below,
# neither of which asks the forge anything.

# What git is handed to clone from. A spec carrying a `:` already names a host
# the way git reads it - a scheme or the scp-like `git@host:path` - and is passed
# through; a bare path is https, with the first segment read as a host when it
# looks like one and as a GitHub owner when it does not.
_forge_url() {
  local spec=${1:-}
  case $spec in
    *:*)
      print -r -- "$spec"
      ;;
    */*)
      if [[ ${spec%%/*} == *.* ]]; then
        print -r -- "https://$spec"
      else
        print -r -- "https://github.com/$spec"
      fi
      ;;
    *)
      print -r -- "$spec"
      ;;
  esac
}

# Your repositories on GitHub, one `<owner>/<repo>` per line. gh's own failure -
# not logged in, offline, rate limited - is what has to be read, so the caller
# fetches this before opening a picker rather than through a pipe fzf would
# paint over.
_forge_repo_list() {
  gh repo list --limit 200 --json nameWithOwner --jq '.[].nameWithOwner'
}

# `<display>\t<owner/repo>` for the picker, given the clone root as $1. The
# listing is what is on GitHub, so the clones already under that root are marked
# rather than dropped: picking one is still a way to get to it. The mark is a
# path test, which keeps the list free of a process per row. The root is passed
# in rather than read here, since where a clone lands is checkout.zsh's and lib
# files do not reach into each other.
_forge_repo_rows() {
  local root=${1:-} nwo
  shift
  for nwo in "$@"; do
    if [[ -n $root && -d $root/github.com/$nwo ]]; then
      printf '✓ %s\t%s\n' "$nwo" "$nwo"
    else
      printf '  %s\t%s\n' "$nwo" "$nwo"
    fi
  done
  return 0
}

# `<display>\t<number>` for the picker.
_forge_pr_rows() {
  gh pr list --limit 100 \
    --json number,title,headRefName,author \
    --template '{{range .}}{{printf "#%-5v %-50.50v %v (@%v)\t%v\n" .number .title .headRefName .author.login .number}}{{end}}'
}

_forge_pr_head() {
  gh pr view "${1:-}" --json headRefName --jq '.headRefName'
}
