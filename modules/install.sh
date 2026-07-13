update_package_index
ensure_package build-essential 'command -v gcc && command -v make' build-essential 'gcc gcc-c++ make'
ensure_package git 'command -v git' git git
ensure_package openssl 'command -v openssl' openssl openssl
ensure_package process-control 'command -v setsid && command -v timeout' 'util-linux coreutils' 'util-linux coreutils'

build_unixbench() {
  ensure_source unixbench 'test -x /opt/UnixBench/Run' 'git clone --depth 1 https://github.com/kdlucas/byte-unixbench.git "$SOURCE_ROOT/unixbench" && make -C "$SOURCE_ROOT/unixbench/UnixBench" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/UnixBench && printf "%s\n" leetfs | sudo -S -p "" cp -a "$SOURCE_ROOT/unixbench/UnixBench/." /opt/UnixBench/'
}

build_lmbench() {
  if ! find /opt/lmbench -name lat_syscall -type f -perm -111 -print -quit 2>/dev/null | grep -q .; then
    ensure_package lmbench-build-deps 'test -f /usr/include/tirpc/rpc/rpc.h' libtirpc-dev libtirpc-devel
  fi
  ensure_source lmbench 'find /opt/lmbench -name lat_syscall -type f -perm -111 -print -quit 2>/dev/null | grep -q .' 'git clone --depth 1 https://github.com/intel/lmbench.git "$SOURCE_ROOT/lmbench" && make -C "$SOURCE_ROOT/lmbench/src" -j "$(nproc)" CPPFLAGS="-I/usr/include/tirpc" LDLIBS="-ltirpc" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/lmbench && printf "%s\n" leetfs | sudo -S -p "" cp -a "$SOURCE_ROOT/lmbench/." /opt/lmbench/'
}

if [ "$RUN_SPEC" -eq 1 ] && has_module cpu; then
  ensure_package download-tools 'command -v curl || command -v wget' curl curl
  ensure_package archive-tools 'command -v tar && command -v xz' 'tar xz-utils' 'tar xz'
  ensure_package mount-tools 'command -v mount' mount util-linux
  ensure_package spec-build-tools 'command -v gcc && command -v g++ && command -v gfortran && command -v make && command -v perl' 'build-essential gfortran perl' 'gcc gcc-c++ gcc-gfortran make perl'
fi

