# Artifact Evaluation Guide

This document is the top-level reviewer guide for:

**Transitive, Abstract, and Class Polymorphic Immutability**

The artifact has two independent evaluation tracks:

- **Rocq formalization**: `pico-rocq/` contains the mechanized formal model and proofs.
- **PICO implementation in a modified Checker Framework**: `checker-framework/` contains the PICO checker implementation and benchmark tests. This track also uses `jdk/`, which contains the annotated OpenJDK sources for the Java Collections Framework case study.

The Rocq model covers the AS, CS, RS, and TS method scopes. The Checker
Framework implementation covers the PICO qualifier system and AS-style
viewpoint adaptation used in the case studies; the four method-scope
annotations are not part of the Java implementation.

The artifact performs no telemetry or analytics and does not contact the
authors. The prebuilt image can be evaluated without network access.

## Files to Download

Download the following before starting:

1. `pico-artifact-oopsla26.tar.gz`, containing the source trees, evaluation
   scripts, expected results, and Markdown documentation.
2. Exactly one prebuilt image archive for the reviewer's host:
   `pico-artifact-image-linux-amd64.docker.tar` for x86_64/Intel/AMD hosts, or
   `pico-artifact-image-linux-arm64.docker.tar` for Apple Silicon/ARM64 hosts.
3. The Markdown evaluation guides (`Artifact-Evaluation.md`,
   `Artifact-Evaluation-Checker.md`, `Artifact-Evaluation-Rocq.md`, and
   `REUSABILITY.md`) if they are not already available through the HotCRP
   submission or the extracted source archive.

Docker Desktop was used for the authors' macOS/ARM64 validation. The images
run an Ubuntu 24.04 userspace and contain OpenJDK 17, Gradle-resolved Checker
Framework dependencies, OPAM, OCaml 5.2.1, Rocq 9.1.1, and Alectryon 2.0.0.
No host installation of those tools is needed.

## Kick-the-Tires Evaluation (about 5–10 minutes, excluding downloads)

Download and extract `pico-artifact-oopsla26.tar.gz`, then download the
Docker archive matching the host architecture. Place the Docker archive next
to the extracted `pico-artifact/` directory and run one of the following from
that directory:

```bash
# x86_64 / Intel / AMD hosts
docker load -i ../pico-artifact-image-linux-amd64.docker.tar
mkdir -p results
docker run --rm -it \
  --network none \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-amd64
```

```bash
# Apple Silicon / ARM64 hosts
docker load -i ../pico-artifact-image-linux-arm64.docker.tar
mkdir -p results
docker run --rm -it \
  --network none \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-arm64
```

The run should exit with status `0`, print `Artifact evaluation completed.`,
and write `results/summary.txt`. The automated evaluation fails if the checker
tests, benchmark totals, Rocq build, proof-hygiene checks, public-theorem
assumption audit, or Alectryon rendering do not match the expected results.
The detailed output is retained under `results/`; begin with
`results/summary.txt` and `results/timings.md`.

