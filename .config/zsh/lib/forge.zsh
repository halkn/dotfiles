# forge - what the remote hosting knows about the repository you are standing
# in: the open pull requests and the branch one of them is proposing.
#
# GitHub only, because `gh` is the only forge CLI that answers without being
# told an organisation and a project first. The repository-level settings and
# the clone URLs live in `repo` (bin/repo), which is a command rather than a
# library so that it can leave this repository.

_forge_pr_rows() {
  gh pr list --limit 100 \
    --json number,title,headRefName,author \
    --template '{{range .}}{{printf "#%-5v %-50.50v %v (@%v)\t%v\n" .number .title .headRefName .author.login .number}}{{end}}'
}

_forge_pr_head() {
  gh pr view "${1:-}" --json headRefName --jq '.headRefName'
}
