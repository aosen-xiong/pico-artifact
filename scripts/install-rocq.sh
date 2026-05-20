#!/usr/bin/env bash
set -euo pipefail

OPAM_SWITCH_NAME="${OPAM_SWITCH_NAME:-artifact-switch}"
OPAM_OCAML_COMPILER="${OPAM_OCAML_COMPILER:-5.2.1}"
ROCQ_CORE_VERSION="${ROCQ_CORE_VERSION:-9.1.1}"
ROCQ_STDLIB_VERSION="${ROCQ_STDLIB_VERSION:-9.0.0}"
COQ_CORE_VERSION="${COQ_CORE_VERSION:-${ROCQ_CORE_VERSION}}"
COQ_RECORD_UPDATE_REPO="${COQ_RECORD_UPDATE_REPO:-https://github.com/tchajed/coq-record-update.git}"
COQ_RECORD_UPDATE_DIR="${COQ_RECORD_UPDATE_DIR:-/tmp/coq-record-update}"

opam init --disable-sandboxing --bare -y
opam switch create "${OPAM_SWITCH_NAME}" "ocaml-base-compiler.${OPAM_OCAML_COMPILER}" -y

# shellcheck disable=SC1091
eval "$(opam env --switch="${OPAM_SWITCH_NAME}")"
opam update -y

unset COQLIB ROCQLIB || true
opam install -y \
  "coq-core.${COQ_CORE_VERSION}" \
  "rocq-core.${ROCQ_CORE_VERSION}" \
  "rocq-stdlib.${ROCQ_STDLIB_VERSION}"

rm -rf "${COQ_RECORD_UPDATE_DIR}"
git clone --depth 1 "${COQ_RECORD_UPDATE_REPO}" "${COQ_RECORD_UPDATE_DIR}"
pushd "${COQ_RECORD_UPDATE_DIR}" >/dev/null
make -j"$(nproc)"
make install
popd >/dev/null
rm -rf "${COQ_RECORD_UPDATE_DIR}"

opam clean -a -c -s --logs -y