If a prebuilt image cannot be loaded, follow [Build Docker
Locally](#build-docker-locally) before running the same container command with
the image name `pico-artifact:latest`.

## Claims Supported by the Artifact

This table is the reviewer checklist connecting the paper's significant
artifact-supported claims to evaluation steps. The two track-specific guides
give the detailed commands and theorem premises.

| Paper claim and location | Artifact evidence | Evaluation step |
|---|---|---|
| Section 5.1 (Implementation): the PICO Checker implements the qualifier hierarchy, viewpoint adaptation, initialization integration, and class mutability polymorphism. | Checker sources and enabled regression suites. | Run `PICOConstrictorTest` and `PICOMutableDefaultTest` as described in [Artifact-Evaluation-Checker.md](Artifact-Evaluation-Checker.md). |
| Section 5.2, Case Study 1, and Appendix B.1: PICO type-checks the evaluated 52-file JCF corpus. | Annotated OpenJDK sources and `TypecheckedList.txt`. | Run the JDK checker command; it must exit `0` without PICO errors. |
| Section 5.2, Case Study 1, and Appendix B.1: the reported JCF annotation totals are reproducible. | `count_java_annotations.pl` and the evaluated file manifest. | Generate the JCF table and compare its total with `expected-results/benchmark-totals.csv`. |
| Section 5.2, Case Studies 2 and 3, and Appendices B.2-B.3: PICO type-checks the Constrictor and Checker Framework case studies with the reported annotation totals. | Benchmark sources, enabled Gradle suites, and counting script. | Run both suites and compare both generated totals with `expected-results/benchmark-totals.csv`. |
| Section 4.4, Theorem 1: the core calculus satisfies preservation and mutation safety. | `Preservation.v` and `WFNOMutationEXP.v`. | Build the Rocq development and inspect the corresponding entries in [Artifact-Evaluation-Rocq.md](Artifact-Evaluation-Rocq.md). |
| Section 4.5, Theorem 2: the core calculus satisfies shallow abstract immutability. | `AbstractStatePreservation.v`. | Build Rocq and inspect `shallow_abstract_immutability`. |
| Section 4.5, Theorem 3: the core calculus satisfies the AS and CS guarantees. | `AbstractStatePreservation.v`, `ConcreteState.v`, and `ConcreteStatePreservation.v`. | Build Rocq and inspect `abstract_state_preservation` and `concrete_state_preservation`. |
| Section 4.5, Theorem 4: the core calculus satisfies the RS and TS guarantees. | `ReadonlyStatePreservation.v` and `TransitiveStatePreservation.v`. | Build Rocq and inspect `readonly_state_preservation` and `transitive_state_preservation`. |
| Submitted Rocq sources contain no literal `Axiom`, `Admitted`, or `admit` commands. | Proof-hygiene script. | Run `opam exec -- make check`; compare the message with `expected-results/proof-hygiene.txt`. |

The artifact does not claim that the Java checker implements the four
method-scope annotations; that claim is confined to the Rocq model. See
[REUSABILITY.md](REUSABILITY.md) for extension guidance and limitations.

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

The supplied image uses Ubuntu 24.04 and contains all build dependencies. Its
evaluation entry point does not require network access.

Recommended resources:

- 4 CPU cores
- 8 GB RAM
- 15-20 GB free disk space

## Prebuilt Docker Images

The artifact submission includes two Docker image archives next to the source
archive:

```text
pico-artifact-image-linux-amd64.docker.tar
pico-artifact-image-linux-arm64.docker.tar
```

Download and use the Docker archive matching the host architecture:

```bash
# x86_64 / Intel / AMD hosts
docker load -i pico-artifact-image-linux-amd64.docker.tar
rm -rf results
mkdir -p results
docker run --rm -it \
  --network none \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-amd64
```

```bash
# Apple Silicon / ARM64 hosts
docker load -i pico-artifact-image-linux-arm64.docker.tar
rm -rf results
mkdir -p results
docker run --rm -it \
  --network none \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-arm64
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

Building the image requires network access to install and cache all dependencies. Running the completed image does not require network access.

The checked-out artifact is about 1 GB. The 15-20 GB recommendation leaves room for Docker image layers, Gradle build outputs, OPAM/Rocq dependencies, and generated evaluation results; it is not an observed minimum.

## Full Automated Evaluation

To run both tracks and keep the generated logs/tables on the host, run from the repository root:

```bash
rm -rf results
mkdir -p results
docker run --rm -it \
  --network none \
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

For a compact baseline independent of a particular run, compare the generated
summary and count files with `expected-results/`.

## Manual Evaluation

For manual inspection, start a shell:

```bash
docker run --rm -it \
  --network none \
  --entrypoint bash \
  pico-artifact:latest
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

For reuse beyond reproducing the paper, see [REUSABILITY.md](REUSABILITY.md).
