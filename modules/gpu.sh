if [ "$RUN_GPU" -eq 1 ]; then
  run_cmd gpu glmark2 1h '(command -v glmark2-es2-drm && ls /dev/dri/card* /dev/dri/renderD* >/dev/null 2>&1) || ((command -v glmark2-es2 || command -v glmark2) && test -n "${DISPLAY:-}")' 'if command -v glmark2-es2-drm >/dev/null; then glmark2-es2-drm; elif command -v glmark2-es2 >/dev/null; then glmark2-es2 --off-screen; else glmark2 --off-screen; fi';
  run_cmd gpu vkmark 1h 'command -v vkmark && command -v vulkaninfo && timeout 30s vulkaninfo --summary' 'vkmark';
  run_cmd gpu vkpeak 1h 'command -v vkpeak && command -v vulkaninfo && timeout 30s vulkaninfo --summary' 'vkpeak';
  run_cmd gpu clpeak 1h 'command -v clpeak && command -v clinfo && timeout 15s clinfo -l | grep -qi platform' 'clpeak';
  run_cmd gpu gfxbench 2h 'command -v gfxbench && (ls /dev/dri/card* /dev/dri/renderD* >/dev/null 2>&1 || test -n "${DISPLAY:-}")' 'gfxbench';
else
  record_skip gpu glmark2 'RUN_GPU=0';
  record_skip gpu vkmark 'RUN_GPU=0';
  record_skip gpu vkpeak 'RUN_GPU=0';
  record_skip gpu clpeak 'RUN_GPU=0';
  record_skip gpu gfxbench 'RUN_GPU=0';
fi;
printf 'LAVA_GPU_BENCHMARKS_%s\n' DONE