if has_module info; then
  ensure_package info-build-tools 'command -v cmake && command -v meson && command -v ninja && command -v pkg-config && command -v autoreconf' 'cmake meson ninja-build pkg-config autoconf automake libtool libegl1-mesa-dev libgles2-mesa-dev libx11-dev libvulkan-dev libva-dev libvdpau-dev libudev-dev' 'cmake meson ninja-build pkgconf autoconf automake libtool mesa-libEGL-devel mesa-libGLES-devel libX11-devel vulkan-loader-devel libva-devel libvdpau-devel systemd-devel'
  ensure_package ruapu 'command -v ruapu' ruapu ruapu
  ensure_package mhz 'command -v mhz || ls /usr/lib/lmbench/bin/*/mhz >/dev/null 2>&1' lmbench lmbench
  ensure_package es2-info 'command -v es2_info' mesa-utils-extra mesa-demos
  ensure_package vulkaninfo 'command -v vulkaninfo' vulkan-tools vulkan-tools
  ensure_package clinfo 'command -v clinfo' clinfo clinfo
  ensure_package glxinfo 'command -v glxinfo' mesa-utils mesa-demos
  ensure_package vainfo 'command -v vainfo' vainfo libva-utils
  ensure_package vdpauinfo 'command -v vdpauinfo' vdpauinfo vdpauinfo
  ensure_package v4l2 'command -v v4l2-ctl' v4l-utils v4l-utils
  ensure_package ffmpeg 'command -v ffmpeg' ffmpeg ffmpeg
  ensure_package gstreamer 'command -v gst-inspect-1.0' gstreamer1.0-tools gstreamer1-plugins-base-tools
  ensure_source ruapu 'command -v ruapu' 'git clone --depth 1 https://github.com/nihui/ruapu.git "$SOURCE_ROOT/ruapu" && cd "$SOURCE_ROOT/ruapu" && gcc -O2 main.c -o ruapu && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 ruapu /usr/local/bin/ruapu'
  ensure_source mhz 'command -v mhz' 'git clone --depth 1 https://github.com/wtarreau/mhz.git "$SOURCE_ROOT/mhz" && make -C "$SOURCE_ROOT/mhz" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/mhz/mhz" /usr/local/bin/mhz'
  ensure_source clinfo 'command -v clinfo' 'git clone --depth 1 https://github.com/Oblomov/clinfo.git "$SOURCE_ROOT/clinfo" && make -C "$SOURCE_ROOT/clinfo" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/clinfo/clinfo" /usr/local/bin/clinfo'
  ensure_source mesa-demos 'command -v es2_info && command -v glxinfo' 'git clone --depth 1 https://gitlab.freedesktop.org/mesa/demos.git "$SOURCE_ROOT/mesa-demos" && meson setup "$SOURCE_ROOT/mesa-demos/build" "$SOURCE_ROOT/mesa-demos" && meson compile -C "$SOURCE_ROOT/mesa-demos/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/mesa-demos/build"'
  ensure_source vulkaninfo 'command -v vulkaninfo' 'git clone --depth 1 --recurse-submodules https://github.com/KhronosGroup/Vulkan-Tools.git "$SOURCE_ROOT/vulkan-tools" && cmake -S "$SOURCE_ROOT/vulkan-tools" -B "$SOURCE_ROOT/vulkan-tools/build" -DCMAKE_BUILD_TYPE=Release && cmake --build "$SOURCE_ROOT/vulkan-tools/build" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" cmake --install "$SOURCE_ROOT/vulkan-tools/build"'
  ensure_source vainfo 'command -v vainfo' 'git clone --depth 1 https://github.com/intel/libva-utils.git "$SOURCE_ROOT/libva-utils" && meson setup "$SOURCE_ROOT/libva-utils/build" "$SOURCE_ROOT/libva-utils" && meson compile -C "$SOURCE_ROOT/libva-utils/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/libva-utils/build"'
  ensure_source vdpauinfo 'command -v vdpauinfo' 'git clone --depth 1 https://gitlab.freedesktop.org/vdpau/vdpauinfo.git "$SOURCE_ROOT/vdpauinfo" && cd "$SOURCE_ROOT/vdpauinfo" && autoreconf -fi && ./configure && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
  ensure_source v4l2 'command -v v4l2-ctl' 'git clone --depth 1 https://git.linuxtv.org/v4l-utils.git "$SOURCE_ROOT/v4l-utils" && meson setup "$SOURCE_ROOT/v4l-utils/build" "$SOURCE_ROOT/v4l-utils" && meson compile -C "$SOURCE_ROOT/v4l-utils/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/v4l-utils/build"'
  ensure_source ffmpeg 'command -v ffmpeg' 'git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git "$SOURCE_ROOT/ffmpeg" && cd "$SOURCE_ROOT/ffmpeg" && ./configure --disable-doc && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
  ensure_source gstreamer 'command -v gst-inspect-1.0' 'git clone --depth 1 https://gitlab.freedesktop.org/gstreamer/gstreamer.git "$SOURCE_ROOT/gstreamer" && meson setup "$SOURCE_ROOT/gstreamer/build" "$SOURCE_ROOT/gstreamer" && meson compile -C "$SOURCE_ROOT/gstreamer/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/gstreamer/build"'
fi

if has_module distro; then
  ensure_package distro-tools 'command -v findmnt && command -v unshare && command -v locale' 'util-linux locales' 'util-linux glibc-langpack-en'
  ensure_package proc-tools 'command -v sysctl' procps procps-ng
fi

if has_module toolchain && [ "$RUN_TOOLCHAINS" -eq 1 ]; then
  ensure_package cpp-toolchain 'command -v g++ && command -v gfortran' 'g++ gfortran' 'gcc-c++ gcc-gfortran'
  ensure_package clang 'command -v clang' clang clang
  ensure_package rust 'command -v rustc && command -v cargo' 'rustc cargo' 'rust cargo'
  ensure_package golang 'command -v go' golang-go golang
  ensure_package java 'command -v javac && command -v java' default-jdk-headless java-17-openjdk-devel
  ensure_package nodejs 'command -v node' nodejs nodejs
  ensure_package perl-modules 'perl -MJSON::PP -MDigest::SHA -e 1' perl perl
  ensure_package php-runtime 'command -v php' php-cli php-cli
fi

