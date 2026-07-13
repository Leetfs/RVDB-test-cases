if [ "$RUN_TOOLCHAINS" -eq 1 ]; then
  run_cmd toolchain gcc-c 10m 'command -v gcc' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" c'
  run_cmd toolchain gcc-cpp 10m 'command -v g++' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" cpp'
  run_cmd toolchain gfortran 10m 'command -v gfortran' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" fortran'
  run_cmd toolchain openmp 10m 'command -v gcc' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" openmp'
  run_cmd toolchain clang 10m 'command -v clang' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" clang'
  run_cmd runtime rust 10m 'command -v rustc' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" rust'
  run_cmd runtime go 10m 'command -v go' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" go'
  run_cmd runtime python 10m 'command -v python3' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" python'
  run_cmd runtime perl 10m 'command -v perl' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" perl'
  run_cmd runtime java 10m 'command -v javac && command -v java' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" java'
  run_cmd runtime nodejs 10m 'command -v node' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" node'
  run_cmd runtime php 10m 'command -v php' 'bash "$ROOT_DIR/scripts/toolchain-smoke.sh" php'
else
  for test_name in gcc-c gcc-cpp gfortran openmp clang rust go python perl java nodejs php; do record_skip toolchain "$test_name" 'RUN_TOOLCHAINS=0'; done
fi
