#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

node_version="20"
mock_hooks_path="$PWD/hooks"

setup() {
  export BUILDKITE_JOB_ID=0
  export BUILDKITE_PULL_REQUEST_BASE_BRANCH="main"
  export BUILDKITE_REPO="git://github.com/owner/repo.git"
  export BUILDKITE_PULL_REQUEST="1023"
  export BUILDKITE_PLUGIN_COMMITLINT_GITHUB_TOKEN="pat_token1931=e18e128912012e9129"
  export BUILDKITE_PLUGINS_PATH="/var/lib/buildkite-agent/plugins"
}

@test "Fails when missing required GITHUB_TOKEN" {
  export BUILDKITE_PLUGIN_COMMITLINT_GITHUB_TOKEN=""

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing GitHub access token"
}

@test "Skips build that is not a pull request" {
  export BUILDKITE_PULL_REQUEST_BASE_BRANCH=""

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "No Pull Request detected"
  assert_output --partial "Skipping Commitlint plugin as it is only intended to run against Pull Request builds"
}

@test "Command succeeds" {
  stub docker \
    "run -e BUILDKITE_REPO -e BUILDKITE_PULL_REQUEST -e BUILDKITE_PLUGIN_COMMITLINT_GITHUB_TOKEN --label "com.buildkite.job-id=${BUILDKITE_JOB_ID}" --workdir=/workdir --volume=$(pwd):/workdir --volume=$mock_hooks_path:/hooks -it --rm public.ecr.aws/docker/library/node:$node_version /bin/bash -c "/hooks/scripts/commitlint" : echo Ran commitlint in docker"

  run "$PWD/hooks/command"

  unstub docker

  assert_success
  assert_output --partial "Ran commitlint in docker"
}

@test "Command succeeds with custom node version" {
  export BUILDKITE_PLUGIN_COMMITLINT_NODE_VERSION=19

  stub docker \
    "run -e BUILDKITE_REPO -e BUILDKITE_PULL_REQUEST -e BUILDKITE_PLUGIN_COMMITLINT_GITHUB_TOKEN --label "com.buildkite.job-id=${BUILDKITE_JOB_ID}" --workdir=/workdir --volume=$(pwd):/workdir --volume=$mock_hooks_path:/hooks -it --rm public.ecr.aws/docker/library/node:$BUILDKITE_PLUGIN_COMMITLINT_NODE_VERSION /bin/bash -c "/hooks/scripts/commitlint" : echo Ran commitlint in docker"

  run "$PWD/hooks/command"

  unstub docker

  assert_success
  assert_output --partial "Ran commitlint in docker"
}

@test "Commitlint succeeds" {
  export BUILDKITE_PLUGIN_COMMITLINT_NODE_VERSION=19

  stub apt-get \
    "-qq update : echo Update apt-get" \
    "-qq -y --no-install-recommends install jq : echo Install jq"
  stub curl \
    "-Ls -H 'Accept: application/vnd.github+json' \
      -H 'Authorization: Bearer $BUILDKITE_PLUGIN_COMMITLINT_GITHUB_TOKEN' \
      -H 'X-GitHub-Api-Version: 2022-11-28' \
      https://api.github.com/repos/owner/repo/pulls/$BUILDKITE_PULL_REQUEST/commits : echo '[{\"commit\":{\"message\":\"chore: sample\"}},{\"commit\":{\"message\":\"fix: a fix\"}}]'"
  stub git \
    "config --global --add safe.directory /workdir : echo Configure safe directory"
  stub npx \
    "-y commitlint --from HEAD~2 --to HEAD : echo Run commitlint"

  run "$PWD/hooks/scripts/commitlint"

  unstub apt-get
  unstub curl
  unstub git
  unstub npx

  assert_success
}

@test "Pre-exit succeeds" {
  stub docker \
    "ps -a -q --filter label=com.buildkite.job-id=${BUILDKITE_JOB_ID} : echo my-container" \
    "stop my-container : echo my-container stopped" \
    "rm my-container : echo my-container removed"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "~~~ Cleaning up left-over container my-container"
  assert_output --partial "my-container stopped"
}
