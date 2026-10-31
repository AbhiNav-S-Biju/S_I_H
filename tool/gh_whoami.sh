#!/usr/bin/env bash
# Reports which GitHub account the stored credential authenticates as, and
# whether it can see the repo we have been pushing to.
set -u
export PATH=/c/Users/Abhinav/SIH/ghtmp/bin:$PATH
export GH_PAGER=cat

printf 'protocol=https\nhost=github.com\n' | git credential fill 2>/dev/null \
  | sed -n 's/^password=//p' > "$HOME/.gh_tok"
export GH_TOKEN=$(cat "$HOME/.gh_tok")
trap 'rm -f "$HOME/.gh_tok"' EXIT

echo "=== Credential identity ==="
gh api user --jq '"login=\(.login)  name=\(.name)  id=\(.id)  url=\(.html_url)"' 2>&1

echo
echo "=== Is 'Abhizz-droid' the authenticated account? ==="
ME=$(gh api user --jq '.login' 2>/dev/null)
if [ "$ME" = "Abhizz-droid" ] || [ "$ME" = "abhizz-droid" ]; then
  echo "yes"
else
  echo "no - authenticated as '$ME'"
fi

echo
echo "=== What does the repo say? ==="
gh api repos/AbhiNav-S-Biju/S_I_H \
  --jq '"full_name=\(.full_name)  owner=\(.owner.login) (id \(.owner.id), \(.owner.type))  private=\(.private)"' 2>&1

echo
echo "=== Contributors to the repo ==="
gh api repos/AbhiNav-S-Biju/S_I_H/contributors \
  --jq '.[] | "\(.login)  contributions=\(.contributions)"' 2>&1

echo
echo "=== Commit authors on main ==="
gh api repos/AbhiNav-S-Biju/S_I_H/commits --jq '.[] | "\(.commit.author.name) <\(.commit.author.email)>  \((.author.login // "no-linked-account"))"' 2>&1 | sort -u | head -20
