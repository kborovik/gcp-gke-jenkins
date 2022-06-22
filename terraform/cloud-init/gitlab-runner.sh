#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2086
gitlab_version="v14.9.1"
gitlab_runner="gitlab/gitlab-runner:ubuntu-$gitlab_version"
gitlab_runner_helper="gitlab/gitlab-runner-helper:ubuntu-x86_64-$gitlab_version"
docker_volume_sock="/var/run/docker.sock:/var/run/docker.sock"
docker_volume_gitlab_config="gitlab-runner-config:/etc/gitlab-runner"
docker pull "$gitlab_runner"
docker pull "$gitlab_runner_helper"
docker volume create gitlab-runner-config
docker run --rm --volume "$docker_volume_sock" --volume "$docker_volume_gitlab_config" "$gitlab_runner" register \
  --non-interactive \
  --name "${google_project_id}" \
  --url "https://code.roche.com/" \
  --registration-token "${gitlab_token}" \
  --executor "docker" \
  --limit 1 \
  --locked=true \
  --tag-list "${google_project_id}" \
  --docker-pull-policy "if-not-present" \
  --docker-helper-image "$gitlab_runner_helper" \
  --docker-image "ubuntu:20.04"
docker run --name "gitlab-runner" --detach --volume "$docker_volume_sock" --volume "$docker_volume_gitlab_config" --restart "always" "$gitlab_runner"
