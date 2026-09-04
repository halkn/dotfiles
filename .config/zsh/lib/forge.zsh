# forge - what the remote hosting knows: the URL a spec clones from, the
# repositories of your own account, the open pull requests of the repository you
# stand in, and the settings a repository is expected to carry.
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

# ── repository settings ──────────────────────────────

# The ruleset guarding the default branch, as the body of
# POST/PUT /repos/{owner}/{repo}/rulesets.
#
# `bypass_actors` is empty on purpose. An agent runs under the same ssh key and
# the same gh token as the person who started it, so an admin bypass would be a
# bypass for both; an exception has to be a deliberate visit to the ruleset in
# the web UI. The approval count is 0 because a lone owner cannot approve their
# own pull request - what is being enforced is that a change arrives as one.
#
# Not included: `required_linear_history`, which contradicts the merge commits
# this account's repositories carry, and `required_status_checks`, which needs a
# check to name.
_forge_ruleset_payload() {
  cat <<'JSON'
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    }
  ]
}
JSON
}

# The id of the ruleset named above, empty when the repository has none. The
# list endpoint answers with names and ids only, so the rules themselves need
# the per-ruleset endpoint.
_forge_ruleset_id() {
  gh api "repos/${1:-}/rulesets" --jq '.[] | select(.name == "main") | .id'
}

_forge_apply_ruleset() {
  local nwo=${1:-} id
  id=$(_forge_ruleset_id "$nwo") || return 1
  if [[ -n $id ]]; then
    _forge_ruleset_payload | gh api --silent --method PUT "repos/$nwo/rulesets/$id" --input -
  else
    _forge_ruleset_payload | gh api --silent --method POST "repos/$nwo/rulesets" --input -
  fi
}

# Push protection is the one that acts before the damage: a secret in a commit
# is rejected at push time rather than reported after it has been published.
# Wiki and projects are turned off as surface nothing here uses.
_forge_apply_repo_settings() {
  gh api --silent --method PATCH "repos/${1:-}" --input - <<'JSON'
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  },
  "allow_auto_merge": true,
  "allow_update_branch": true,
  "delete_branch_on_merge": true,
  "has_wiki": false,
  "has_projects": false
}
JSON
}

_forge_apply_dependabot() {
  local nwo=${1:-} rc=0
  gh api --silent --method PUT "repos/$nwo/vulnerability-alerts" || rc=1
  gh api --silent --method PUT "repos/$nwo/automated-security-fixes" || rc=1
  return $rc
}

# What the settings above currently are. The ruleset it writes has no bypass
# actor, so applying it takes away the caller's own push to the default branch:
# the current state has to be readable before that happens.
_forge_settings_report() {
  local nwo=${1:-} id
  gh api "repos/$nwo" --jq '
    "repository:  \(.full_name) (\(if .private then "private" else "public" end))",
    "  default branch:          \(.default_branch)",
    "  secret scanning:         \(.security_and_analysis.secret_scanning.status // "n/a")",
    "  push protection:         \(.security_and_analysis.secret_scanning_push_protection.status // "n/a")",
    "  dependabot alerts:       \(.security_and_analysis.dependabot_security_updates.status // "n/a")",
    "  allow_auto_merge:        \(.allow_auto_merge)",
    "  allow_update_branch:     \(.allow_update_branch)",
    "  delete_branch_on_merge:  \(.delete_branch_on_merge)",
    "  has_wiki / has_projects: \(.has_wiki) / \(.has_projects)"
  ' || return 1

  id=$(_forge_ruleset_id "$nwo") || return 1
  if [[ -z $id ]]; then
    print -r -- '  ruleset "main":          (none)'
    return 0
  fi
  gh api "repos/$nwo/rulesets/$id" --jq '
    "  ruleset \"\(.name)\":          \(.enforcement), \(.bypass_actors | length) bypass actor(s)",
    "    rules:                 \(.rules | map(.type) | join(", "))"
  '
}
