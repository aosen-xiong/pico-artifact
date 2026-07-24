#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_BASE="${ZENODO_API_BASE:-https://zenodo.org/api}"
STATE_FILE="${ZENODO_STATE_FILE:-${REPO_ROOT}/output/zenodo-version-draft.json}"
SOURCE_DEPOSITION_ID="${ZENODO_SOURCE_DEPOSITION_ID:-21513422}"
VERSION_LABEL="${ZENODO_VERSION:-1.0.1}"
COMMAND="${1:-draft}"

if [[ -z "${ZENODO_ACCESS_TOKEN:-}" ]]; then
  echo "error: ZENODO_ACCESS_TOKEN is not set" >&2
  echo "source the file that defines it, then rerun this script" >&2
  exit 1
fi

for command in curl jq md5 stat; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "error: required command not found: ${command}" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "${STATE_FILE}")"

CURL_CONFIG="$(mktemp "${TMPDIR:-/tmp}/pico-zenodo-curl.XXXXXX")"
chmod 600 "${CURL_CONFIG}"
trap 'rm -f "${CURL_CONFIG}"' EXIT
printf 'header = "Authorization: Bearer %s"\n' "${ZENODO_ACCESS_TOKEN}" > "${CURL_CONFIG}"

api_json() {
  curl --fail --show-error --silent \
    --config "${CURL_CONFIG}" \
    -H "Content-Type: application/json" \
    "$@"
}

create_draft() {
  if [[ -f "${STATE_FILE}" ]]; then
    echo "Using existing draft state: ${STATE_FILE}"
    return
  fi

  local response
  response="$(mktemp "${TMPDIR:-/tmp}/pico-zenodo-create.XXXXXX")"
  api_json -X POST -d '{}' "${API_BASE}/deposit/depositions" > "${response}"

  jq '{
    id: .id,
    bucket: .links.bucket,
    self: .links.self,
    html: (.links.latest_draft_html // .links.html),
    publish: .links.publish,
    reserved_doi: .metadata.prereserve_doi.doi
  }' "${response}" > "${STATE_FILE}"
  rm -f "${response}"

  echo "Created Zenodo draft $(jq -r '.id' "${STATE_FILE}")"
  echo "Draft URL: $(jq -r '.html' "${STATE_FILE}")"
}

save_draft_state() {
  local response_file="$1"

  jq '{
    id: .id,
    bucket: .links.bucket,
    self: .links.self,
    html: (.links.latest_draft_html // .links.html),
    publish: .links.publish,
    reserved_doi: .metadata.prereserve_doi.doi
  }' "${response_file}" > "${STATE_FILE}"
}

create_version_draft() {
  if [[ -f "${STATE_FILE}" ]]; then
    echo "Using existing version-draft state: ${STATE_FILE}"
    return
  fi

  local original_response latest_draft draft_response
  original_response="$(mktemp "${TMPDIR:-/tmp}/pico-zenodo-new-version.XXXXXX")"
  draft_response="$(mktemp "${TMPDIR:-/tmp}/pico-zenodo-version-draft.XXXXXX")"

  api_json -X POST \
    "${API_BASE}/deposit/depositions/${SOURCE_DEPOSITION_ID}/actions/newversion" \
    > "${original_response}"
  latest_draft="$(jq -r '.links.latest_draft' "${original_response}")"
  if [[ -z "${latest_draft}" || "${latest_draft}" == "null" ]]; then
    echo "error: Zenodo did not return a latest_draft link" >&2
    rm -f "${original_response}" "${draft_response}"
    exit 1
  fi

  api_json "${latest_draft}" > "${draft_response}"
  save_draft_state "${draft_response}"
  rm -f "${original_response}" "${draft_response}"

  echo "Created Zenodo version draft $(jq -r '.id' "${STATE_FILE}")"
  echo "Draft URL: $(jq -r '.html' "${STATE_FILE}")"
}

