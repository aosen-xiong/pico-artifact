#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_PARENT="$(dirname "${REPO_ROOT}")"
REPO_NAME="$(basename "${REPO_ROOT}")"
OUTPUT="${1:-${REPO_PARENT}/${REPO_NAME}-anonymous.tar.gz}"

OUTPUT_DIR="$(dirname "${OUTPUT}")"
OUTPUT_BASE="$(basename "${OUTPUT}")"
mkdir -p "${OUTPUT_DIR}"
OUTPUT_ABS="$(cd "${OUTPUT_DIR}" && pwd)/${OUTPUT_BASE}"

EXCLUDES=(
  --exclude "${REPO_NAME}/.git"
  --exclude "${REPO_NAME}/.git/*"
  --exclude "${REPO_NAME}/.git*"
  --exclude "${REPO_NAME}/*/.git"
  --exclude "${REPO_NAME}/*/.git/*"
  --exclude "${REPO_NAME}/*/.git*"
  --exclude "${REPO_NAME}/**/.git"
  --exclude "${REPO_NAME}/**/.git/*"
  --exclude "${REPO_NAME}/**/.git*"
  --exclude "${REPO_NAME}/**/.DS_Store"
  --exclude "${REPO_NAME}/**/.idea"
  --exclude "${REPO_NAME}/**/.idea/*"
  --exclude "${REPO_NAME}/**/.vscode"
  --exclude "${REPO_NAME}/**/.vscode/*"
)

case "${OUTPUT_ABS}" in
  "${REPO_ROOT}"/*)
    REL_OUTPUT="${OUTPUT_ABS#"${REPO_PARENT}/"}"
    EXCLUDES+=(--exclude "${REL_OUTPUT}")
    ;;
esac

tar -czf "${OUTPUT_ABS}" "${EXCLUDES[@]}" -C "${REPO_PARENT}" "${REPO_NAME}"

echo "Created anonymous artifact archive:"
echo "  ${OUTPUT_ABS}"
echo
echo "Verify that no .git directories were included:"
echo "  tar -tzf ${OUTPUT_ABS} | grep -E '/\\.git(/|$)' || true"