if has_module network && [ "$RUN_NETWORK" -eq 1 ]; then
  ensure_package iproute 'command -v ip' iproute2 iproute
  ensure_package ping 'command -v ping' iputils-ping iputils
  ensure_package ethtool 'command -v ethtool' ethtool ethtool
  ensure_package iperf3 'command -v iperf3' iperf3 iperf3
  ensure_package netperf 'command -v netperf && command -v netserver' netperf netperf
  ensure_package sockperf 'command -v sockperf' sockperf sockperf
  ensure_package qperf 'command -v qperf' qperf qperf
  ensure_source netperf 'command -v netperf && command -v netserver' 'git clone --depth 1 https://github.com/HewlettPackard/netperf.git "$SOURCE_ROOT/netperf" && cd "$SOURCE_ROOT/netperf" && ./autogen.sh && ./configure && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
  ensure_source sockperf 'command -v sockperf' 'git clone --depth 1 https://github.com/Mellanox/sockperf.git "$SOURCE_ROOT/sockperf" && cd "$SOURCE_ROOT/sockperf" && ./autogen.sh && ./configure && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
  ensure_source qperf 'command -v qperf' 'git clone --depth 1 https://github.com/linux-rdma/qperf.git "$SOURCE_ROOT/qperf" && cd "$SOURCE_ROOT/qperf" && ./autogen.sh && ./configure && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
fi

if has_module container && [ "$RUN_CONTAINERS" -eq 1 ]; then
  ensure_package podman 'command -v podman' podman podman
  ensure_package runc 'command -v runc' runc runc
  ensure_package crun 'command -v crun' crun crun
  ensure_package containerd 'command -v containerd && command -v ctr' containerd containerd
  ensure_package docker 'command -v docker' docker.io moby-engine
  ensure_source runc 'command -v runc' 'git clone --depth 1 https://github.com/opencontainers/runc.git "$SOURCE_ROOT/runc" && make -C "$SOURCE_ROOT/runc" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/runc/runc" /usr/local/bin/runc' 4h
  ensure_source crun 'command -v crun' 'git clone --depth 1 https://github.com/containers/crun.git "$SOURCE_ROOT/crun" && cd "$SOURCE_ROOT/crun" && ./autogen.sh && ./configure && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install' 4h
  ensure_source containerd 'command -v containerd && command -v ctr' 'git clone --depth 1 https://github.com/containerd/containerd.git "$SOURCE_ROOT/containerd" && make -C "$SOURCE_ROOT/containerd" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/containerd/bin/containerd" "$SOURCE_ROOT/containerd/bin/ctr" /usr/local/bin/' 4h
  ensure_source podman 'command -v podman' 'git clone --depth 1 https://github.com/containers/podman.git "$SOURCE_ROOT/podman" && make -C "$SOURCE_ROOT/podman" -j "$(nproc)" BUILDTAGS="" && printf "%s\n" leetfs | sudo -S -p "" make -C "$SOURCE_ROOT/podman" install PREFIX=/usr/local' 6h
fi

if has_module security && [ "$RUN_SECURITY" -eq 1 ]; then
  ensure_package capabilities 'command -v capsh' libcap2-bin libcap
  ensure_package audit 'command -v auditctl' auditd audit
  ensure_package checksec 'command -v checksec' checksec checksec
  ensure_package lynis 'command -v lynis' lynis lynis
  ensure_package openscap 'command -v oscap' openscap-scanner openscap-scanner
  ensure_source checksec 'command -v checksec' 'git clone --depth 1 https://github.com/slimm609/checksec.sh.git "$SOURCE_ROOT/checksec" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/checksec/checksec" /usr/local/bin/checksec'
  ensure_source lynis 'command -v lynis' 'git clone --depth 1 https://github.com/CISOfy/lynis.git "$SOURCE_ROOT/lynis" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/lynis && printf "%s\n" leetfs | sudo -S -p "" cp -a "$SOURCE_ROOT/lynis/." /opt/lynis/ && printf "%s\n" leetfs | sudo -S -p "" ln -sf /opt/lynis/lynis /usr/local/bin/lynis'
  ensure_source openscap 'command -v oscap' 'git clone --depth 1 https://github.com/OpenSCAP/openscap.git "$SOURCE_ROOT/openscap" && cmake -S "$SOURCE_ROOT/openscap" -B "$SOURCE_ROOT/openscap/build" -DCMAKE_BUILD_TYPE=Release -DENABLE_PYTHON3=OFF -DENABLE_TESTS=OFF && cmake --build "$SOURCE_ROOT/openscap/build" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" cmake --install "$SOURCE_ROOT/openscap/build"' 4h
