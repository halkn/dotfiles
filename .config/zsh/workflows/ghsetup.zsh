# ghsetup - the GitHub-side settings every repository of this account is meant
# to carry: a ruleset guarding the default branch, secret scanning with push
# protection, and the merge behaviour. What each setting is and why lives in
# lib/forge.zsh.
#
# A personal account has no way to make these apply to repositories that do not
# exist yet - rulesets are scoped to a repository or to an organisation, and the
# organisation-wide target needs a paid plan - so this command is what stands in
# for that, run once after `gh repo create`.
#
# Functions are always defined; the entry point checks its own dependencies, so
# a machine without gh reports what is missing instead of `command not found`.

_GHSETUP_LIB=${${(%):-%x}:A}

for _ghsetup_part in ui forge; do
  source "${${_GHSETUP_LIB:h}:h}/lib/$_ghsetup_part.zsh"
done
unset _ghsetup_part

_ghsetup_usage() {
  print -r -- 'usage: ghsetup [--dry-run] [<owner>/<repo>]'
}

# The ruleset carries no bypass actor, so applying it takes away the caller's own
# push to the default branch. --dry-run is how that is seen coming.
ghsetup() {
  local nwo= arg
  local -i dry_run=0 rc=0

  for arg in "$@"; do
    case $arg in
      --dry-run)
        dry_run=1
        ;;
      -h | --help)
        _ghsetup_usage
        return 0
        ;;
      -*)
        print -u2 "ghsetup: unknown option: $arg"
        _ghsetup_usage >&2
        return 1
        ;;
      *)
        if [[ -n $nwo ]]; then
          print -u2 'ghsetup: expected at most one repository'
          _ghsetup_usage >&2
          return 1
        fi
        nwo=$arg
        ;;
    esac
  done

  _ui_require gh ghsetup || return 1

  if [[ -z $nwo ]]; then
    nwo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner') || return 1
  fi
  if [[ $nwo != */* ]]; then
    print -u2 "ghsetup: expected <owner>/<repo>, got '$nwo'"
    return 1
  fi

  if ((dry_run)); then
    _forge_settings_report "$nwo"
    return
  fi

  _forge_apply_ruleset "$nwo" || rc=1
  _forge_apply_repo_settings "$nwo" || rc=1
  _forge_apply_dependabot "$nwo" || rc=1
  ((rc == 0)) || return $rc
  _forge_settings_report "$nwo"
}
