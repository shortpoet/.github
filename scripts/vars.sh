#!/usr/bin/env bash

owner='shortpoet'
# repo='tf-web'

get_repo_source_input_from_user() {
  read -r -p "Enter source name: " source_repo_input
  echo "$source_repo_input"
}

get_repo_target_input_from_user() {
  read -r -p "Enter target name: " target_repo_input
  echo "$target_repo_input"
}

source_repo="${1:-$(get_repo_source_input_from_user)}"

target_repo="${2:-$(get_repo_target_input_from_user)}"

echo "Copying vars from $source_repo to repo: $target_repo"

get_vars() {
  gh api "repos/$owner/$source_repo/actions/variables" --jq '.variables[] | [.name, .value] | @tsv'
  # gh api "repos/$owner/$source_repo/actions/variables" --jq '.variables[] | {name: .name, value: .value}'
}

set_var() {
  # echo "Setting var: $1"
  # echo "Setting value: $2"

  gh api "repos/$owner/$target_repo/actions/variables" -X POST -f "name=$1" -f "value=$2"
}

set_vars() {
  mapfile -t vars < <(get_vars)
  for var in "${vars[@]}"; do
    name=$(echo "$var" | awk '{print $1}')
    value=$(echo "$var" | awk '{print $2}')
    set_var "$name" "$value"
  done
}

set_vars