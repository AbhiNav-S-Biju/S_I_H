#!/usr/bin/env bash
# Uses the OAuth token already stored by git-credential-manager to report CI
# status, and to print the failing log for the newest run when asked.
set -u
export PATH=/c/Users/Abhinav/SIH/ghtmp/bin:$PATH
export GH_PAGER=cat

printf 'protocol=https\nhost=github.com\n' | git credential fill 2>/dev/null \
  | sed -n 's/^password=//p' > "$HOME/.gh_tok"
export GH_TOKEN=$(cat "$HOME/.gh_tok")
trap 'rm -f "$HOME/.gh_tok"' EXIT

echo "=== Recent runs ==="
gh run list --repo AbhiNav-S-Biju/S_I_H --limit 5 \
  --json name,status,conclusion,event,displayTitle \
  --template '{{range .}}{{.name}} | {{.status}} | {{.conclusion}} | {{.event}} | {{.displayTitle}}{{"\n"}}{{end}}'

echo
echo "=== Releases ==="
gh release list --repo AbhiNav-S-Biju/S_I_H 2>&1 | head -10

if [ "${1:-}" = "--logs" ]; then
  RUN_ID=$(gh run list --repo AbhiNav-S-Biju/S_I_H --workflow release-apk.yml \
    --limit 1 --json databaseId --jq '.[0].databaseId')
  echo
  echo "=== Failed log for run $RUN_ID ==="
  gh run view "$RUN_ID" --repo AbhiNav-S-Biju/S_I_H --log-failed 2>&1 | tail -40
fi