fi

if has_module realtime && [ "$RUN_REALTIME" -eq 1 ]; then
  ensure_package rt-tests 'command -v cyclictest && command -v oslat' rt-tests rt-tests
  ensure_package perf 'command -v perf' linux-perf perf
  ensure_source rt-tests 'command -v cyclictest && command -v oslat' 'git clone --depth 1 https://git.kernel.org/pub/scm/utils/rt-tests/rt-tests.git "$SOURCE_ROOT/rt-tests" && make -C "$SOURCE_ROOT/rt-tests" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make -C "$SOURCE_ROOT/rt-tests" install' 2h
fi

if has_module multimedia && [ "$RUN_MULTIMEDIA" -eq 1 ]; then
  ensure_package multimedia-tools 'command -v ffmpeg && command -v gst-launch-1.0 && command -v v4l2-compliance' 'ffmpeg gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good v4l-utils' 'ffmpeg gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good v4l-utils'
fi

if has_module filesystem && [ "$RUN_FILESYSTEM" -eq 1 ]; then
  ensure_package filesystem-tools 'command -v xfs_io && command -v getfacl && command -v setfattr' 'xfsprogs acl attr' 'xfsprogs acl attr'
  ensure_package xfstests-build-deps 'test -f /usr/include/libaio.h && test -f /usr/include/uuid/uuid.h && command -v prove' 'libaio-dev uuid-dev libcap-dev libgdbm-dev e2fsprogs perl' 'libaio-devel libuuid-devel libcap-devel gdbm-devel e2fsprogs perl'
  ensure_package pjdfstest 'command -v pjdfstest' pjdfstest pjdfstest
  ensure_source xfstests 'test -x /opt/xfstests/check && test -x /opt/xfstests/src/fsx' 'git clone --depth 1 https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git "$SOURCE_ROOT/xfstests" && make -C "$SOURCE_ROOT/xfstests" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/xfstests && printf "%s\n" leetfs | sudo -S -p "" cp -a "$SOURCE_ROOT/xfstests/." /opt/xfstests/' 4h
  ensure_source pjdfstest 'test -d /opt/pjdfstest/tests' 'git clone --depth 1 https://github.com/pjd/pjdfstest.git "$SOURCE_ROOT/pjdfstest" && make -C "$SOURCE_ROOT/pjdfstest" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/pjdfstest && printf "%s\n" leetfs | sudo -S -p "" cp -a "$SOURCE_ROOT/pjdfstest/." /opt/pjdfstest/'
  if [ "$RUN_DESTRUCTIVE" -eq 1 ] && [ -n "$BLKTESTS_DEVICES" ]; then
    ensure_source blktests 'test -x /opt/blktests/check' 'git clone --depth 1 https://github.com/osandov/blktests.git "$SOURCE_ROOT/blktests" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/blktests && printf "%s\n" leetfs | sudo -S -p "" cp -a "$SOURCE_ROOT/blktests/." /opt/blktests/'
  fi
fi

if has_module kernel-extra && [ "$RUN_KSELFTEST" -eq 1 ]; then
  ensure_package kselftest-build-deps 'command -v flex && command -v bison && test -f /usr/include/elf.h' 'flex bison libelf-dev libssl-dev libcap-dev liburing-dev' 'flex bison elfutils-libelf-devel openssl-devel libcap-devel liburing-devel'
  ensure_source kselftest 'test -x /opt/kselftest/run_kselftest.sh' 'git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git "$SOURCE_ROOT/linux" && make -C "$SOURCE_ROOT/linux" headers && make -C "$SOURCE_ROOT/linux/tools/testing/selftests" -j "$(nproc)" TARGETS="'$KSELFTEST_COLLECTIONS'" && printf "%s\n" leetfs | sudo -S -p "" make -C "$SOURCE_ROOT/linux/tools/testing/selftests" TARGETS="'$KSELFTEST_COLLECTIONS'" install INSTALL_PATH=/opt/kselftest' 8h
  ensure_package bpftool 'command -v bpftool' bpftool bpftool
  ensure_package perf 'command -v perf' linux-perf perf
fi