update_metadata() {
  local deposition_id metadata_file
  deposition_id="$(jq -r '.id' "${STATE_FILE}")"
  metadata_file="$(mktemp "${TMPDIR:-/tmp}/pico-zenodo-metadata.XXXXXX")"

  jq -n --arg version "${VERSION_LABEL}" '{
    metadata: {
      upload_type: "software",
      publication_date: "2026-07-23",
      title: "Artifact for Transitive, Abstract, and Class Polymorphic Immutability",
      description: (
        "<h1>Artifact for &quot;Transitive, Abstract, and Class Polymorphic Immutability&quot;</h1>" +
        "<p>This record contains the artifact for the OOPSLA 2026 paper " +
        "&quot;Transitive, Abstract, and Class Polymorphic Immutability.&quot;</p>" +
        "<p>The artifact includes the PICO implementation in a modified Checker Framework, " +
        "annotated OpenJDK sources and benchmark case studies, the Rocq mechanization of the " +
        "formal model and proofs, automated evaluation scripts, expected results, complete " +
        "evaluation documentation, and prebuilt container images for AMD64 and ARM64 hosts.</p>" +
        "<h2>Licensing</h2>" +
        "<p>This is a mixed-license artifact. Artifact-specific documentation, evaluation " +
        "scripts, tutorial material, and original PICO material are released under the MIT " +
        "License. The <code>pico-rocq/</code> formalization is released under the MIT License. " +
        "The bundled Checker Framework is primarily GPL version 2 with the Classpath Exception, " +
        "with selected components under MIT. The annotated OpenJDK sources retain the OpenJDK " +
        "GPL version 2 with the Classpath Exception and their bundled third-party notices. " +
        "The root <code>LICENSE</code>, <code>THIRD-PARTY-LICENSES.md</code>, and license files " +
        "within each source subtree state the exact terms; this Zenodo record does not replace " +
        "or relicense those components.</p>" +
        "<h2>Getting started</h2>" +
        "<p>Download <code>pico-artifact-oopsla26.tar.gz</code>, " +
        "the Markdown evaluation guides, and exactly one platform-specific Docker archive. " +
        "Use the AMD64 archive for Intel/AMD hosts and the ARM64 archive for Apple Silicon " +
        "or other ARM64 hosts. Start with <code>Artifact-Evaluation.md</code>; the Checker, " +
        "Rocq, and reusability guides provide the detailed evaluation instructions.</p>"
      ),
      creators: [
        {
          name: "Xiong, Aosen",
          affiliation: "University of Waterloo",
          orcid: "0009-0006-7362-7412"
        },
        {
          name: "Bai, Yudi",
          affiliation: "University of Waterloo",
          orcid: "0009-0007-8346-5071"
        },
        {
          name: "Shi, Haifeng",
          affiliation: "University of Waterloo",
          orcid: "0009-0000-5947-8867"
        },
        {name: "Sun, Lian", affiliation: "University of Waterloo"},
        {
          name: "Ta, Mier",
          affiliation: "University of Waterloo",
          orcid: "0009-0002-9944-2302"
        },
        {
          name: "Dietl, Werner",
          affiliation: "University of Waterloo",
          orcid: "0000-0002-9316-6952"
        }
      ],
      access_right: "open",
      license: "other-open",
      version: $version,
      prereserve_doi: true,
      keywords: [
        "immutability",
        "type systems",
        "program analysis",
        "Checker Framework",
        "Rocq",
        "artifact evaluation"
      ],
      notes: (
        "This record uses Other Open because it contains components under multiple open-source " +
        "licenses. Artifact-specific and pico-rocq material is MIT licensed. Checker Framework " +
        "and OpenJDK-derived components retain their respective GPLv2 with Classpath Exception " +
        "and other applicable terms. See LICENSE, THIRD-PARTY-LICENSES.md, and the license files " +
        "within the source archive for the authoritative file-level terms."
      )
    }
  }' > "${metadata_file}"

  api_json -X PUT \
    --data-binary "@${metadata_file}" \
    "${API_BASE}/deposit/depositions/${deposition_id}" >/dev/null
  rm -f "${metadata_file}"
  echo "Updated draft metadata"
}

