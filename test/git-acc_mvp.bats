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

@test "add creates account file and SSH key" {
  run git-acc add personal "Jane Dev" "jane@example.com"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.git-accounts/personal.conf" ]
  [ -f "$HOME/.ssh/id_ed25519_personal" ]
  [ -f "$HOME/.ssh/id_ed25519_personal.pub" ]
}

@test "add creates SSH config entry" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  [ -f "$HOME/.ssh/config" ]
  run grep "Host github.com-personal" "$HOME/.ssh/config"
  [ "$status" -eq 0 ]
}

@test "add prevents duplicate accounts" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  run git-acc add personal "Jane Dev" "jane@example.com"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists"* ]]
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

@test "use switches to account" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  echo "y" | git-acc use personal >/dev/null
  run git-acc current
  [ "$status" -eq 0 ]
  [[ "$output" == *"personal"* ]]
  [[ "$output" == *"Jane Dev"* ]]
}

@test "current shows no account when none active" {
  run git-acc current
  [ "$status" -eq 0 ]
  [[ "$output" == *"No account currently active"* ]]
}

@test "remove deletes account and files" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  echo "y" | git-acc remove personal >/dev/null
  [ ! -f "$HOME/.git-accounts/personal.conf" ]
  [ ! -f "$HOME/.ssh/id_ed25519_personal" ]
  [ ! -f "$HOME/.ssh/id_ed25519_personal.pub" ]
}

@test "remove clears current account if it was removed" {
  git-acc add personal "Jane Dev" "jane@example.com" >/dev/null
  echo "y" | git-acc use personal >/dev/null
  echo "y" | git-acc remove personal >/dev/null
  run git-acc current
  [ "$status" -eq 0 ]
  [[ "$output" == *"No account currently active"* ]]
}
