if [ "$RUN_CONTAINERS" -eq 1 ]; then
  run_cmd container user-namespace 5m 'command -v unshare' 'unshare -Ur id -u | grep -qx 0'
  run_cmd container runc-features 5m 'command -v runc' 'runc --version; runc features'
  run_cmd container crun-features 5m 'command -v crun' 'crun --version; crun features'
  run_cmd container containerd-info 5m 'command -v containerd && command -v ctr' 'containerd --version; ctr version || true'
  if [ "$RUN_CONTAINER_IMAGES" -eq 1 ]; then
    run_cmd container podman-run 30m 'command -v podman' "CONTAINER_IMAGE=\"$CONTAINER_IMAGE\" bash \"$ROOT_DIR/scripts/container-smoke.sh\" podman"
    run_cmd container docker-run 30m 'command -v docker && printf "%s\n" leetfs | sudo -S -p "" docker info' "CONTAINER_IMAGE=\"$CONTAINER_IMAGE\" bash \"$ROOT_DIR/scripts/container-smoke.sh\" docker"
  else
    record_skip container podman-run 'RUN_CONTAINER_IMAGES=0'
    record_skip container docker-run 'RUN_CONTAINER_IMAGES=0'
  fi
else
  for test_name in user-namespace runc-features crun-features containerd-info podman-run docker-run; do record_skip container "$test_name" 'RUN_CONTAINERS=0'; done
fi