if has_module graphics-cts && [ "$RUN_GRAPHICS_CTS" -eq 1 ]; then
  ensure_package graphics-cts-build-deps 'test -f /usr/include/CL/cl.h && command -v pkg-config && command -v spirv-as' 'ocl-icd-opencl-dev opencl-headers spirv-headers spirv-tools libdrm-dev libgbm-dev libegl1-mesa-dev libgles2-mesa-dev' 'ocl-icd-devel opencl-headers spirv-headers spirv-tools libdrm-devel mesa-libgbm-devel mesa-libEGL-devel mesa-libGLES-devel'
  ensure_package drm-tests 'command -v modetest' libdrm-tests libdrm-tests
  ensure_package piglit 'command -v piglit' piglit piglit
  ensure_package deqp 'command -v deqp-gles2 && command -v deqp-vk' 'deqp deqp-vk' 'deqp deqp-vk'
  ensure_package opencl-cts 'command -v test_basic' opencl-cts opencl-cts
  ensure_source piglit 'command -v piglit' 'git clone --depth 1 https://gitlab.freedesktop.org/mesa/piglit.git "$SOURCE_ROOT/piglit" && meson setup "$SOURCE_ROOT/piglit/build" "$SOURCE_ROOT/piglit" && meson compile -C "$SOURCE_ROOT/piglit/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/piglit/build"' 8h
  ensure_source modetest 'command -v modetest' 'git clone --depth 1 https://gitlab.freedesktop.org/mesa/drm.git "$SOURCE_ROOT/libdrm" && meson setup "$SOURCE_ROOT/libdrm/build" "$SOURCE_ROOT/libdrm" -Dinstall-test-programs=true && meson compile -C "$SOURCE_ROOT/libdrm/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/libdrm/build"' 4h
  ensure_source deqp 'command -v deqp-gles2 && command -v deqp-vk' 'git clone --depth 1 https://github.com/KhronosGroup/VK-GL-CTS.git "$SOURCE_ROOT/vk-gl-cts" && cd "$SOURCE_ROOT/vk-gl-cts" && python3 external/fetch_sources.py && cmake -S . -B build -DDEQP_TARGET=surfaceless -DCMAKE_BUILD_TYPE=Release && cmake --build build -j "$(nproc)" --target deqp-gles2 deqp-vk && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 build/modules/gles2/deqp-gles2 build/external/vulkancts/modules/vulkan/deqp-vk /usr/local/bin/' 12h
  ensure_source opencl-cts 'command -v test_basic' 'git clone --depth 1 https://github.com/KhronosGroup/OpenCL-CTS.git "$SOURCE_ROOT/opencl-cts" && libdir=$(pkg-config --variable=libdir OpenCL) && cmake -S "$SOURCE_ROOT/opencl-cts" -B "$SOURCE_ROOT/opencl-cts/build" -DCL_INCLUDE_DIR=/usr/include -DSPIRV_INCLUDE_DIR=/usr/include -DCL_LIB_DIR="$libdir" -DSPIRV_TOOLS_DIR=/usr/bin -DOPENCL_LIBRARIES=OpenCL -DCMAKE_BUILD_TYPE=Release && cmake --build "$SOURCE_ROOT/opencl-cts/build" -j "$(nproc)" --target test_basic && bin=$(find "$SOURCE_ROOT/opencl-cts/build" -type f -name test_basic -perm -111 -print -quit) && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$bin" /usr/local/bin/test_basic' 12h
fi

