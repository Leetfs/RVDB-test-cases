# 测试覆盖矩阵

本文档记录 RVDB Linux 发行版测试仓库覆盖的领域、主要开源项目和执行边界。
所有基础测试均通过统一框架向 LAVA Results 上报 `pass`、`fail` 或 `skip`。

## 默认覆盖

| 领域 | 测试与框架 |
|---|---|
| 系统信息 | uname、os-release、lscpu、cpuinfo、设备树、RISC-V ISA、MMU、CPUFreq、ruapu、mhz |
| 图形/媒体能力 | PVR debugfs、es2_info、glxinfo、vulkaninfo、clinfo、vainfo、vdpauinfo、V4L2、FFmpeg、GStreamer |
| 发行版健康 | dpkg/rpm 数据库、ldconfig、systemd failed units/boot analysis、locale、timedatectl、cgroup、findmnt |
| CPU | CoreMark、CoreMark-PRO、UnixBench、OpenSSL、7-Zip、Stockfish、SPEC CPU 2017 |
| 内存 | tinymembench、ramlat、core-to-core-latency、STREAM、lmbench |
| GPU | glmark2、vkmark、vkpeak、clpeak、GFXBench（需授权介质） |
| 存储 | fio、iozone |
| 综合 | BYTE UnixBench、lmbench、sbc-bench |
| 工具链 | GCC C/C++/Fortran/OpenMP、Clang |
| 语言运行时 | Rust、Go、Python、Perl、Java、Node.js、PHP |
| 网络 | IPv4/IPv6 loopback、路由、namespace/veth、iperf3、netperf、sockperf、qperf、ethtool |
| 容器 | user namespace、runc、crun、containerd、Podman、Docker |
| 安全 | seccomp、Linux capabilities、user namespace、LSM、audit、checksec、Lynis |
| 实时性 | cyclictest、perf hackbench、oslat、hwlatdetect |
| 多媒体 | FFmpeg H.264/HEVC 编解码、GStreamer audio/video pipeline、v4l2-compliance |
| 文件系统 | tmpfs、OverlayFS、fsx、pjdfstest |
| 内核 | kselftest、KUnit、perf bench、bpftool、LTP、kvm-unit-tests |
| 稳定性 | 温度监控、可选 stress-ng 烤机 |
| PTS | 11 个领域共 72 个开源 profile，详见 `config/pts/*.list` |

## PTS 领域

- CPU/HPC：CoreMark、Stockfish、Sysbench、C-Ray、SciMark、Fhourstones、
  Primesieve、PolyBench-C、GMPbench、NPB、XSBench、miniFE。
- 密码学：OpenSSL、GnuPG、libgcrypt、Crypto++、SMHasher、SecureMark。
- 压缩：7-Zip、gzip、LZ4、pbzip2、XZ、Zstd。
- 内存：STREAM、tinymembench、RAMspeed、CacheBench、pmbench、t-test1、
  core-latency、stream-dynamic。
- 存储：fio、iozone、SQLite、FS-Mark、PostMark、dbench、CompileBench、
  pjdfstest、IOR。
- 工具链：Linux kernel build/unpack、LLVM、Mesa、MPlayer、PHP、Python build。
- 运行时：pyperformance、PHPBench、Go、Perl、Rust Prime、Rust Mandelbrot。
- 多媒体：x264、x265、FFmpeg、rav1e。
- 服务端：Redis、Nginx、PostgreSQL pgbench、SQLite speedtest、Apache、
  Memcached、ClickHouse。
- 内核：perf-bench、schbench、IPC benchmark、stress-ng。
- 网络：network-loopback、sockperf、iperf。

## 条件性深度测试

| 测试 | 开启条件 | 保护措施 |
|---|---|---|
| xfstests | `RUN_DESTRUCTIVE=1`、`XFSTESTS_TEST_DEV`、`XFSTESTS_SCRATCH_DEV` | 只允许使用明确指定的专用设备 |
| blktests | `RUN_DESTRUCTIVE=1`、`BLKTESTS_DEVICES` | 不自动选择系统盘 |
| Piglit/Khronos CTS | `RUN_GRAPHICS_CTS=1` | 先探测显示、DRM、Vulkan/OpenCL runtime |
| OpenSCAP | `RUN_OPENSCAP=1`、`OPENSCAP_CONTENT`、`OPENSCAP_PROFILE` | 不自动下载或猜测安全基线 |
| stress-ng 烤机 | `RUN_STRESS=1` | 默认关闭，时长由 `STRESS_SECONDS` 控制 |
| 容器镜像运行 | `RUN_CONTAINER_IMAGES=1` | Podman 使用 Job 私有 root/runroot；Docker 仅清理由本次 Job 新拉取的镜像 |

## 开源上游

主要使用 Linux kernel kselftest/KUnit、LTP/Kirk、kvm-unit-tests、xfstests、
blktests、Phoronix Test Suite、OpenBenchmarking、Piglit、Khronos VK-GL-CTS、
OpenCL-CTS、OpenSCAP、Lynis、Podman、OCI runc/crun、rt-tests、FFmpeg、
GStreamer、v4l-utils、fio、iozone、netperf、sockperf 和 qperf。

若发行版包管理器无法提供对应项目，安装模块会在项目存在受支持源码构建方式时
继续尝试上游源码。硬件、内核配置、安全策略或授权介质缺失时必须上报 `skip`，
不能用安装软件伪造硬件能力。

完整 Job 的上限为 120 小时，PTS 独立 Job 为 72 小时。单项测试仍有更短的独立
超时，因此某个项目卡住不会永久阻塞后续领域。
