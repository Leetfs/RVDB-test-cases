update_package_index;
ensure_package build-essential 'command -v gcc && command -v make' build-essential 'gcc gcc-c++ make';
ensure_package git 'command -v git' git git;
ensure_package openssl 'command -v openssl' openssl openssl;
if [ "$RUN_SPEC" -eq 1 ]; then
  ensure_package download-tools 'command -v curl || command -v wget' curl curl;
  ensure_package archive-tools 'command -v tar && command -v xz' 'tar xz-utils' 'tar xz';
  ensure_package mount-tools 'command -v mount' mount util-linux;
fi;
if has_module info; then
  ensure_package ruapu 'command -v ruapu' ruapu ruapu;
  ensure_package mhz 'command -v mhz || ls /usr/lib/lmbench/bin/*/mhz >/dev/null 2>&1' lmbench lmbench;
  ensure_package es2-info 'command -v es2_info' mesa-utils-extra mesa-demos;
  ensure_package vulkaninfo 'command -v vulkaninfo' vulkan-tools vulkan-tools;
  ensure_package clinfo 'command -v clinfo' clinfo clinfo;
  ensure_package glxinfo 'command -v glxinfo' mesa-utils mesa-demos;
  ensure_package vainfo 'command -v vainfo' vainfo libva-utils;
  ensure_package vdpauinfo 'command -v vdpauinfo' vdpauinfo vdpauinfo;
  ensure_package v4l2 'command -v v4l2-ctl' v4l-utils v4l-utils;
  ensure_package ffmpeg 'command -v ffmpeg' ffmpeg ffmpeg;
  ensure_package gstreamer 'command -v gst-inspect-1.0' gstreamer1.0-tools gstreamer1-plugins-base-tools;
  ensure_source ruapu 'command -v ruapu' 'rm -rf /tmp/lava-src/ruapu; mkdir -p /tmp/lava-src; git clone --depth 1 https://github.com/nihui/ruapu.git /tmp/lava-src/ruapu && cd /tmp/lava-src/ruapu && gcc -O2 main.c -o ruapu && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 ruapu /usr/local/bin/ruapu';
fi;
if has_module cpu; then
  ensure_package 7zip 'command -v 7z' p7zip-full 'p7zip p7zip-plugins';
  ensure_package stockfish 'command -v stockfish || test -x /usr/games/stockfish' stockfish stockfish;
  ensure_package unixbench 'command -v byte-unixbench || test -x /usr/lib/byte-unixbench/Run' byte-unixbench byte-unixbench;
  ensure_package coremark-pro 'command -v coremark-pro || test -f /opt/coremark-pro/Makefile' coremark-pro coremark-pro;
  ensure_source coremark 'command -v coremark' 'rm -rf /tmp/lava-src/coremark; mkdir -p /tmp/lava-src; git clone --depth 1 https://github.com/eembc/coremark.git /tmp/lava-src/coremark && cd /tmp/lava-src/coremark && make PORT_DIR=linux64 && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 coremark.exe /usr/local/bin/coremark';
  ensure_source coremark-pro 'command -v coremark-pro' 'rm -rf /tmp/lava-src/coremark-pro; mkdir -p /tmp/lava-src; git clone --depth 1 https://github.com/eembc/coremark-pro.git /tmp/lava-src/coremark-pro && cd /tmp/lava-src/coremark-pro && make TARGET=linux64 build && printf "%s\n" leetfs | sudo -S -p "" mkdir -p /opt/coremark-pro && printf "%s\n" leetfs | sudo -S -p "" cp -a . /opt/coremark-pro/ && printf "%s\n" leetfs | sudo -S -p "" sh -c "printf '\''#!/bin/sh\\ncd /opt/coremark-pro || exit 1\\nexec make TARGET=linux64 XCMD=\\\"-c\$(nproc)\\\" certify-all\\n'\'' > /usr/local/bin/coremark-pro && chmod 0755 /usr/local/bin/coremark-pro"';