upload_file() {
  local source_path="$1"
  local remote_name="$2"
  local bucket response expected_size uploaded_size expected_md5 uploaded_md5

  if [[ ! -f "${source_path}" ]]; then
    echo "error: upload file not found: ${source_path}" >&2
    exit 1
  fi

  bucket="$(jq -r '.bucket' "${STATE_FILE}")"
  response="$(mktemp "${TMPDIR:-/tmp}/pico-zenodo-upload.XXXXXX")"
  expected_size="$(stat -f '%z' "${source_path}")"
  expected_md5="$(md5 -q "${source_path}")"

  echo "Uploading ${remote_name} ($(du -h "${source_path}" | awk '{print $1}'))"
  curl --fail --show-error --progress-bar \
    --config "${CURL_CONFIG}" \
    --upload-file "${source_path}" \
    "${bucket}/${remote_name}" > "${response}"

  uploaded_size="$(jq -r '.size' "${response}")"
  uploaded_md5="$(jq -r '.checksum' "${response}" | sed 's/^md5://')"
  rm -f "${response}"
  if [[ "${uploaded_size}" != "${expected_size}" ]]; then
    echo "error: uploaded size mismatch for ${remote_name}" >&2
    echo "expected ${expected_size}, Zenodo reported ${uploaded_size}" >&2
    exit 1
  fi
  if [[ "${uploaded_md5}" != "${expected_md5}" ]]; then
    echo "error: uploaded checksum mismatch for ${remote_name}" >&2
    echo "expected md5:${expected_md5}, Zenodo reported md5:${uploaded_md5}" >&2
    exit 1
  fi
  echo "Verified ${remote_name}: ${uploaded_size} bytes, md5:${uploaded_md5}"
}

delete_file_if_present() {
  local remote_name="$1"
  local deposition_id file_url

  deposition_id="$(jq -r '.id' "${STATE_FILE}")"
  file_url="$(
    api_json "${API_BASE}/deposit/depositions/${deposition_id}" |
      jq -r --arg name "${remote_name}" \
        '.files[] | select((.filename // .key) == $name) | .links.self' |
      head -n 1
  )"
  if [[ -z "${file_url}" ]]; then
    echo "${remote_name} is not present; nothing to remove"
    return
  fi

  curl --fail --show-error --silent \
    --config "${CURL_CONFIG}" \
    -X DELETE "${file_url}" >/dev/null
  echo "Removed ${remote_name}"
}

upload_markdown_docs() {
  upload_file "${REPO_ROOT}/Artifact-Evaluation.md" "Artifact-Evaluation.md"
  upload_file "${REPO_ROOT}/Artifact-Evaluation-Checker.md" \
    "Artifact-Evaluation-Checker.md"
  upload_file "${REPO_ROOT}/Artifact-Evaluation-Rocq.md" \
    "Artifact-Evaluation-Rocq.md"
  upload_file "${REPO_ROOT}/REUSABILITY.md" "REUSABILITY.md"
}

upload_all() {
  upload_file "${REPO_ROOT}/README.md" "README.md"
  upload_file "${REPO_ROOT}/LICENSE" "LICENSE"
  upload_file "${REPO_ROOT}/THIRD-PARTY-LICENSES.md" "THIRD-PARTY-LICENSES.md"
  upload_markdown_docs
  upload_file "${REPO_ROOT}/release/pico-artifact-oopsla26.tar.gz" \
    "pico-artifact-oopsla26.tar.gz"
  upload_file "${REPO_ROOT}/release/pico-artifact-image-linux-amd64.docker.tar" \
    "pico-artifact-image-linux-amd64.docker.tar"
  upload_file "${REPO_ROOT}/release/pico-artifact-image-linux-arm64.docker.tar" \
    "pico-artifact-image-linux-arm64.docker.tar"
  upload_file "${REPO_ROOT}/release/SHA256SUMS" "SHA256SUMS"
}

