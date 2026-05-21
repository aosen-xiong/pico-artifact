# PICO Artifact

This repository contains the artifact for **Transitive, Abstract, and Class Polymorphic Immutability**.

Start with the artifact evaluation guide:

- [Artifact-Evaluation.md](Artifact-Evaluation.md)

The artifact has two evaluation tracks:

- [Rocq formalization](Artifact-Evaluation-Rocq.md): mechanized model and proofs in `pico-rocq/`.
- [PICO implementation in a modified Checker Framework](Artifact-Evaluation-Checker.md): PICO checker, tests, benchmarks, and annotated JDK case study.

For a short guide to PICO type-check errors, see [PICO-Error-Message-Tutorial.md](PICO-Error-Message-Tutorial.md). It includes focused files under `tutorial/pico-errors/` that reviewers can compile directly.

Quick start:

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
