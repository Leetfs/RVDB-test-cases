spec_find_root() {
  version="$1"
  explicit_root="$2"
  runner="$3"
  for candidate in \
    "$explicit_root" \
    "/opt/spec$version" \
    "/opt/SPEC_CPU$version" \
    "/usr/local/spec$version" \
    "$HOME/spec$version"; do
    [ -n "$candidate" ] || continue
    [ -f "$candidate/shrc" ] || continue
    if (cd "$candidate" && . ./shrc >/dev/null 2>&1 && command -v "$runner" >/dev/null 2>&1); then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

spec_find_config() {
  root="$1"
  requested="$2"
  if [ -n "$requested" ] && [ "$requested" != auto ]; then
    if [ -f "$requested" ]; then printf '%s\n' "$requested"; return 0; fi
    if [ -f "$root/config/$requested" ]; then printf '%s\n' "$requested"; return 0; fi
    return 1
  fi
  config="$(find "$root/config" -maxdepth 1 -type f -name 'k1*.cfg' -print 2>/dev/null | sort | head -1)"
  if [ -z "$config" ]; then
    config="$(find "$root/config" -maxdepth 1 -type f -name '*.cfg' -print 2>/dev/null | sort | head -1)"
  fi
  [ -n "$config" ] || return 1
  basename "$config"
}

spec_download_media() {
  url="$1"
  output="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --output "$output" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --tries=3 --output-document="$output" "$url"
  else
    return 1
  fi
}

spec_find_local_media() {
  version="$1"
  for candidate in \
    "/opt/spec-media/cpu$version.iso" \
    "/opt/spec-media/cpu$version.tar.xz" \
    "/srv/spec/cpu$version.iso" \
    "/srv/spec/cpu$version.tar.xz" \
    "/home/leetfs/spec-media/cpu$version.iso" \
    "/home/leetfs/spec-media/cpu$version.tar.xz"; do
    if [ -r "$candidate" ]; then
      printf 'file://%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

spec_install_from_media() {
  version="$1"
  media_url="$2"
  sha256_file="$3"
  destination="$4"
  custom_install_command="$5"
  work_dir="$SPEC_WORK_ROOT/cpu$version-install"
  media_file="$work_dir/media"
  source_dir="$work_dir/source"
  mount_dir="$work_dir/mount"
  mounted=0

  [ -n "$media_url" ] || return 2
  rm -rf "$work_dir"
  mkdir -p "$source_dir" "$mount_dir" "$(dirname "$destination")"
  spec_download_media "$media_url" "$media_file" || return 3
  [ -n "$sha256_file" ] || return 4
  case "$sha256_file" in
    /*) checksum_path="$sha256_file" ;;
    *) checksum_path="$ROOT_DIR/$sha256_file" ;;
  esac
  [ -r "$checksum_path" ] || return 4
  media_sha256="$(awk 'NF {print $1; exit}' "$checksum_path")"
  printf '%s\n' "$media_sha256" | grep -Eq '^[0-9a-fA-F]{64}$' || return 4
  printf '%s  %s\n' "$media_sha256" "$media_file" | sha256sum -c - || return 4

  case "${media_url%%\?*}" in
    *.iso)
      printf '%s\n' leetfs | sudo -S -p '' mount -o loop,ro,exec "$media_file" "$mount_dir" || return 5
      mounted=1
      cp -a "$mount_dir/." "$source_dir/" || return 6
      printf '%s\n' leetfs | sudo -S -p '' umount "$mount_dir" || return 5
      mounted=0
      ;;
    *.tar|*.tar.gz|*.tgz|*.tar.xz|*.txz|*.tar.bz2)
      tar -xf "$media_file" -C "$source_dir" || return 6
      installer="$(find "$source_dir" -type f -name install.sh -print | head -1)"
      [ -n "$installer" ] || return 7
      source_dir="$(dirname "$installer")"
      ;;
    *)
      return 8
      ;;
  esac

  if [ "$(uname -m)" = riscv64 ] && [ -z "$custom_install_command" ]; then
    if [ ! -x "$source_dir/tools/bin/runcpu" ]; then
      tools_source="$source_dir/tools/src"
      if [ ! -x "$tools_source/buildtools" ]; then
        tools_archive="$(find "$source_dir/install_archives" -maxdepth 1 -type f \
          \( -name 'tools-src*.tar' -o -name 'tools-src*.tar.gz' -o -name 'tools-src*.tar.xz' -o -name 'tools-src*.tgz' \) \
          -print 2>/dev/null | sort | head -1)"
        [ -n "$tools_archive" ] || return 9
        rm -rf "$source_dir/tools"
        mkdir -p "$tools_source/buildtools.log"
        printf 'Extracting SPEC tools source: %s\n' "$(basename "$tools_archive")"
        tar -xf "$tools_archive" -C "$source_dir" || return 9
      fi
      [ -x "$tools_source/buildtools" ] || return 9
      (cd "$tools_source" && timeout 8h ./buildtools) || return 10
    fi
  fi

  if [ -n "$custom_install_command" ]; then
    SPEC_MEDIA_DIR="$source_dir" SPEC_INSTALL_ROOT="$destination" timeout 4h bash -lc "$custom_install_command"
    rc=$?
  else
    (cd "$source_dir" && printf 'yes\n' | timeout 4h ./install.sh -d "$destination")
    rc=$?
  fi
  if [ "$mounted" -eq 1 ] || mountpoint -q "$mount_dir" 2>/dev/null; then
    printf '%s\n' leetfs | sudo -S -p '' umount "$mount_dir" || true
  fi
  return "$rc"
}

spec_initialize_one() {
  version="$1"
  root_name="$2"
  config_name="$3"
  command_name="$4"
  runner="$5"

  eval "explicit_root=\${$root_name}"
  eval "requested_config=\${$config_name}"
  eval "command_text=\${$command_name}"

  eval "media_url=\${SPEC${version}_MEDIA_URL}"
  eval "sha256_file=\${SPEC${version}_SHA256_FILE}"
  eval "install_root=\${SPEC${version}_INSTALL_ROOT}"
  eval "install_command=\${SPEC${version}_INSTALL_CMD}"

  if [ -z "$media_url" ]; then
    media_url="$(spec_find_local_media "$version")" || true
  fi

  root="$(spec_find_root "$version" "$explicit_root" "$runner")" || true
  if [ -z "$root" ]; then
    if spec_install_from_media "$version" "$media_url" "$sha256_file" "$install_root" "$install_command"; then
      root="$(spec_find_root "$version" "$install_root" "$runner")" || true
      if [ -n "$root" ]; then
        install_result "spec-cpu$version-install" INSTALLED "$install_root"
      else
        printf -v "$command_name" '%s' ''
        install_result "spec-cpu$version-install" UNAVAILABLE "$runner unavailable after installation"
        return 0
      fi
    else
      rc=$?
      printf -v "$command_name" '%s' ''
      if [ "$rc" -eq 2 ]; then
        install_result "spec-cpu$version-install" UNAVAILABLE "stage licensed media under /opt/spec-media or set SPEC${version}_MEDIA_URL"
      elif [ "$rc" -eq 4 ]; then
        install_result "spec-cpu$version-install" FAILED "local official SHA256 manifest missing, invalid, or mismatched"
      elif [ "$rc" -eq 9 ] || [ "$rc" -eq 10 ]; then
        install_result "spec-cpu$version-install" UNAVAILABLE "RISC-V SPEC tools source/build failed (rc=$rc)"
      else
        install_result "spec-cpu$version-install" UNAVAILABLE "media installation rc=$rc"
      fi
      return 0
    fi
  fi
  config="$(spec_find_config "$root" "$requested_config")" || {
    printf -v "$command_name" '%s' ''
    install_result "spec-cpu$version-init" UNAVAILABLE "no usable config under $root/config"
    return 0
  }

  command_text="${command_text//--config=auto/--config=$config}"
  printf -v quoted_root '%q' "$root"
  printf -v initialized_command 'cd %s && . ./shrc && %s' "$quoted_root" "$command_text"
  printf -v "$root_name" '%s' "$root"
  printf -v "$config_name" '%s' "$config"
  printf -v "$command_name" '%s' "$initialized_command"
  install_result "spec-cpu$version-init" READY "$root; config=$config"
}

initialize_spec() {
  [ "$RUN_SPEC" -eq 1 ] || return 0
  if [ "$SPEC_AUTO_INIT" -ne 1 ]; then
    install_result spec-auto-init SKIP 'SPEC_AUTO_INIT=0; using configured commands unchanged'
    return 0
  fi
  spec_initialize_one 2017 SPEC2017_ROOT SPEC2017_CONFIG SPEC2017_CMD runcpu
}
