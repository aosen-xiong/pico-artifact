#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
RESULTS_DIR="${RESULTS_DIR:-${WORKSPACE}/results}"
CHECKER_RESULTS_DIR="${RESULTS_DIR}/checker"
ROCQ_RESULTS_DIR="${RESULTS_DIR}/rocq"
COUNTS_RESULTS_DIR="${RESULTS_DIR}/counts"
ROCQ_ALECTRYON_DIR="${ROCQ_RESULTS_DIR}/alectryon"
TIMINGS_FILE="${RESULTS_DIR}/timings.tsv"
TIMINGS_MD="${RESULTS_DIR}/timings.md"
JDK_UTIL_DIR="${WORKSPACE}/jdk/src/java.base/share/classes/java/util"
TYPECHECKED_LIST="${JDK_UTIL_DIR}/TypecheckedList.txt"

mkdir -p "${CHECKER_RESULTS_DIR}" "${ROCQ_RESULTS_DIR}" "${COUNTS_RESULTS_DIR}"
printf 'step\tseconds\n' > "${TIMINGS_FILE}"

record_timing() {
  local step="$1"
  local seconds="$2"
  printf '%s\t%s\n' "${step}" "${seconds}" >> "${TIMINGS_FILE}"
}

format_seconds() {
  local seconds="$1"
  printf '%dm %02ds' "$((seconds / 60))" "$((seconds % 60))"
}

run_logged() {
  local step="$1"
  shift
  local log_file="$1"
  shift

  echo "+ $*" | tee "${log_file}"
  local start
  start="$(date +%s)"
  "$@" >> "${log_file}" 2>&1
  local status=$?
  local end
  end="$(date +%s)"
  local elapsed=$((end - start))
  record_timing "${step}" "${elapsed}"
  echo "Completed ${step} in $(format_seconds "${elapsed}")"
  return "${status}"
}

echo "=== Smoke Test ==="
java -version
opam --version
opam exec -- rocq -v
ls -d "${WORKSPACE}/checker-framework" "${WORKSPACE}/jdk" "${WORKSPACE}/pico-rocq"
count_java_annotations.pl --help > "${COUNTS_RESULTS_DIR}/count_java_annotations-help.txt"

echo
echo "=== Step 1: Checker Framework / JDK Evaluation ==="
cd "${WORKSPACE}/checker-framework"

run_logged "assembleforjavac" "${CHECKER_RESULTS_DIR}/assembleforjavac.log" bash ./gradlew assembleforjavac

mapfile -t JDK_UTIL_FILES < <(sed 's#^#'"${JDK_UTIL_DIR}"'/#' "${TYPECHECKED_LIST}")

JDK_CHECKER_START="$(date +%s)"
set +e
./checker/bin/javac -processor pico \
  --patch-module java.base="${WORKSPACE}/jdk/src/java.base" \
  --add-reads java.base=ALL-UNNAMED \
  -Xmaxerrs 5000 \
  -Xlint:none \
  -Alint=-all \
  -XDignore.symbol.file=true \
  -AassumeInitialized \
  "${JDK_UTIL_FILES[@]}" \
  > "${CHECKER_RESULTS_DIR}/compile.log" 2>&1
JDK_CHECKER_STATUS=$?
set -e
JDK_CHECKER_END="$(date +%s)"
JDK_CHECKER_SECONDS=$((JDK_CHECKER_END - JDK_CHECKER_START))
record_timing "jdk-checker" "${JDK_CHECKER_SECONDS}"

cp "${CHECKER_RESULTS_DIR}/compile.log" "${WORKSPACE}/checker-framework/compile.log"
printf '%s\n' "${JDK_CHECKER_STATUS}" > "${CHECKER_RESULTS_DIR}/compile.exit-status"

echo "JDK checker exit status: ${JDK_CHECKER_STATUS}"
echo "JDK checker log: ${CHECKER_RESULTS_DIR}/compile.log"
echo "Completed JDK checker in $(format_seconds "${JDK_CHECKER_SECONDS}")"

if [[ "${JDK_CHECKER_STATUS}" -ne 0 ]]; then
  echo "JDK checker failed; see ${CHECKER_RESULTS_DIR}/compile.log"
  exit "${JDK_CHECKER_STATUS}"
fi

