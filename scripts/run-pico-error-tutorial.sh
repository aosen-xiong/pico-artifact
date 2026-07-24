#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CHECKER_DIR="${CHECKER_DIR:-${WORKSPACE}/checker-framework}"
TUTORIAL_DIR="${TUTORIAL_DIR:-${WORKSPACE}/tutorial/pico-errors}"
OUTPUT_FILE="${1:-${TUTORIAL_DIR}/expected-output.txt}"
CLASSES_DIR="${CLASSES_DIR:-${WORKSPACE}/results/tutorial-classes}"

mkdir -p "${CLASSES_DIR}" "$(dirname "${OUTPUT_FILE}")"

cd "${CHECKER_DIR}"

if [[ ! -f checker/dist/checker.jar ]]; then
  cat >&2 <<EOF
Missing ${CHECKER_DIR}/checker/dist/checker.jar.

Build the Checker Framework javac wrapper first:

  cd ${CHECKER_DIR}
  bash ./gradlew --offline assembleforjavac

Then rerun:

  bash ${WORKSPACE}/scripts/run-pico-error-tutorial.sh ${OUTPUT_FILE}
EOF
  exit 1
fi

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
