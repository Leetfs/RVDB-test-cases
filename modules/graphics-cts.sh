if [ "$RUN_GRAPHICS_CTS" -eq 1 ]; then
  run_cmd graphics drm-modetest 10m 'command -v modetest && ls /dev/dri/card* >/dev/null 2>&1' 'modetest -c -e -p'
  run_cmd graphics piglit-quick 6h 'command -v piglit && test -n "${DISPLAY:-}"' 'piglit run --process-isolation false quick "$WORK_DIR/piglit-results"'
  run_cmd graphics opengl-cts 6h 'command -v deqp-gles2 && (test -n "${DISPLAY:-}" || ls /dev/dri/renderD* >/dev/null 2>&1)' 'deqp-gles2 --deqp-case="dEQP-GLES2.info.*"'
  run_cmd graphics vulkan-cts 6h 'command -v deqp-vk && command -v vulkaninfo && timeout 30s vulkaninfo --summary' 'deqp-vk --deqp-case="dEQP-VK.info.*"'
  run_cmd graphics opencl-cts 6h 'command -v test_basic && command -v clinfo && timeout 15s clinfo -l | grep -qi platform' 'test_basic'
else
  for test_name in drm-modetest piglit-quick opengl-cts vulkan-cts opencl-cts; do record_skip graphics "$test_name" 'RUN_GRAPHICS_CTS=0'; done
fi