if has_module cpu; then
  ensure_package 7zip 'command -v 7z || command -v 7zz' p7zip-full 'p7zip p7zip-plugins'
  ensure_package stockfish 'command -v stockfish || test -x /usr/games/stockfish' stockfish stockfish
  ensure_package unixbench 'command -v byte-unixbench || test -x /usr/lib/byte-unixbench/Run || test -x /opt/UnixBench/Run' byte-unixbench byte-unixbench
  ensure_package coremark-pro 'command -v coremark-pro || test -f /opt/coremark-pro/Makefile' coremark-pro coremark-pro
  ensure_source 7zip 'command -v 7z || command -v 7zz' 'git clone --depth 1 https://github.com/ip7z/7zip.git "$SOURCE_ROOT/7zip" && make -C "$SOURCE_ROOT/7zip/CPP/7zip/Bundles/Alone2" -f makefile.gcc -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/7zip/CPP/7zip/Bundles/Alone2/b/g/7zz" /usr/local/bin/7z'
  ensure_source stockfish 'command -v stockfish' 'git clone --depth 1 https://github.com/official-stockfish/Stockfish.git "$SOURCE_ROOT/stockfish" && make -C "$SOURCE_ROOT/stockfish/src" -j "$(nproc)" build ARCH=riscv64 && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/stockfish/src/stockfish" /usr/local/bin/stockfish'
  build_unixbench
  ensure_source coremark 'command -v coremark' 'git clone --depth 1 https://github.com/eembc/coremark.git "$SOURCE_ROOT/coremark" && make -C "$SOURCE_ROOT/coremark" PORT_DIR=linux compile && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/coremark/coremark.exe" /usr/local/bin/coremark'
  ensure_source coremark-pro 'command -v coremark-pro' 'git clone --depth 1 https://github.com/eembc/coremark-pro.git "$SOURCE_ROOT/coremark-pro" && cd "$SOURCE_ROOT/coremark-pro" && make TARGET=linux64 build && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/coremark-pro && printf "%s\n" leetfs | sudo -S -p "" cp -a . /opt/coremark-pro/ && printf "%s\n" leetfs | sudo -S -p "" sh -c "printf '\''#!/bin/sh\ncd /opt/coremark-pro || exit 1\nexec make TARGET=linux64 XCMD=\"-c\$(nproc)\" certify-all\n'\'' > /usr/local/bin/coremark-pro && chmod 0755 /usr/local/bin/coremark-pro"'
fi

if has_module memory; then
  ensure_package tinymembench 'command -v tinymembench' tinymembench tinymembench
  ensure_package lmbench 'command -v lat_syscall || ls /usr/lib/lmbench/bin/*/lat_syscall >/dev/null 2>&1 || find /opt/lmbench -name lat_syscall -type f -perm -111 -print -quit 2>/dev/null | grep -q .' lmbench lmbench
  ensure_package ramlat 'command -v ramlat' ramlat ramlat
  ensure_package core-to-core-latency 'command -v core-to-core-latency' core-to-core-latency core-to-core-latency
  ensure_package cargo 'command -v cargo' cargo 'cargo rust'
  ensure_source tinymembench 'command -v tinymembench' 'git clone --depth 1 https://github.com/ssvb/tinymembench.git "$SOURCE_ROOT/tinymembench" && make -C "$SOURCE_ROOT/tinymembench" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/tinymembench/tinymembench" /usr/local/bin/tinymembench'
  build_lmbench
  ensure_source ramlat 'command -v ramlat' 'git clone --depth 1 https://github.com/wtarreau/ramspeed.git "$SOURCE_ROOT/ramspeed" && make -C "$SOURCE_ROOT/ramspeed" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/ramspeed/ramlat" /usr/local/bin/ramlat'
  ensure_source stream 'command -v stream' 'git clone --depth 1 https://github.com/jeffhammond/STREAM.git "$SOURCE_ROOT/stream" && cd "$SOURCE_ROOT/stream" && gcc -O3 -fopenmp -DSTREAM_ARRAY_SIZE=10000000 -DNTIMES=10 stream.c -o stream && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 stream /usr/local/bin/stream'
  ensure_source core-to-core-latency 'command -v core-to-core-latency' 'cargo install --root "$WORK_DIR/cargo" core-to-core-latency && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$WORK_DIR/cargo/bin/core-to-core-latency" /usr/local/bin/core-to-core-latency'
fi

