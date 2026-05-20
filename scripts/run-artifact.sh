#!/usr/bin/env bash
set -euo pipefail

cd /workspace

echo "=== Environment ==="
java -version || true
opam --version || true
opam exec -- coqc --version || true

echo
echo "Place your artifact runner in /workspace/scripts/evaluate.sh"
if [[ -x /workspace/scripts/evaluate.sh ]]; then
  exec /workspace/scripts/evaluate.sh
else
  exec bash
fi
