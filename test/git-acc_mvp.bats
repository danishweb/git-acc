#!/usr/bin/env bats

setup() {
  # Isolate HOME so we don't touch the runner's real home
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Use the repo's bin directly; no copy needed
  PATH="$PWD/bin:$PATH"

  # Optional: isolate global git config so tests don't see runner's config
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
}

teardown() {
  rm -rf "$HOME"
}

@test "add creates account file" {
  run git-acc add personal "Jane Dev" "jane@example.com"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.git-accounts/personal.conf" ]
}

@test "list shows created account" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  run git-acc list
  [ "$status" -eq 0 ]
  [[ "$output" == *"personal"* ]]
}

@test "show prints account contents" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  run git-acc show personal
  [ "$status" -eq 0 ]
  [[ "$output" == *'NAME="Jane Dev"'* ]]
  [[ "$output" == *'EMAIL="jane@example.com"'* ]]
}
