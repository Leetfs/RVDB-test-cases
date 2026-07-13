# RVDB Linux 发行版 LAVA 测试用例

本仓库提供面向多架构 Linux 发行版和开发板的模块化 LAVA 测试套件，K1 是
当前参考设备。只需向 LAVA
提交一个主 Job，LAVA dispatcher 会通过官方的
`test.definitions.from: git` 机制获取本仓库，并按照 Lava-Test Test
Definition 1.0 规范执行全部测试模块。

## 目录结构

- `k1-full-benchmark.yaml`：提交到 LAVA UI 的主 Job。
- `k1-pts-benchmark.yaml`：只运行 PTS 常规测试的独立 Job。
- `lava/k1-full.yaml`：由 LAVA 从 Git 获取并执行的测试定义。
- `config/defaults.env`：自动安装、测试开关和运行参数。
- `config/pts/*.list`：按领域维护的 PTS 开源测试目录及档位。
- `config/cpu2017-1_0_5.iso.sha256`：SPEC CPU 2017 v1.0.5 官方哈希。
- `profiles/*.env`：各测试方案包含的模块及执行顺序。
- `scripts/run-profile.sh`：测试方案运行入口。
- `lib/harness.sh`：超时、依赖安装、报告和 LAVA 结果上报框架。
- `lib/spec.sh`：SPEC CPU 2017 探测、下载、校验、安装和初始化逻辑。
- `modules/*.sh`：按测试领域拆分的独立模块。
- `docs/coverage.md`：全部测试领域、开源框架和安全边界清单。

## Git 仓库

主 Job 使用以下仓库地址：

```yaml
- repository: https://github.com/Leetfs/RVDB-test-cases.git
  from: git
  path: lava/k1-full.yaml
  name: k1-full-results
```

该地址必须能从 LAVA dispatcher 访问。如果以后改成私有仓库，应在
dispatcher 侧配置凭据，不要把访问令牌写入 Job YAML。

## 运行方法

在 LAVA UI 中提交 `k1-full-benchmark.yaml`。Job 连接开发板当前 shell，必要时
自动登录 `leetfs`，但不会执行前置重启。随后 LAVA 获取并执行
`lava/k1-full.yaml`。测试定义最终运行：

```bash
bash ../scripts/run-profile.sh full
```

`full` 方案依次执行：

```text
info distro toolchain cpu memory gpu graphics-cts multimedia network filesystem
container security realtime kernel-extra combined pts storage virt-kernel stability
```

也可以在仓库检出目录中手动执行某个方案：

```bash
bash scripts/run-profile.sh cpu
```

## 自动安装

测试开始前会自动识别 `apt-get` 或 `dnf`，刷新对应的软件源，并使用各发行版
对应的包名安装缺失程序。如果发行版没有对应软件包，且项目具有受支持的公开
源码构建方式，则继续尝试下载源码、编译并安装。

每次运行使用独立的 `/tmp/lava-k1-benchmark-<job-id>` 工作目录。正常完成、
测试失败、超时或人工取消都会触发清理；独立清理守护进程会在测试 shell 被
直接终止时兜底删除源码树、日志、SPEC 临时介质和存储测试文件。下次启动还会
先清理历史版本遗留的 `/tmp/lava-*` 测试文件。

主 Job 通过 LAVA `context.lava_test_results_dir` 将测试 overlay 和结果目录放在
`/home/leetfs/lava-<job-id>`，与清理守护进程使用同一路径，不会在根目录创建
`/lava-<job-id>`。

硬件接口和内核接口无法通过软件包补齐，例如设备树节点、PVR debugfs、温度
节点和 `/dev/kvm`。GFXBench 等授权软件也只能使用发行版已有软件包或已授权的
安装介质。这些条件不存在时测试向 LAVA 上报 `skip`，而不是 `fail`。

`sbc-bench` 使用 root 和 `MODE=unattended` 运行，不读取“建议重启”的交互确认，
因此适合无人值守 Job。

## 扩展覆盖

`full` 当前包含 19 个模块、114 个非 PTS 测试入口和 72 个 PTS profile，基础
testcase 规模约 186 项；kselftest、LTP、KUnit、xfstests、Piglit 和 Khronos CTS
等框架还会在内部产生更多子用例。详细矩阵见 `docs/coverage.md`。

