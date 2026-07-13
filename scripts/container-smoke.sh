#!/usr/bin/env bash
set -euo pipefail

mode="${1:?mode is required}"
case "$mode" in
  podman)
    root="$WORK_DIR/podman-root"; runroot="$WORK_DIR/podman-runroot"
    mkdir -p "$root" "$runroot"
    podman --root "$root" --runroot "$runroot" --storage-driver vfs info
    podman --root "$root" --runroot "$runroot" --storage-driver vfs run --rm "$CONTAINER_IMAGE" sh -c 'uname -m; test -r /etc/os-release'
    ;;
  docker)
    image_existed=0
    if printf '%s\n' leetfs | sudo -S -p '' docker image inspect "$CONTAINER_IMAGE" >/dev/null 2>&1; then
      image_existed=1
    fi
    cleanup_docker_image() {
      if [ "$image_existed" -eq 0 ]; then
        printf '%s\n' leetfs | sudo -S -p '' docker image rm "$CONTAINER_IMAGE" >/dev/null 2>&1 || true
      fi
    }
    trap cleanup_docker_image EXIT INT TERM
    printf '%s\n' leetfs | sudo -S -p '' docker info
    printf '%s\n' leetfs | sudo -S -p '' docker run --rm "$CONTAINER_IMAGE" sh -c 'uname -m; test -r /etc/os-release'
    ;;
  *) exit 2 ;;
esac
