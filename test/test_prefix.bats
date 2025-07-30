#!/usr/bin/env bats
export BATS_LIB_PATH=${BATS_LIB_PATH:-"/usr/lib"}
bats_load_library bats-support
bats_load_library bats-assert

setup() {
  TMP=$(mktemp -d)
  cd "$TMP"
  git init -b main >/dev/null
  git config user.name "Test"
  git config user.email "test@example.com"
  touch README && git add README && git commit -m "initial" >/dev/null

  SOURCE="../../../../..$(pwd)" # Workaround for "GITHUB_WORKSPACE" prefix in script
}

teardown() {
  rm -rf "$TMP"
}

run_entry() {
  bash "$BATS_TEST_DIRNAME/../entrypoint.sh"
}

@test "Creates a new tag with default settings (no prefix)" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag 0.0.0 - New tag 0.1.0"
}

@test "Bumps a tag with default settings (no prefix)" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"
  git tag "1.0.0" && git commit -m "bump" --allow-empty >/dev/null

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag 1.0.0 - New tag 1.1.0"
}

@test "Creates a new tag with 'v' prefix" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"
  export TAG_PREFIX="v"

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag v0.0.0 - New tag v0.1.0"
}

@test "Bumps a tag with 'v' prefix" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"
  export TAG_PREFIX="v"
  git tag "v1.0.0" && git commit -m "bump" --allow-empty >/dev/null

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag v1.0.0 - New tag v1.1.0"
}

@test "Creates a new tag with '/' prefix" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"
  export TAG_PREFIX="infra/"

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag infra/0.0.0 - New tag infra/0.1.0"
}

@test "Bumps a tag with '/' prefix" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"
  export TAG_PREFIX="infra/"
  git tag "infra/1.0.0" && git commit -m "bump" --allow-empty >/dev/null

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag infra/1.0.0 - New tag infra/1.1.0"
}

@test "Bumps only matching prefix tag" {
  # Arrange
  export SOURCE="$SOURCE"
  export DRY_RUN="true"
  export TAG_PREFIX="infra/"
  git tag "2.0.0" && git commit -m "bump-no-prefix-1" --allow-empty >/dev/null
  git tag "infra/1.7.0" && git commit -m "bump-prefix-1" --allow-empty >/dev/null
  git tag "2.1.0" && git commit -m "bump-no-prefix-2" --allow-empty >/dev/null

  # Act
  run run_entry

  # Assert
  assert_success
  assert_line "Bumping tag infra/1.7.0 - New tag infra/1.8.0"
  refute_line "Bumping tag 2.1.0 - New tag 2.2.0"
}