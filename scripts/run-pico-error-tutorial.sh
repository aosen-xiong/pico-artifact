#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CHECKER_DIR="${CHECKER_DIR:-${WORKSPACE}/checker-framework}"
TUTORIAL_DIR="${TUTORIAL_DIR:-${WORKSPACE}/tutorial/pico-errors}"
OUTPUT_FILE="${1:-${TUTORIAL_DIR}/expected-output.txt}"
CLASSES_DIR="${CLASSES_DIR:-${WORKSPACE}/results/tutorial-classes}"

mkdir -p "${CLASSES_DIR}" "$(dirname "${OUTPUT_FILE}")"

cd "${CHECKER_DIR}"

: > "${OUTPUT_FILE}"
for file in "${TUTORIAL_DIR}"/*.java; do
  {
    printf '== %s ==\n' "$(basename "${file}")"
    sh ./checker/bin/javac -processor pico \
      -Xmaxerrs 200 -Xlint:none -Alint=-all \
      -d "${CLASSES_DIR}" \
      "../tutorial/pico-errors/$(basename "${file}")"
  } >> "${OUTPUT_FILE}" 2>&1 || true
done

printf 'Wrote %s\n' "${OUTPUT_FILE}"
