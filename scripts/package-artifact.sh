#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_PARENT="$(dirname "${REPO_ROOT}")"
REPO_NAME="$(basename "${REPO_ROOT}")"
OUTPUT="${1:-${REPO_PARENT}/${REPO_NAME}.tar.gz}"

if [[ ! -f "${REPO_ROOT}/pico-rocq/Makefile" || ! -f "${REPO_ROOT}/pico-rocq/_RocqProject" ]]; then
  echo "error: pico-rocq sources are missing" >&2
  echo "expected pico-rocq/Makefile and pico-rocq/_RocqProject before packaging" >&2
  exit 1
fi

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
  --exclude "${REPO_NAME}/.DS_Store"
  --exclude "${REPO_NAME}/**/.DS_Store"
  --exclude "${REPO_NAME}/._*"
  --exclude "${REPO_NAME}/**/._*"
  --exclude "${REPO_NAME}/**/.idea"
  --exclude "${REPO_NAME}/**/.idea/*"
  --exclude "${REPO_NAME}/**/.vscode"
  --exclude "${REPO_NAME}/**/.vscode/*"
  --exclude "${REPO_NAME}/results"
  --exclude "${REPO_NAME}/results/*"
  --exclude "${REPO_NAME}/release"
  --exclude "${REPO_NAME}/release/*"
  --exclude "${REPO_NAME}/output"
  --exclude "${REPO_NAME}/output/*"
  --exclude "${REPO_NAME}/tmp"
  --exclude "${REPO_NAME}/tmp/*"
  --exclude "${REPO_NAME}/PICOPaper"
  --exclude "${REPO_NAME}/PICOPaper/*"
  --exclude "${REPO_NAME}/Rocq-Paper-Review-Prompt.md"
  --exclude "${REPO_NAME}/pico-artifact*.tar.gz"
  --exclude "${REPO_NAME}/pico-artifact-image-*"
  --exclude "${REPO_NAME}/checker-framework/.gradle"
  --exclude "${REPO_NAME}/checker-framework/.gradle/*"
  --exclude "${REPO_NAME}/checker-framework/**/build"
  --exclude "${REPO_NAME}/checker-framework/**/build/*"
  --exclude "${REPO_NAME}/checker-framework/**/*.fdb_latexmk"
  --exclude "${REPO_NAME}/checker-framework/**/*.fls"
  --exclude "${REPO_NAME}/checker-framework/**/*.log"
  --exclude "${REPO_NAME}/pico-rocq/CoqMakefile"
  --exclude "${REPO_NAME}/pico-rocq/CoqMakefile.conf"
  --exclude "${REPO_NAME}/pico-rocq/.CoqMakefile.d"
  --exclude "${REPO_NAME}/pico-rocq/.Makefile.d"
  --exclude "${REPO_NAME}/pico-rocq/*.vo"
  --exclude "${REPO_NAME}/pico-rocq/*.vos"
  --exclude "${REPO_NAME}/pico-rocq/*.vok"
  --exclude "${REPO_NAME}/pico-rocq/*.glob"
  --exclude "${REPO_NAME}/pico-rocq/*.aux"
  --exclude "${REPO_NAME}/pico-rocq/.*.aux"
  --exclude "${REPO_NAME}/pico-rocq/_build"
  --exclude "${REPO_NAME}/pico-rocq/_build/*"
  --exclude "${REPO_NAME}/pico-rocq/_opam"
  --exclude "${REPO_NAME}/pico-rocq/_opam/*"
  --exclude "${REPO_NAME}/pico-rocq/alectryon"
  --exclude "${REPO_NAME}/pico-rocq/alectryon/*"
  --exclude "${REPO_NAME}/pico-rocq/doc"
  --exclude "${REPO_NAME}/pico-rocq/doc/*"
  --exclude "${REPO_NAME}/pico-rocq/.local"
  --exclude "${REPO_NAME}/pico-rocq/.local/*"
)

case "${OUTPUT_ABS}" in
  "${REPO_ROOT}"/*)
    REL_OUTPUT="${OUTPUT_ABS#"${REPO_PARENT}/"}"
    EXCLUDES+=(--exclude "${REL_OUTPUT}")
    ;;
esac

# Prevent macOS tar from serializing extended attributes as AppleDouble
# sidecar files such as ._PaperFigureExamples.java.
COPYFILE_DISABLE=1 tar -czf "${OUTPUT_ABS}" "${EXCLUDES[@]}" -C "${REPO_PARENT}" "${REPO_NAME}"

if tar -tzf "${OUTPUT_ABS}" | grep -Eq '(^|/)\._[^/]*$'; then
  echo "error: archive contains macOS AppleDouble metadata files" >&2
  exit 1
fi

echo "Created artifact archive:"
echo "  ${OUTPUT_ABS}"
echo
echo "Verify that no .git directories were included:"
echo "  tar -tzf ${OUTPUT_ABS} | grep -E '/\\.git(/|$)' || true"
