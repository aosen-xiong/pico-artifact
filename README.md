# PICO Artifact

This repository contains the artifact for **Transitive, Abstract, and Class Polymorphic Immutability**.

Start with the artifact evaluation guide:

- [Artifact-Evaluation.md](Artifact-Evaluation.md)

The submitted artifact package includes all source trees needed for evaluation,
including the Rocq sources under `pico-rocq/`. Reviewers should not need to
clone any additional repositories.

The artifact has two evaluation tracks:

- [Rocq formalization](Artifact-Evaluation-Rocq.md): mechanized model and proofs in `pico-rocq/`.
- [PICO implementation in a modified Checker Framework](Artifact-Evaluation-Checker.md): PICO checker, tests, benchmarks, and annotated JDK case study.

The Rocq track mechanizes all four protection modes (AS, CS, RS, and TS). The
Checker Framework track evaluates the implemented PICO qualifier system and its
AS-style viewpoint adaptation; it does not implement the four method-scope
annotations from the core formal model.

For a short guide to PICO type-check errors, see [PICO-Error-Message-Tutorial.md](PICO-Error-Message-Tutorial.md). It includes focused files under `tutorial/pico-errors/` that reviewers can compile directly.

For extending the checker or formalization, see [REUSABILITY.md](REUSABILITY.md).
Licensing information for the artifact and its bundled upstream components is
summarized in [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).

Quick start:

If the prebuilt Docker image archives are included with the submission, load the
archive for your host platform first:

```bash
# x86_64 / Intel / AMD hosts
docker load -i pico-artifact-image-linux-amd64.docker.tar
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-amd64

# Apple Silicon / ARM64 hosts
docker load -i pico-artifact-image-linux-arm64.docker.tar
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:ae-2026-arm64
```

Otherwise, build the image locally from the packaged sources:

```bash
docker build -t pico-artifact:latest .
rm -rf results
mkdir -p results
docker run --rm -it \
  -v "$PWD/results:/workspace/results" \
  pico-artifact:latest
```

The evaluation outputs are preserved on the host under `./results`.

On the authors' Docker Desktop run, the image build took about 8 minutes. A warm automated evaluation after the image is built takes about 2-3 minutes.