fi;
if has_module memory; then
  ensure_package tinymembench 'command -v tinymembench' tinymembench tinymembench;
  ensure_package lmbench 'command -v lat_syscall || ls /usr/lib/lmbench/bin/*/lat_syscall >/dev/null 2>&1' lmbench lmbench;
  ensure_package ramlat 'command -v ramlat' ramlat ramlat;
  ensure_package core-to-core-latency 'command -v core-to-core-latency' core-to-core-latency core-to-core-latency;
  ensure_package cargo 'command -v cargo' cargo 'cargo rust';
  ensure_source tinymembench 'command -v tinymembench' 'rm -rf /tmp/lava-src/tinymembench; mkdir -p /tmp/lava-src; git clone --depth 1 https://github.com/ssvb/tinymembench.git /tmp/lava-src/tinymembench && cd /tmp/lava-src/tinymembench && make && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 tinymembench /usr/local/bin/tinymembench';
  ensure_source stream 'command -v stream' 'rm -rf /tmp/lava-src/stream; mkdir -p /tmp/lava-src; git clone --depth 1 https://github.com/jeffhammond/STREAM.git /tmp/lava-src/stream && cd /tmp/lava-src/stream && gcc -O3 -fopenmp -DSTREAM_ARRAY_SIZE=10000000 -DNTIMES=10 stream.c -o stream && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 stream /usr/local/bin/stream';
  ensure_source core-to-core-latency 'command -v core-to-core-latency' 'rm -rf /tmp/lava-cargo; mkdir -p /tmp/lava-cargo; cargo install --root /tmp/lava-cargo core-to-core-latency && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 /tmp/lava-cargo/bin/core-to-core-latency /usr/local/bin/core-to-core-latency';
fi;
if has_module gpu; then
  ensure_package cmake 'command -v cmake' cmake cmake;
  ensure_package glmark2 'command -v glmark2-es2-drm || command -v glmark2-es2 || command -v glmark2' glmark2 glmark2;
  ensure_package vkmark 'command -v vkmark' vkmark vkmark;
  ensure_package vkpeak 'command -v vkpeak' vkpeak vkpeak;
  ensure_package clpeak 'command -v clpeak' clpeak clpeak;
  ensure_package gfxbench 'command -v gfxbench' gfxbench gfxbench;
  ensure_source vkpeak 'command -v vkpeak' 'rm -rf /tmp/lava-src/vkpeak; mkdir -p /tmp/lava-src; git clone --depth 1 --recurse-submodules https://github.com/nihui/vkpeak.git /tmp/lava-src/vkpeak && cmake -S /tmp/lava-src/vkpeak -B /tmp/lava-src/vkpeak/build && cmake --build /tmp/lava-src/vkpeak/build -j "$(nproc)" && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 /tmp/lava-src/vkpeak/build/vkpeak /usr/local/bin/vkpeak';
fi;
if has_module combined; then
  ensure_package unixbench 'command -v byte-unixbench || test -x /usr/lib/byte-unixbench/Run' byte-unixbench byte-unixbench;
  ensure_package lmbench 'command -v lat_syscall || ls /usr/lib/lmbench/bin/*/lat_syscall >/dev/null 2>&1' lmbench lmbench;
  ensure_source sbc-bench 'command -v sbc-bench' 'rm -rf /tmp/lava-src/sbc-bench; mkdir -p /tmp/lava-src; git clone --depth 1 https://github.com/ThomasKaiser/sbc-bench.git /tmp/lava-src/sbc-bench && printf "%s\n" leetfs | sudo -S -p "" install -m 0755 /tmp/lava-src/sbc-bench/sbc-bench.sh /usr/local/bin/sbc-bench';
  if [ "$RUN_PTS" -eq 1 ]; then
    ensure_package php 'command -v php' php-cli php-cli;
    ensure_package phoronix-test-suite 'command -v phoronix-test-suite' phoronix-test-suite phoronix-test-suite;
  fi;
fi;
if has_module storage; then
  ensure_package fio 'command -v fio' fio fio;
  ensure_package iozone 'command -v iozone' iozone3 iozone;
fi;
if has_module virt-kernel; then
  ensure_package kvm-unit-tests 'test -x /opt/kvm-unit-tests/run_tests.sh || test -x /usr/share/kvm-unit-tests/run_tests.sh' kvm-unit-tests kvm-unit-tests;
  if [ "$RUN_LTP" -eq 1 ]; then ensure_package ltp 'command -v runltp || test -x /opt/ltp/runltp' ltp-testsuite ltp; fi;
fi;
if has_module stability && [ "$RUN_STRESS" -eq 1 ]; then ensure_package stress-ng 'command -v stress-ng' stress-ng stress-ng; fi;
printf '\n## 测试结果\n\n| 分类 | 测试 | 状态 | 返回码 | 时长（秒） |\n|---|---|---:|---:|---:|\n' >> "$REPORT";
printf 'LAVA_AUTO_INSTALL_%s\n' DONE