run_logged "PICOConstrictorTest" "${CHECKER_RESULTS_DIR}/PICOConstrictorTest.log" bash ./gradlew PICOConstrictorTest
run_logged "PICOMutableDefaultTest" "${CHECKER_RESULTS_DIR}/PICOMutableDefaultTest.log" bash ./gradlew PICOMutableDefaultTest

echo
echo "=== Step 2: Annotation and Suppression Counts ==="
cd "${JDK_UTIL_DIR}"

COUNTS_START="$(date +%s)"
count_java_annotations.pl -l \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico \
  -f TypecheckedList.txt \
  > "${COUNTS_RESULTS_DIR}/java-util-annotation-counts.tex"

count_java_annotations.pl -t \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico \
  -f TypecheckedList.txt \
  > "${COUNTS_RESULTS_DIR}/java-util-annotation-counts.csv"

count_java_annotations.pl \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico \
  -f TypecheckedList.txt \
  > "${COUNTS_RESULTS_DIR}/java-util-annotation-counts.txt"
COUNTS_END="$(date +%s)"
COUNTS_SECONDS=$((COUNTS_END - COUNTS_START))
record_timing "annotation-counts" "${COUNTS_SECONDS}"

echo "Annotation count outputs: ${COUNTS_RESULTS_DIR}"
echo "Completed annotation counts in $(format_seconds "${COUNTS_SECONDS}")"

echo
echo "=== Step 3: Rocq Evaluation ==="
cd "${WORKSPACE}/pico-rocq"

# Regenerate build files inside the container. A checked-out artifact may contain
# CoqMakefile files produced on a different host with absolute OPAM paths.
rm -f CoqMakefile CoqMakefile.conf .CoqMakefile.d .Makefile.d
rm -f ./*.vo ./*.vos ./*.vok ./*.glob ./*.aux ./.*.aux

# Some archive hosts preserve upload timestamps that are ahead of the Docker
# container clock. Normalize source mtimes so make does not repeatedly
# regenerate CoqMakefile because _RocqProject appears to be in the future.
find . -maxdepth 1 \( -name '*.v' -o -name '_RocqProject' -o -name 'Makefile' \) \
  -exec touch -c {} +

run_logged "rocq-make" "${ROCQ_RESULTS_DIR}/make.log" opam exec -- make
run_logged "rocq-make-check" "${ROCQ_RESULTS_DIR}/make-check.log" opam exec -- make check
run_logged "rocq-alectryon-doc" "${ROCQ_RESULTS_DIR}/alectryon-doc.log" \
  opam exec -- make ALECTRYON_DIR="${ROCQ_ALECTRYON_DIR}" alectryon-doc

{
  printf '| Step | Time |\n'
  printf '| --- | ---: |\n'
  tail -n +2 "${TIMINGS_FILE}" | while IFS=$'\t' read -r step seconds; do
    printf '| `%s` | %s |\n' "${step}" "$(format_seconds "${seconds}")"
  done
} > "${TIMINGS_MD}"

echo
echo "=== Step 4: Summary ==="
cat > "${RESULTS_DIR}/summary.txt" <<EOF
Artifact evaluation completed.

Checker Framework / JDK:
  assembleforjavac log: ${CHECKER_RESULTS_DIR}/assembleforjavac.log
  JDK checker log: ${CHECKER_RESULTS_DIR}/compile.log
  JDK checker exit status: ${JDK_CHECKER_STATUS}
  PICOConstrictorTest log: ${CHECKER_RESULTS_DIR}/PICOConstrictorTest.log
  PICOMutableDefaultTest log: ${CHECKER_RESULTS_DIR}/PICOMutableDefaultTest.log

Annotation counts:
  LaTeX: ${COUNTS_RESULTS_DIR}/java-util-annotation-counts.tex
  CSV: ${COUNTS_RESULTS_DIR}/java-util-annotation-counts.csv
  Text: ${COUNTS_RESULTS_DIR}/java-util-annotation-counts.txt

Rocq:
  make log: ${ROCQ_RESULTS_DIR}/make.log
  make check log: ${ROCQ_RESULTS_DIR}/make-check.log
  Alectryon HTML: ${ROCQ_ALECTRYON_DIR}/index.html
  Alectryon log: ${ROCQ_RESULTS_DIR}/alectryon-doc.log

Timings:
  TSV: ${TIMINGS_FILE}
  Markdown: ${TIMINGS_MD}
EOF

cat "${RESULTS_DIR}/summary.txt"
echo
echo "Results directory: ${RESULTS_DIR}"
