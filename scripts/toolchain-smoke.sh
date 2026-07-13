#!/usr/bin/env bash
set -euo pipefail

language="${1:?language is required}"
work="${WORK_DIR:?WORK_DIR is required}/toolchain-$language"
mkdir -p "$work"
cd "$work"

case "$language" in
  c)
    printf '#include <stdio.h>\nint main(void){puts("c-ok");return 0;}\n' > main.c
    gcc -O2 -Wall -Wextra -Werror main.c -o main
    test "$(./main)" = c-ok
    ;;
  cpp)
    printf '#include <iostream>\nint main(){std::cout << "cpp-ok\\n";}\n' > main.cpp
    g++ -std=c++17 -O2 -Wall -Wextra -Werror main.cpp -o main
    test "$(./main)" = cpp-ok
    ;;
  fortran)
    printf 'program main\nprint *, "fortran-ok"\nend program main\n' > main.f90
    gfortran -O2 -Wall -Werror main.f90 -o main
    ./main | grep -q fortran-ok
    ;;
  openmp)
    printf '#include <omp.h>\n#include <stdio.h>\nint main(void){int n=0;\n#pragma omp parallel reduction(+:n)\nn+=1; printf("threads=%d\\n",n);}\n' > main.c
    gcc -O2 -fopenmp main.c -o main
    ./main | grep -Eq 'threads=[1-9][0-9]*'
    ;;
  clang)
    printf '#include <stdio.h>\nint main(void){puts("clang-ok");}\n' > main.c
    clang -O2 -Wall -Wextra -Werror main.c -o main
    test "$(./main)" = clang-ok
    ;;
  rust)
    printf 'fn main(){println!("rust-ok");}\n' > main.rs
    rustc -O main.rs -o main
    test "$(./main)" = rust-ok
    ;;
  go)
    printf 'package main\nimport "fmt"\nfunc main(){fmt.Println("go-ok")}\n' > main.go
    go build -o main main.go
    test "$(./main)" = go-ok
    ;;
  python)
    printf 'import json, sqlite3, ssl\nassert json.loads("{\\"ok\\": true}")["ok"]\nassert sqlite3.connect(":memory:").execute("select 1").fetchone()[0] == 1\nprint(ssl.OPENSSL_VERSION)\n' > main.py
    python3 main.py
    ;;
  perl)
    perl -MJSON::PP -MDigest::SHA=sha256_hex -e 'print encode_json({ok => 1}), " ", sha256_hex("linux"), "\n"'
    ;;
  java)
    printf 'public class Main { public static void main(String[] a) { System.out.println("java-ok"); } }\n' > Main.java
    javac Main.java
    test "$(java Main)" = java-ok
    ;;
  node)
    node -e 'const crypto=require("crypto"); console.log(crypto.createHash("sha256").update("linux").digest("hex"))'
    ;;
  php)
    php -r '$x=json_decode("{\"ok\":true}", true); if (!$x["ok"]) exit(1); echo OPENSSL_VERSION_TEXT, "\n";'
    ;;
  *)
    printf 'unsupported language: %s\n' "$language" >&2
    exit 2
    ;;
esac