if has_module gpu; then
  ensure_package cmake 'command -v cmake' cmake cmake
  ensure_package gpu-build-tools 'command -v meson && command -v ninja && command -v pkg-config' 'meson ninja-build pkg-config libdrm-dev libegl1-mesa-dev libgles2-mesa-dev libvulkan-dev' 'meson ninja-build pkgconf libdrm-devel mesa-libEGL-devel mesa-libGLES-devel vulkan-loader-devel'
  ensure_package glmark2 'command -v glmark2-es2-drm || command -v glmark2-es2 || command -v glmark2' glmark2 glmark2
  ensure_package vkmark 'command -v vkmark' vkmark vkmark
  ensure_package vkpeak 'command -v vkpeak' vkpeak vkpeak
  ensure_package clpeak 'command -v clpeak' clpeak clpeak
  ensure_package gfxbench 'command -v gfxbench' gfxbench gfxbench
  ensure_source glmark2 'command -v glmark2-es2-drm || command -v glmark2-es2 || command -v glmark2' 'git clone --depth 1 https://github.com/glmark2/glmark2.git "$SOURCE_ROOT/glmark2" && meson setup "$SOURCE_ROOT/glmark2/build" "$SOURCE_ROOT/glmark2" -Dflavors=drm-glesv2 && meson compile -C "$SOURCE_ROOT/glmark2/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/glmark2/build"'
  ensure_source vkmark 'command -v vkmark' 'git clone --depth 1 https://github.com/vkmark/vkmark.git "$SOURCE_ROOT/vkmark" && meson setup "$SOURCE_ROOT/vkmark/build" "$SOURCE_ROOT/vkmark" && meson compile -C "$SOURCE_ROOT/vkmark/build" && printf "%s\n" leetfs | sudo -S -p "" meson install -C "$SOURCE_ROOT/vkmark/build"'
  ensure_source vkpeak 'command -v vkpeak' 'git clone --depth 1 --recurse-submodules https://github.com/nihui/vkpeak.git "$SOURCE_ROOT/vkpeak" && cmake -S "$SOURCE_ROOT/vkpeak" -B "$SOURCE_ROOT/vkpeak/build" && cmake --build "$SOURCE_ROOT/vkpeak/build" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/vkpeak/build/vkpeak" /usr/local/bin/vkpeak'
  ensure_source clpeak 'command -v clpeak' 'git clone --depth 1 https://github.com/krrishnarraj/clpeak.git "$SOURCE_ROOT/clpeak" && cmake -S "$SOURCE_ROOT/clpeak" -B "$SOURCE_ROOT/clpeak/build" && cmake --build "$SOURCE_ROOT/clpeak/build" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/clpeak/build/clpeak" /usr/local/bin/clpeak'
  if ! command -v gfxbench >/dev/null 2>&1; then install_result gfxbench-source UNAVAILABLE 'GFXBench requires licensed vendor media'; fi
fi

if has_module combined; then
  ensure_package unixbench 'command -v byte-unixbench || test -x /usr/lib/byte-unixbench/Run || test -x /opt/UnixBench/Run' byte-unixbench byte-unixbench
  ensure_package lmbench 'command -v lat_syscall || ls /usr/lib/lmbench/bin/*/lat_syscall >/dev/null 2>&1 || find /opt/lmbench -name lat_syscall -type f -perm -111 -print -quit 2>/dev/null | grep -q .' lmbench lmbench
  if ! has_module cpu; then build_unixbench; fi
  if ! has_module memory; then build_lmbench; fi
  ensure_source sbc-bench 'command -v sbc-bench' 'git clone --depth 1 https://github.com/ThomasKaiser/sbc-bench.git "$SOURCE_ROOT/sbc-bench" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 "$SOURCE_ROOT/sbc-bench/sbc-bench.sh" /usr/local/bin/sbc-bench'
fi

if has_module pts && [ "$RUN_PTS" -eq 1 ] && [ -n "$PTS_TESTS" ]; then
  ensure_package php 'command -v php' php-cli php-cli
  ensure_package php-xml 'php -m 2>/dev/null | grep -qix dom && php -m 2>/dev/null | grep -qix simplexml' php-xml php-xml
  ensure_package pts-runtime-deps 'command -v python3 && command -v perl && command -v unzip && command -v xz' 'python3 python3-venv python3-pip perl unzip xz-utils' 'python3 python3-pip perl unzip xz'
  ensure_package pts-build-tools 'command -v cmake && command -v meson && command -v ninja && command -v autoreconf && command -v bison && command -v flex' 'cmake meson ninja-build pkg-config autoconf automake libtool bison flex' 'cmake meson ninja-build pkgconf autoconf automake libtool bison flex'
  ensure_package pts-dev-core 'test -f /usr/include/libaio.h && test -f /usr/include/sqlite3.h && test -f /usr/include/zlib.h && test -f /usr/include/openssl/ssl.h && test -f /usr/include/libxml2/libxml/parser.h' 'libaio-dev libsqlite3-dev zlib1g-dev libssl-dev libxml2-dev' 'libaio-devel sqlite-devel zlib-devel openssl-devel libxml2-devel'
  ensure_package pts-dev-services 'test -f /usr/include/numa.h && test -f /usr/include/event2/event.h && test -f /usr/include/pcre2.h && find /usr/include -path "*/curl/curl.h" -print -quit | grep -q .' 'libcurl4-openssl-dev libnuma-dev libevent-dev libpcre2-dev' 'libcurl-devel numactl-devel libevent-devel pcre2-devel'
  ensure_package phoronix-test-suite 'test -x /usr/bin/phoronix-test-suite && test -f /usr/share/phoronix-test-suite/pts-core/phoronix-test-suite.php' phoronix-test-suite phoronix-test-suite
  ensure_source phoronix-test-suite 'test -x /usr/bin/phoronix-test-suite && test -f /usr/share/phoronix-test-suite/pts-core/phoronix-test-suite.php' 'git clone --depth 1 https://github.com/phoronix-test-suite/phoronix-test-suite.git "$SOURCE_ROOT/phoronix-test-suite" && cd "$SOURCE_ROOT/phoronix-test-suite" && printf "%s\n" leetfs | sudo -S -p "" rm -f /usr/local/bin/phoronix-test-suite && printf "%s\n" leetfs | sudo -S -p "" ./install-sh /usr'