show_status() {
  local deposition_id
  deposition_id="$(jq -r '.id' "${STATE_FILE}")"
  api_json "${API_BASE}/deposit/depositions/${deposition_id}" |
    jq '{
      id,
      title,
      version: .metadata.version,
      state,
      submitted,
      doi: (.doi // .metadata.prereserve_doi.doi),
      html: (.links.latest_draft_html // .links.html),
      files: [
        .files[] |
        {
          name: (.filename // .key),
          size: (.size // .filesize),
          checksum
        }
      ]
    }'
}

publish_draft() {
  local publish_url
  publish_url="$(jq -r '.publish' "${STATE_FILE}")"
  echo "Publishing is permanent for this version."
  echo "Rerun with: $0 publish-confirmed"
  exit 2
}

publish_confirmed() {
  local publish_url
  publish_url="$(jq -r '.publish' "${STATE_FILE}")"
  api_json -X POST "${publish_url}" |
    jq '{doi, doi_url, record_url, state, submitted}'
}

case "${COMMAND}" in
  new-version)
    create_version_draft
    update_metadata
    show_status
    echo
    echo "Version ${VERSION_LABEL} draft ready: $(jq -r '.html' "${STATE_FILE}")"
    echo "No files were uploaded and the draft was not published."
    ;;
  prepare)
    create_draft
    update_metadata
    show_status
    echo
    echo "Draft metadata ready for review: $(jq -r '.html' "${STATE_FILE}")"
    echo "No files were uploaded and the record was not published."
    ;;
  upload)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    upload_all
    show_status
    echo
    echo "Files uploaded to draft: $(jq -r '.html' "${STATE_FILE}")"
    echo "The record was not published."
    ;;
  upload-amd64)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    upload_file "${REPO_ROOT}/release/pico-artifact-image-linux-amd64.docker.tar" \
      "pico-artifact-image-linux-amd64.docker.tar"
    show_status
    echo "The record was not published."
    ;;
  upload-arm64)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    upload_file "${REPO_ROOT}/release/pico-artifact-image-linux-arm64.docker.tar" \
      "pico-artifact-image-linux-arm64.docker.tar"
    show_status
    echo "The record was not published."
    ;;
  upload-source)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    upload_file "${REPO_ROOT}/release/pico-artifact-oopsla26.tar.gz" \
      "pico-artifact-oopsla26.tar.gz"
    show_status
    echo "The record was not published."
    ;;
  refresh-readme)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    upload_file "${REPO_ROOT}/release/pico-artifact-oopsla26.tar.gz" \
      "pico-artifact-oopsla26.tar.gz"
    upload_file "${REPO_ROOT}/README.md" "README.md"
    show_status
    echo "The source archive and README were updated; the record was not published."
    ;;
  replace-pdf-with-markdown)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    upload_file "${REPO_ROOT}/release/pico-artifact-oopsla26.tar.gz" \
      "pico-artifact-oopsla26.tar.gz"
    upload_markdown_docs
    delete_file_if_present "artifact-documentation.pdf"
    update_metadata
    show_status
    echo "The source archive and Markdown guides were updated; the PDF was removed."
    echo "The record was not published."
    ;;
  draft)
    create_draft
    update_metadata
    upload_all
    show_status
    echo
    echo "Draft ready for review: $(jq -r '.html' "${STATE_FILE}")"
    echo "This script did not publish the record."
    ;;
  status)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    show_status
    ;;
  publish)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    publish_draft
    ;;
  publish-confirmed)
    [[ -f "${STATE_FILE}" ]] || { echo "error: no draft state found" >&2; exit 1; }
    publish_confirmed
    ;;
  *)
    echo "usage: $0 [new-version|prepare|upload|upload-source|refresh-readme|upload-amd64|upload-arm64|replace-pdf-with-markdown|draft|status|publish|publish-confirmed]" >&2
    exit 1
    ;;
esac