除原有性能测试外，现已覆盖：

- 发行版健康：包数据库、动态链接器、systemd、locale、时区、挂载和 cgroup。
- 工具链/运行时：GCC C/C++/Fortran/OpenMP、Clang、Rust、Go、Python、Perl、
  Java、Node.js、PHP。
- 内核：kselftest、KUnit、LTP、perf bench、BPF feature probe、KVM unit tests。
- 网络：IPv4/IPv6、network namespace/veth、iperf3、netperf、sockperf、qperf、
  ethtool。
- 文件系统/块设备：tmpfs、OverlayFS、fsx、pjdfstest、xfstests、blktests。
- 容器：user namespace、runc、crun、containerd、Podman、Docker。
- 安全：seccomp、capabilities、LSM、audit、checksec、Lynis、OpenSCAP。
- 实时性：cyclictest、hackbench、oslat、hwlatdetect。
- 多媒体：FFmpeg H.264/HEVC、GStreamer 音视频、v4l2-compliance。
- 图形一致性：DRM modetest、Piglit、OpenGL ES CTS、Vulkan CTS、OpenCL CTS。

默认不执行可能破坏数据或耗时极长的测试。xfstests/blktests 必须设置
`RUN_DESTRUCTIVE=1` 并提供专用测试设备；完整图形 CTS 需设置
`RUN_GRAPHICS_CTS=1`；OpenSCAP 需要显式提供内容和 profile。所有临时挂载、
网络 namespace、容器存储和生成文件均位于本次 Job 工作目录并带清理逻辑。

## Phoronix Test Suite

`pts` 是独立模块，面向多架构 Linux 发行版验证。测试目录按 CPU、密码学、
压缩、内存、存储、工具链、语言运行时、多媒体、服务端、内核和网络共 11 个
领域拆分，当前共收录 72 个开源 profile。

通过 `PTS_TIER` 选择运行深度：

- `smoke`：11 项，适合每次构建后的快速冒烟测试。
- `standard`：49 项，覆盖常见发行版性能与功能场景。
- `extended`：72 项，默认值，增加 LLVM/Mesa/PHP/Python 编译、HPC、数据库和网络等长测。

默认配置为：

```env
PTS_TIER=extended
PTS_GROUPS='cpu crypto compression memory storage toolchain runtime multimedia server kernel network'
PTS_TESTS=
PTS_TIMES_TO_RUN=1
PTS_TEST_TIMEOUT=4h
```

每个 profile 分别通过 `default-benchmark` 非交互运行，使用 profile 的默认测试
配置。每项测试会生成独立的 LAVA testcase，例如 `pts-coremark`、`pts-fio`，
一个 profile 失败不会阻止后续项。PTS 声明当前 OS 或 CPU 架构不支持的测试，
以及当前仓库不存在的 profile，会记录为 `skip`，不会制造无意义的 `fail`。

profile 完成后会通过 PTS 官方 `result-file-to-json` 导出结构化结果。脚本读取其中
的 `value` 和 `scale`，将每种测试配置的实际性能值及单位作为额外 testcase
measurement 写入同一个 LAVA suite。完整控制台输出保留在 Job 日志中，JSON
原文位于本次 Job 临时目录并在解析完成后随其它测试文件统一清理。

PTS 命令返回 0 但没有生成 JSON，或 JSON 中没有任何数值测量项时，该测试仍按
执行失败处理，不能仅凭进程退出码上报 pass。这样每个 `pts-*` pass testcase
都至少对应一个实际进入 LAVA Results 的性能 measurement。

PTS 下载、编译、安装和结果目录均位于当前 Job 的临时工作目录，完成、失败或
取消后都会清理。`PTS_TESTS` 非空时会覆盖目录选择，可用于精确指定一组 profile；
设置 `RUN_PTS=0` 可关闭。只运行 PTS 时，可在 LAVA UI 提交
`k1-pts-benchmark.yaml`，或在仓库目录手动执行：

```bash
bash scripts/run-profile.sh pts
```

例如只跑快速测试、只跑内核与工具链，或执行完整目录：

```bash
PTS_TIER=smoke bash scripts/run-profile.sh pts
PTS_GROUPS='kernel toolchain' bash scripts/run-profile.sh pts
PTS_TIER=extended bash scripts/run-profile.sh pts
```

