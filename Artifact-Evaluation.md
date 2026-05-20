# Artifact Evaluation Guide

This document is the top-level reviewer guide for:

**Transitive, Abstract, and Class Polymorphic Immutability**

The artifact has two independent evaluation tracks:

- **Rocq formalization**: `pico-rocq/` contains the mechanized formal model and proofs.
- **Checker Framework implementation**: `checker-framework/` contains the PICO checker implementation and benchmark tests. This track also uses `jdk/`, which contains the annotated OpenJDK sources for the Java Collections Framework case study.

## Common Docker Setup

The authors evaluated the artifact on macOS with Docker Desktop. The artifact should also run on a Linux host with Docker.

Recommended resources:

- 4 CPU cores
- 8 GB RAM
- 100 GB free disk space

Build the image from the repository root:

```bash
docker build -t pico-artifact:latest .
```

If an Ubuntu package mirror rejects the build because of temporary apt metadata or signature issues, retry with:

```bash
docker build --build-arg APT_INSECURE=true -t pico-artifact:latest .
```

Use the insecure apt build argument only as a fallback for mirror problems.

## Full Automated Evaluation

To run both tracks and keep the generated logs/tables on the host, run from the repository root:

```bash
mkdir -p results
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:latest
```

The container starts in `/workspace` and runs:

```text
/workspace/scripts/run-artifact.sh
```

which invokes:

```text
/workspace/scripts/evaluate.sh
```

The evaluation writes logs and generated tables to:

```text
./results
```

This host directory is mounted inside the container as `/workspace/results`.

On the authors' Docker Desktop run, a warm full evaluation after the image was already built took about 2-3 minutes. We recommend budgeting about 5 minutes for a warm run, and longer for a fully clean run that rebuilds Gradle or Rocq artifacts. The script records per-step timings in:

```text
./results/timings.tsv
./results/timings.md
```

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
- [Checker Framework artifact evaluation](Artifact-Evaluation-Checker.md)
