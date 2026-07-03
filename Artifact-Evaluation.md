# Artifact Evaluation Guide

This document is the top-level reviewer guide for:

**Transitive, Abstract, and Class Polymorphic Immutability**

The artifact has two independent evaluation tracks:

- **Rocq formalization**: `pico-rocq/` contains the mechanized formal model and proofs.
- **PICO implementation in a modified Checker Framework**: `checker-framework/` contains the PICO checker implementation and benchmark tests. This track also uses `jdk/`, which contains the annotated OpenJDK sources for the Java Collections Framework case study.

## Getting the Sources

Reviewers should start from the submitted artifact archive. The archive includes
all source trees used by the evaluation, including `pico-rocq/`,
`checker-framework/`, and `jdk/`. No additional Git clone
or submodule initialization step is required for evaluation.

Sanity check:

```bash
test -f pico-rocq/Makefile
test -f pico-rocq/_RocqProject
```

## Common Docker Setup

The authors evaluated the artifact on macOS with Docker Desktop. The artifact should also run on a Linux host with Docker.

Recommended resources:

- 4 CPU cores
- 8 GB RAM
- 15-20 GB free disk space

## Prebuilt Docker Images

The artifact submission may include Docker image archives next to the source
archive:

```text
pico-artifact-image-linux-amd64.docker.tar
pico-artifact-image-linux-arm64.docker.tar
pico-artifact-image-oci.tar
```

Use the platform-specific Docker archive for ordinary Docker workflows:

```bash
# x86_64 / Intel / AMD hosts
docker load -i pico-artifact-image-linux-amd64.docker.tar
rm -rf results
mkdir -p results
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-amd64
```

```bash
# Apple Silicon / ARM64 hosts
docker load -i pico-artifact-image-linux-arm64.docker.tar
rm -rf results
mkdir -p results
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-arm64
```

The `pico-artifact-image-oci.tar` file is a multi-platform OCI image archive
containing both `linux/amd64` and `linux/arm64` image manifests. It is included
as the build artifact corresponding to Docker's multi-platform image format.
Plain `docker load` expects Docker archive format, so the two
`*.docker.tar` files are provided for direct reviewer use.

The multi-platform image was built with:

```bash
docker buildx create --name pico-ae-builder --driver docker-container --use --bootstrap
docker buildx build \
  --builder pico-ae-builder \
  --platform linux/amd64,linux/arm64 \
  -t pico-artifact:ae-2026 \
  --output type=oci,dest=pico-artifact-image-oci.tar \
  .
```

The platform-specific Docker-loadable archives were exported with:

```bash
docker buildx build \
  --builder pico-ae-builder \
  --platform linux/amd64 \
  -t pico-artifact:ae-2026-amd64 \
  --output type=docker,dest=pico-artifact-image-linux-amd64.docker.tar \
  .

docker buildx build \
  --builder pico-ae-builder \
  --platform linux/arm64 \
  -t pico-artifact:ae-2026-arm64 \
  --output type=docker,dest=pico-artifact-image-linux-arm64.docker.tar \
  .
```

## Build Docker Locally

If the prebuilt image archives are unavailable, build the image from the
repository root:

```bash
docker build -t pico-artifact:latest .
```

The checked-out artifact is about 1 GB. The 15-20 GB recommendation leaves room for Docker image layers, Gradle build outputs, OPAM/Rocq dependencies, and generated evaluation results; it is not an observed minimum.

If an Ubuntu package mirror rejects the build because of temporary apt metadata or signature issues, retry with:

```bash
docker build --build-arg APT_INSECURE=true -t pico-artifact:latest .
```

Use the insecure apt build argument only as a fallback for mirror problems.

## Full Automated Evaluation

To run both tracks and keep the generated logs/tables on the host, run from the repository root:

```bash
rm -rf results
mkdir -p results
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:latest
```

The `rm -rf results` command removes stale output from previous runs so the new results are easy to inspect. Omit it if you want to keep an earlier run for comparison.

The container starts in `/workspace` and runs:

```text
/workspace/scripts/run-artifact.sh
```

which invokes:

```text
/workspace/scripts/evaluate.sh
```

The evaluation writes logs, generated tables, and rendered Rocq/Alectryon proof documentation to:

```text
./results
```

This host directory is mounted inside the container as `/workspace/results`.

On the authors' Docker Desktop run, a warm full evaluation after the image was already built took about 2-3 minutes. We recommend budgeting about 5 minutes for a warm run, and longer for a fully clean run that rebuilds Gradle or Rocq artifacts. The script records per-step timings in:

```text
./results/timings.tsv
./results/timings.md
```

The rendered Rocq proof documentation is available at:

```text
./results/rocq/alectryon/index.html
```

Open this file from the host system in a browser after the Docker run completes.

## Manual Evaluation

For manual inspection, start a shell:

```bash
docker run --rm -it --entrypoint bash pico-artifact:latest
```

Inside the container, the expected repository layout is:

```text
/workspace/checker-framework
/workspace/jdk
/workspace/pico-rocq
/workspace/scripts
```

Then follow either:

- [Rocq artifact evaluation](Artifact-Evaluation-Rocq.md)
- [PICO implementation artifact evaluation](Artifact-Evaluation-Checker.md)