目录文件每行由 `profile tier` 组成。新增项目时优先选择源码开放、可自动下载、
可非交互执行且支持多架构的 profile；依赖专有介质、外部服务或特定硬件的项目
应放入 `extended`，并保留明确的探测与 `skip` 行为。

## 结果上报

所有可执行测试必须使用：

```bash
run_cmd CATEGORY TEST_NAME TIMEOUT PROBE COMMAND
```

关闭、授权受限或前置条件不满足的测试使用：

```bash
record_skip CATEGORY TEST_NAME REASON
```

两个函数都会更新 Markdown 报告并调用 `lava-test-case`。每项测试都会直接写入
`k1-full-results` suite，包含 pass、fail 或 skip 状态和运行时长。超时在详细
报告中记录为 `TIMEOUT`，在 LAVA suite 中记录为 fail。

所有基础结果和 measurement 都通过统一上报函数写入 LAVA Results。单条写入
失败时自动重试 3 次并继续后续测试；Job 结束时只要仍有任何结果未成功写入，
测试 shell 就返回非零状态，避免出现日志执行完成但 Results 缺项的静默成功。

基础测试通过后，`lib/metrics.sh` 会解析该测试的独立输出文件，并把性能值作为
额外的 testcase measurement 写入同一个 suite。例如：

```text
cpu-coremark-score
cpu-unixbench-index-score
cpu-stockfish-nodes-per-second
ram-stream-copy
gpu-glmark2-score
gpu-vkpeak-fp32-scalar
storage-fio-read-iops
stability-thermal-after-thermal-zone0
```

当前结构化指标覆盖 CoreMark、CoreMark-PRO、UnixBench、OpenSSL、7-Zip、
Stockfish、SPEC CPU 2017、CPU 实测频率、tinymembench、ramlat、
core-to-core-latency、STREAM、glmark2、vkmark、vkpeak、clpeak、GFXBench、
lmbench、fio、iozone、温度和 stress-ng。指标会附带实际单位，可用于 LAVA
结果查询和趋势图。无法稳定解析的工具输出仍完整保留在 Job 日志中，不会提交
不可靠的 measurement。

## SPEC CPU 2017

设置 `RUN_SPEC=1` 后，运行器会查找现有 CPU 2017 安装目录、加载 `shrc`、优先
选择 `k1*.cfg`，否则选择第一个可用配置，并展开默认命令：

```env
SPEC2017_CMD='runcpu --config=auto --size=ref intrate fprate'
```

如果板子尚未安装 CPU 2017，默认从以下地址下载 v1.0.5 ISO：

```env
SPEC2017_MEDIA_URL='https://smallquilt.quilt.idv.tw:8923/ouo/support/SPEC%20CPU%202017/CPU%202017%201.0.5.iso'
SPEC2017_SHA256_FILE=config/cpu2017-1_0_5.iso.sha256
```

SHA256 校验是强制步骤。只有 ISO 与仓库中保存的 SPEC 官方哈希一致时才会挂载
和安装。没有配置下载地址时，也会检查 `/opt/spec-media`、`/srv/spec` 和
`/home/leetfs/spec-media` 下的 CPU 2017 ISO 或 tar 介质。

默认安装目录是 `/home/leetfs/spec2017`。CPU2017 1.0.5 介质不包含 RISC-V
预编译工具集；检测到 `riscv64` 时，初始化器会将只读 ISO 复制到本次 Job 工作
目录，解包 `tools-src` 并执行官方 `tools/src/buildtools`，成功后再运行安装器。
首次构建可能耗时数小时，正常结束、失败或人工取消后都会清理 ISO、副本和构建
目录。

如需覆盖自动流程，可设置 `SPEC2017_INSTALL_CMD`；执行时会提供
`SPEC_MEDIA_DIR` 和 `SPEC_INSTALL_ROOT` 环境变量。

## 新增模块

1. 新建 `modules/<name>.sh`，测试必须使用 `run_cmd` 或 `record_skip`。
2. 在 `modules/install.sh` 对应的 `has_module` 分支中加入依赖安装逻辑。
3. 将模块名加入需要使用它的 `profiles/*.env`。

新增测试模块不需要修改主 LAVA YAML。
