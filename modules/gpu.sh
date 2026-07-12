if [ "$RUN_GPU" -eq 1 ]; then
  run_cmd gpu glmark2 1h 'command -v glmark2-es2-drm || command -v glmark2-es2 || command -v glmark2' 'if command -v glmark2-es2-drm >/dev/null; then glmark2-es2-drm; elif command -v glmark2-es2 >/dev/null; then glmark2-es2 --off-screen; else glmark2 --off-screen; fi';
  run_cmd gpu vkmark 1h 'command -v vkmark' 'vkmark';
  run_cmd gpu vkpeak 1h 'command -v vkpeak' 'vkpeak';
  run_cmd gpu clpeak 1h 'command -v clpeak' 'clpeak';
  run_cmd gpu gfxbench 2h 'command -v gfxbench' 'gfxbench';
else
  record_skip gpu glmark2 'RUN_GPU=0';
  record_skip gpu vkmark 'RUN_GPU=0';
  record_skip gpu vkpeak 'RUN_GPU=0';
  record_skip gpu clpeak 'RUN_GPU=0';
  record_skip gpu gfxbench 'RUN_GPU=0';
fi;
printf 'LAVA_GPU_BENCHMARKS_%s\n' DONE
