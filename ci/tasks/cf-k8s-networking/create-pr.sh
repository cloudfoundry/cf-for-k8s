#!/usr/bin/env bash
set -euo pipefail

# ENV
: "${GITHUB_KEY:?}"
: "${GITHUB_TITLE:?}"
: "${GITHUB_BODY:?}"
: "${BRANCH:?}"

# Replace newlines with the two characters '\n'.
# This allows the $GITHUB_BODY in the pipeline to be pretty.
sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$GITHUB_BODY" > github_body

echo "Creating PR"
pull=$(curl \
  -sS \
  --fail \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_KEY}" \
  https://api.github.com/repos/cloudfoundry/cf-for-k8s/pulls \
  -d '{
    "head":"'"$BRANCH"'",
    "base":"develop",
    "maintainer_can_modify": true,
    "title": "'"$GITHUB_TITLE"'",
    "body": "'"$(cat github_body)"'"
  }')

pull_number="$(echo "${pull}" | jq -r '.number')"

echo "PR number is $pull_number"
# Add networking label to run our CI job for tests
curl \
  --fail \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_KEY}" \
  "https://api.github.com/repos/cloudfoundry/cf-for-k8s/issues/${pull_number}/labels" \
  -d '{"labels":["networking"]}'

echo "DONE"
