# forge - what the remote hosting knows: the URL a spec clones from, the
# repositories of your own account, the open pull requests, and the settings a
# repository is expected to carry.
#
# GitHub is the only forge with a listing here, because `gh` is the only one
# that answers without being told an organisation and a project first. An Azure
# Repos URL still clones, since that path asks the forge nothing.

# A spec carrying a `:` already names a host the way git reads it and is passed
# through untouched.
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

# gh's own failure - not logged in, offline, rate limited - is what has to be
# read, so the caller fetches this before opening a picker rather than through a
# pipe fzf would paint over.
_forge_repo_list() {
  gh repo list --limit 200 --json nameWithOwner --jq '.[].nameWithOwner'
}

# The listing is what is on GitHub, so a clone already under $1 is marked rather
# than dropped: picking it is still a way to get to it. The root is passed in
# because where a clone lands is checkout.zsh's, and lib files do not reach into
# each other.
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

_forge_pr_rows() {
  gh pr list --limit 100 \
    --json number,title,headRefName,author \
    --template '{{range .}}{{printf "#%-5v %-50.50v %v (@%v)\t%v\n" .number .title .headRefName .author.login .number}}{{end}}'
}

_forge_pr_head() {
  gh pr view "${1:-}" --json headRefName --jq '.headRefName'
}

# ── repository settings ──────────────────────────────

# `bypass_actors` is empty on purpose. An agent runs under the same ssh key and
# the same gh token as the person who started it, so an admin bypass would be a
# bypass for both; an exception has to be a deliberate visit to the ruleset in
# the web UI. The approval count is 0 because a lone owner cannot approve their
# own pull request - what is being enforced is that a change arrives as one.
#
# Not included: `required_linear_history`, which contradicts the merge commits
# this account's repositories carry, and `required_status_checks`, which needs a
# check to name.
#
# The name is a variable because _forge_ruleset_id finds the ruleset to update by
# it: written twice, a rename would silently turn an update into a second,
# overlapping ruleset. The JSON below holds no other expansion.
_FORGE_RULESET_NAME=main

_forge_ruleset_payload() {
  cat <<JSON
{
  "name": "$_FORGE_RULESET_NAME",
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

# `includes_parents` defaults to true, which mixes in the organisation and
# enterprise rulesets that also apply here. Those ids belong to another owner:
# updating one is refused, and the repository would be left with no ruleset of
# its own.
_forge_ruleset_id() {
  gh api "repos/${1:-}/rulesets?includes_parents=false&per_page=100" \
    --jq "[.[] | select(.name == \"$_FORGE_RULESET_NAME\") | .id] | first // empty"
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

# Two PATCHes rather than one: the endpoint applies a body atomically, and
# secret scanning needs an eligible repository (public, or private with Secret
# Protection). Sent together, a private repository on a plan without it would
# lose the merge settings to the same rejection.
_forge_apply_repo_settings() {
  local nwo=${1:-} rc=0
  gh api --silent --method PATCH "repos/$nwo" --input - <<'JSON' || rc=1
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
JSON
  gh api --silent --method PATCH "repos/$nwo" --input - <<'JSON' || rc=1
{
  "allow_auto_merge": true,
  "allow_update_branch": true,
  "delete_branch_on_merge": true,
  "has_wiki": false,
  "has_projects": false
}
JSON
  return $rc
}

_forge_apply_dependabot() {
  local nwo=${1:-} rc=0
  gh api --silent --method PUT "repos/$nwo/vulnerability-alerts" || rc=1
  gh api --silent --method PUT "repos/$nwo/automated-security-fixes" || rc=1
  return $rc
}

# Dependabot alerts are absent because this endpoint reports the security
# updates only; the alerts answer on their own endpoint with a status code.
_forge_settings_report() {
  local nwo=${1:-} id
  gh api "repos/$nwo" --jq '
    "repository:  \(.full_name) (\(if .private then "private" else "public" end))",
    "  default branch:          \(.default_branch)",
    "  secret scanning:         \(.security_and_analysis.secret_scanning.status // "n/a")",
    "  push protection:         \(.security_and_analysis.secret_scanning_push_protection.status // "n/a")",
    "  dependabot updates:      \(.security_and_analysis.dependabot_security_updates.status // "n/a")",
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
