# Rocq Artifact Evaluation Guide

This document gives reviewer-facing instructions for reproducing the Rocq formalization track for:

**Transitive, Abstract, and Class Polymorphic Immutability**

The Rocq artifact is in:

```text
pico-rocq/
```

It contains the mechanized formal model and proofs. The main validation task is to build the Rocq development and, optionally, run the stronger no-axioms/no-admits check. Reviewers can use the claim map below to connect paper-level claims to the corresponding Rocq theorem statements.

Build and start the Docker container as described in [Artifact-Evaluation.md](Artifact-Evaluation.md). Then run the commands below inside the container. The Rocq development is at:

```text
/workspace/pico-rocq
```

## 1. Claim Map

| Paper reference | Paper-level claim / premise | Mechanized premise in Rocq | Proved guarantee | Rocq theorem / file |
|---|---|---|---|---|
| Theorem 1 | Preservation | Initial runtime config is well-formed; statement is well-typed; statement evaluates successfully with result `OK` | Final runtime config is well-formed | `preservation_pico` in [Preservation.v](pico-rocq/Preservation.v) |
| Theorem 1 safety support | Mutation exception cannot arise for well-typed field writes | Runtime config is well-formed; field write is well-typed; assume it evaluates to `MUTATIONEXP` | Contradiction: a well-typed field write cannot produce the mutation exception | `well_typed_no_mutation_exp` in [WFNOMutationEXP.v](pico-rocq/WFNOMutationEXP.v) |
| Theorem 1 support | Big-step evaluation determinism | The same expression or statement evaluates twice from the same initial configuration | The two evaluations produce the same result/configuration | `eval_expr_deterministic` and `eval_stmt_deterministic` in [Bigstep.v](pico-rocq/Bigstep.v) |
| Theorem 1 support | Local variable declaration preserves well-formedness | `SLocal T x` is well-typed and evaluates by `eval_stmt` | Extending runtime/static environments with the local binding preserves `wf_r_config` | `preservation_local_ok` in [Properties.v](pico-rocq/Properties.v) |
| Theorem 1 support | Variable assignment preserves well-formedness | `SVarAss x e` is well-typed and evaluates by `eval_stmt` | Updating `x` with the evaluated value preserves `wf_r_config` | `preservation_varass_ok` in [Properties.v](pico-rocq/Properties.v) |
| Theorem 1 support | Field write preserves well-formedness under permitted writes | `SFldWrite x f y` is well-typed and evaluates successfully by `eval_stmt` | Heap update preserves `wf_r_config` | `preservation_fldwrite_ok` plus scope-specific lemmas in [Properties.v](pico-rocq/Properties.v) |
| Theorem 1 support | Object creation preserves well-formedness | `SNew x q_c c ys` is well-typed and evaluates by `eval_stmt` | Extending the heap and assigning the fresh object preserves `wf_r_config` | `preservation_new_ok` in [Properties.v](pico-rocq/Properties.v) |
| Theorem 2 | Shallow abstract immutability | Immutable object exists before and after evaluation; field is `Final` or `RDA`; statement is well-typed and evaluates successfully | Protected field value is unchanged | `shallow_immutability_pico` in [DeepImmutability.v](pico-rocq/DeepImmutability.v) |
| Lemma 1 | Reachable-abstract-state reachability from an immutable root preserves immutability | Object is reachable from an immutable root through abstract-state fields | The reachable object is also immutable | `reachable_abs_from_imm_points_to_imm` in [DeepImmutability.v](pico-rocq/DeepImmutability.v) |
| Theorem 3 | Transitive abstract immutability | Object is reachable from an immutable root; statement is well-typed and evaluates successfully | Reachable abstract-state objects remain protected | `deep_immutability_pico` in [DeepImmutability.v](pico-rocq/DeepImmutability.v) |
| Theorem 4 | Safe readonly method call | Method call through readonly receiver; arguments are protected/readable; method body evaluates successfully | Readonly-reachable arguments remain protected across the call | `readonly_method_call_preserves_arguments` in [ReadonlySafety.v](pico-rocq/ReadonlySafety.v) |
| Theorem 4 support | Readonly field-write safety | Receiver expression has static type `RO`; field-write statement evaluates successfully; method scope is not `AbstractImm` | Protected field of the readonly-referenced object is unchanged | `readonly_pico_field_write` in [ReadonlySafety.v](pico-rocq/ReadonlySafety.v) |
| Theorem 5 | Concrete immutability | Method call occurs in `ConcreteImm` scope; receiver has static `RO` type; all parameters are safe | Entire reachable argument/object graph remains unchanged for protected fields | `ConcreteImmutability` in [ConcreteImmutability.v](pico-rocq/ConcreteImmutability.v) |
| Proof integrity | No axioms/admitted proof gaps in submitted sources | Artifact sources exclude forbidden `Axiom`, `Admitted`, and `admit`, except bundled `LibTactics.v` support library | Mechanical checker passes | [scripts/check-no-axioms-admits.py](pico-rocq/scripts/check-no-axioms-admits.py) via `make check` |