fi

if has_module storage; then
  ensure_package fio 'command -v fio' fio fio
  ensure_package iozone 'command -v iozone' iozone3 iozone
  ensure_source fio 'command -v fio' 'git clone --depth 1 https://github.com/axboe/fio.git "$SOURCE_ROOT/fio" && cd "$SOURCE_ROOT/fio" && ./configure && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
  ensure_source iozone 'command -v iozone' 'cd "$SOURCE_ROOT" && (curl -fsSLO https://www.iozone.org/src/current/iozone3_506.tar || wget -q https://www.iozone.org/src/current/iozone3_506.tar) && tar -xf iozone3_506.tar && make -C iozone3_506/src/current linux -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 iozone3_506/src/current/iozone /usr/local/bin/iozone'
fi

if has_module virt-kernel; then
  if [ -e /dev/kvm ]; then
    ensure_package kvm-unit-tests 'test -x /opt/kvm-unit-tests/run_tests.sh || test -x /usr/share/kvm-unit-tests/run_tests.sh' kvm-unit-tests kvm-unit-tests
    ensure_source kvm-unit-tests 'test -x /opt/kvm-unit-tests/run_tests.sh' 'git clone --depth 1 https://gitlab.com/kvm-unit-tests/kvm-unit-tests.git "$SOURCE_ROOT/kvm-unit-tests" && cd "$SOURCE_ROOT/kvm-unit-tests" && ./configure --arch=riscv64 && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/kvm-unit-tests && printf "%s\n" leetfs | sudo -S -p "" cp -a . /opt/kvm-unit-tests/'
  else
    install_result kvm-unit-tests SKIP '/dev/kvm is absent'
  fi
  if [ "$RUN_LTP" -eq 1 ]; then
    ensure_package ltp-build-tools 'command -v autoreconf && command -v pkg-config && command -v bison && command -v flex' 'autoconf automake pkg-config bison flex m4' 'autoconf automake pkgconf-pkg-config bison flex m4'
    ensure_package ltp 'command -v runltp || test -x /opt/ltp/runltp' ltp-testsuite ltp
    ensure_source ltp 'test -x /opt/ltp/runltp' 'git clone --depth 1 https://github.com/linux-test-project/ltp.git "$SOURCE_ROOT/ltp" && cd "$SOURCE_ROOT/ltp" && make autotools && ./configure --prefix=/opt/ltp --without-modules && make -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make install'
  fi
fi

if has_module stability && [ "$RUN_STRESS" -eq 1 ]; then
  ensure_package stress-ng 'command -v stress-ng' stress-ng stress-ng
  ensure_source stress-ng 'command -v stress-ng' 'git clone --depth 1 https://github.com/ColinIanKing/stress-ng.git "$SOURCE_ROOT/stress-ng" && make -C "$SOURCE_ROOT/stress-ng" -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" make -C "$SOURCE_ROOT/stress-ng" install'
fi

printf '\n## 测试结果\n\n| 分类 | 测试 | 状态 | 返回码 | 时长（秒） |\n|---|---|---:|---:|---:|\n' >> "$REPORT"
printf 'LAVA_AUTO_INSTALL_%s\n' DONE
