#!/usr/bin/env bash

# Unofficial Bash Strict Mode
set -efuo pipefail
IFS=$'\n\t'

DEPLOY_ENV="staging"

fail_github_deploy_status() {
  # Create a "deployment status" at GitHub: "failure"
  # shellcheck disable=2154
  curl \
    --silent --show-error \
    --fail \
    --user "${GITHUB_ACCESS_TOKEN}" \
    --header "Accept: application/vnd.github.v3+json" \
    --header "Content-Type: application/json" \
    --data '{"state": "failure"}' \
    "https://api.github.com/repos/tomwassenberg/test-deployments/deployments/${DEPLOY_ID}/statuses"
}

NEW_GIT_REF="$(git rev-parse --short HEAD)"

DEPLOY_DESCRIPTION="Deploying commit ${NEW_GIT_REF} on top of old commit X."

# Create a "deployment" at GitHub and save its ID
DEPLOY_ID="$(curl \
  --silent --show-error \
  --fail \
  --user "${GITHUB_ACCESS_TOKEN}" \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Content-Type: application/json" \
  --data \
  '{"ref": "'"${NEW_GIT_REF}"'",
      "auto_merge": false,
      "required_contexts": [],
      "description": "'"${DEPLOY_DESCRIPTION}"'",
      "environment": "'"${DEPLOY_ENV}"'"}' \
  https://api.github.com/repos/tomwassenberg/test-deployments/deployments |
  jq --raw-output .id)"

trap fail_github_deploy_status ERR

echo "do website building stuff"
/bin/true

# Create a "deployment status" at GitHub: "success"
curl \
  --silent --show-error \
  --fail \
  --user "${GITHUB_ACCESS_TOKEN}" \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Content-Type: application/json" \
  --data '{"state": "success"}' \
  "https://api.github.com/repos/tomwassenberg/test-deployments/deployments/${DEPLOY_ID}/statuses"