## 2. Smoke Test

Inside the container, run:

```bash
opam --version
opam exec -- rocq -v
ls -d /workspace/pico-rocq
```

Expected results:

- OPAM is available.
- Rocq is available through `opam exec -- ...`.
- `/workspace/pico-rocq` exists.

## 3. Build the Formalization

Run:

```bash
cd /workspace/pico-rocq
rm -f CoqMakefile CoqMakefile.conf .CoqMakefile.d .Makefile.d
rm -f ./*.vo ./*.vos ./*.vok ./*.glob ./*.aux ./.*.aux
opam exec -- make
```

The existing `Makefile` generates and uses `CoqMakefile` from `_RocqProject`.

Expected result: Rocq checks all `.v` files successfully.

The cleanup commands force a real rebuild. Without removing the compiled `.vo` files, `make` may correctly report `Nothing to be done for 'real-all'` because the proof objects are already present.

Recommended budget for a clean Rocq build: 3-5 minutes on a 4-core Docker Desktop VM.

## 4. Proof Hygiene Check

For the stronger check, run:

```bash
cd /workspace/pico-rocq
opam exec -- make check
```

Expected result: the Rocq development builds successfully, and `scripts/check-no-axioms-admits.py` reports no axioms or admits.

Observed warm-run time: effectively instantaneous after `opam exec -- make` has completed. Recommended budget: less than 1 minute.

## 5. Optional Alectryon Inspection

The commands above are the required validation steps. Reviewers who want to browse proof states can also render Alectryon HTML pages. The Docker image includes Alectryon for this optional inspection step.

Inside the container, run:

```bash
cd /workspace/pico-rocq
opam exec -- make alectryon-doc
```

The generated index is:

```text
/workspace/pico-rocq/alectryon/index.html
```

To inspect it from the host, start the manual evaluation shell with a host-mounted output directory:

```bash
mkdir -p alectryon
docker run --rm -it \
  -v "$PWD/alectryon:/workspace/pico-rocq/alectryon" \
  --entrypoint bash \
  pico-artifact:latest
```

Inside the container, run:

```bash
cd /workspace/pico-rocq
opam exec -- make alectryon-doc
```

Because `/workspace/pico-rocq/alectryon` is mounted to `./alectryon` on the host, the generated files are already available after the command finishes. Then open `./alectryon/index.html` in a browser.

The index groups files by role:

- **Foundations**: syntax, notation, helper lemmas, and tactics.
- **Type system**: viewpoint adaptation, subtyping, and typing.
- **Runtime**: reachability, big-step semantics, and preservation support lemmas.
- **Soundness**: the preservation theorem.
- **Immutability**: shallow/deep immutability and concrete immutability.
- **Readonly**: readonly confinement, no-mutation lemmas, and readonly safety.
- **Mutation safety**: the no-successful-forbidden-mutation theorem.

The rendered pages include proof states. Use the proof-toggle button added by the artifact's Alectryon theme to expand or hide proof scripts while browsing theorem statements.

## 6. Troubleshooting

- **Rocq command not found**: run Rocq commands through `opam exec -- ...`.
- **OPAM switch appears unavailable**: rebuild the Docker image and inspect the `scripts/install-rocq.sh` step in the Docker log.
- **Build fails after a partial run**: from `/workspace/pico-rocq`, run `opam exec -- make clean`, then rerun `opam exec -- make`.
- **Alectryon command not found**: rebuild the Docker image. The Dockerfile installs Alectryon during image construction.
