#!/usr/bin/env bash

owner='shortpoet'
# repo='tf-web'

get_repo_input_from_user() {
  read -r -p "Enter repo name: " repo_input
  echo "$repo_input"
}

repo="${1:-$(get_repo_input_from_user)}"

echo "Adding secrets to repo: $repo"

get_secrets() {
  # gh api "repos/$owner/$repo/actions/secrets/$1" | jq -r '.value'
  gh secret list -R "$owner/$repo" #| grep "$1" | awk '{print $2}'
}

# get_secrets

set_secret() {
  gh secret set -R "$owner/$repo" "$1" < "$2"
}

set_secrets() {
  set_secret AWS_ACCESS_KEY_ID <(pass Cloud/aws/soriano.carlitos/terraform-user/access_key_id)
  set_secret AWS_SECRET_ACCESS_KEY <(pass Cloud/aws/soriano.carlitos/terraform-user/secret_access_key)
  set_secret CLOUDFLARE_API_TOKEN <(pass Cloud/cloudflare/Github_Token)
  set_secret AWS_ROLE_TO_ASSUME <(pass Cloud/aws/soriano.carlitos/terraform-admin/role-arn)
}

set_secrets