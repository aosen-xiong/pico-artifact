# Rocq Artifact Evaluation Guide

This document gives reviewer-facing instructions for reproducing the Rocq formalization track for:

**Transitive, Abstract, and Class Polymorphic Immutability**

The Rocq artifact is in:

```text
pico-rocq/
```

The submitted artifact archive includes the Rocq source files directly under
this directory. Reviewers should not need to clone another repository or
initialize a submodule.

It contains the mechanized formal model and proofs. The main validation task is to build the Rocq development and run the proof-hygiene scan. Reviewers can use the claim map below to connect paper-level claims to the corresponding Rocq theorem statements.

Build and start the Docker container as described in [Artifact-Evaluation.md](Artifact-Evaluation.md). Then run the commands below inside the container. The Rocq development is at:

```text
/workspace/pico-rocq
```

## 1. Claim Map

| Paper reference | Paper-level claim / premise | Mechanized premise in Rocq | Proved guarantee | Rocq theorem / file |
|---|---|---|---|---|
| Syntax figures | Pico syntax: qualifiers, expressions, statements, fields, classes, methods, runtime values, heaps | Inductive datatypes and records encode the paper grammar | Source language and runtime configurations used by all later judgments | `q`, `q_f`, `q_c`, `a`, `expr`, `stmt`, `field_type`, `method_sig`, `class_def`, `runtime_type`, `r_env`, `Obj` in [Syntax.v](pico-rocq/Syntax.v) |
| Viewpoint adaptation rules | Mutability, assignability, field, constructor, and runtime viewpoint adaptation | Scope-specific functions encode AS, CS, RS, and TS as independent mutability/assignability choices | Adapted qualifiers used by typing, field access/write, constructors, and runtime typability | `vpa_mutability_qq_abstract_state`, `vpa_mutability_tt_abstract_state`, `vpa_mutability_qq_readonly_state`, `vpa_mutability_tt_readonly_state`, `vpa_assignability`, `vpa_assignability_cs_ts` in [ViewpointAdaptation.v](pico-rocq/ViewpointAdaptation.v) |
| Subtyping rules | Qualifier, class/base, method-scope, and qualified-type subtyping | Inductive relations encode the subtype premises consumed by typing | Subtyping derivations used by statement typing and well-formedness | `q_subtype`, `base_subtype`, `method_scope_subtype`, `qualified_type_subtype` in [Subtyping.v](pico-rocq/Subtyping.v) |
| Static typing | Statement typing and well-formed field, constructor, class, method, and table conditions | Static environments, method scopes, receiver/argument adaptation, and class-table checks are explicit premises | Well-typed statements and well-formed declarations used by preservation and immutability proofs | `stmt_typing`, `wf_stypeuse`, `wf_field`, `wf_constructor`, `wf_method`, `wf_class`, `wf_class_table` in [Typing.v](pico-rocq/Typing.v) |
| Dynamic semantics | Big-step expression and statement evaluation with success, null-pointer, and mutation-exception outcomes | Evaluation relates expressions and statements in an initial runtime configuration to an outcome and final configuration | Operational behavior used by preservation, mutation safety, and the immutability proofs | `eval_expr`, `eval_stmt` and their determinism theorems in [Bigstep.v](pico-rocq/Bigstep.v) |
| Runtime well-formedness | Runtime configuration consistency between static environments, runtime environments, heaps, and class tables | Runtime typability and heap/object well-formedness are bundled in `wf_r_config` | Starting assumption and final guarantee for preservation | `wf_rtypeuse`, `wf_obj`, `wf_heap`, `wf_renv`, `wf_r_config` in [Bigstep.v](pico-rocq/Bigstep.v) |
| Reachability definitions | Ordinary reachability and abstract-state reachability | `reachable` follows arbitrary heap edges; `reachable_abs` and `protected_locset` encode RAS protection; `reachable_locations_from_initial_env` collects the objects reachable from call roots | Reachability sets used by shallow abstract immutability and the four state-preservation guarantees | `reachable`, `reachable_abs`, `protected_locset` in [Reachability.v](pico-rocq/Reachability.v); `reachable_locations_from_initial_env` in [Bigstep.v](pico-rocq/Bigstep.v) |
| Theorem 1 | Preservation and mutation safety | The initial runtime configuration is well-formed and the statement is well-typed; preservation additionally assumes a successful `OK` evaluation, while safety considers an evaluation producing `MUTATIONEXP` | Successful evaluation preserves runtime well-formedness, and no well-typed statement can produce the mutation exception | `preservation_pico` in [Preservation.v](pico-rocq/Preservation.v) and `well_typed_no_mutation_exp` in [WFNOMutationEXP.v](pico-rocq/WFNOMutationEXP.v) |
| Theorem 1 support | Big-step evaluation determinism | The same expression or statement evaluates twice from the same initial configuration | The two evaluations produce the same result/configuration | `eval_expr_deterministic` and `eval_stmt_deterministic` in [Bigstep.v](pico-rocq/Bigstep.v) |
| Theorem 1 support | Local variable declaration preserves well-formedness | `SLocal T x` is well-typed and evaluates by `eval_stmt` | Extending runtime/static environments with the local binding preserves `wf_r_config` | `preservation_local_ok` in [Properties.v](pico-rocq/Properties.v) |
| Theorem 1 support | Variable assignment preserves well-formedness | `SVarAss x e` is well-typed and evaluates by `eval_stmt` | Updating `x` with the evaluated value preserves `wf_r_config` | `preservation_varass_ok` in [Properties.v](pico-rocq/Properties.v) |
| Theorem 1 support | Field write preserves well-formedness under permitted writes | `SFldWrite x f y` is well-typed and evaluates successfully by `eval_stmt` | Heap update preserves `wf_r_config` | `preservation_fldwrite_ok` plus scope-specific lemmas in [Properties.v](pico-rocq/Properties.v) |
| Theorem 1 support | Object creation preserves well-formedness | `SNew x q_c c ys` is well-typed and evaluates by `eval_stmt` | Extending the heap and assigning the fresh object preserves `wf_r_config` | `preservation_new_ok` in [Properties.v](pico-rocq/Properties.v) |
| Theorem 2 | Shallow abstract immutability | Immutable object exists at entry; field is `Final` or `RDA`; statement is well-typed and evaluates successfully | The object still exists with the same runtime type, and the protected field value is unchanged | `shallow_abstract_immutability` in [AbstractStatePreservation.v](pico-rocq/AbstractStatePreservation.v) |
| Lemma 1 | Reachable-abstract-state reachability from an immutable root preserves immutability | Object is reachable from an immutable root through abstract-state fields | The reachable object is also immutable | `reachable_abs_from_imm_points_to_imm` in [AbstractStatePreservation.v](pico-rocq/AbstractStatePreservation.v) |
| Theorem 3, AS clause | Abstract-state preservation | Object is reachable from an immutable root through abstract state; statement is well-typed and evaluates successfully | The reachable object still exists with the same runtime type, and every non-`Assignable` field retains its entry value | `abstract_state_preservation` in [AbstractStatePreservation.v](pico-rocq/AbstractStatePreservation.v) |
| Theorem 3, CS clause | Concrete-state preservation | Object is reachable through abstract state from an immutable root; statement is well-typed in `ConcreteState` scope | The reachable object still exists with the same runtime type, and every field retains its entry value, including fields declared `Assignable` | `concrete_state_preservation` in [ConcreteStatePreservation.v](pico-rocq/ConcreteStatePreservation.v), supported by [ConcreteState.v](pico-rocq/ConcreteState.v) |
| Theorem 4, RS clause | Readonly-state preservation | Method call occurs in `ReadonlyState` scope through protected receiver/arguments and evaluates successfully | Each protected object still exists with the same runtime type, and its non-`Assignable` fields retain their entry values | `readonly_state_preservation` in [ReadonlyStatePreservation.v](pico-rocq/ReadonlyStatePreservation.v) |
| Theorem 4 support | Readonly field-write safety | Receiver expression has static type `RO`; field-write statement evaluates successfully in `ReadonlyState` or `TransitiveState` scope | Protected field of the readonly-referenced object is unchanged | `readonly_field_write_preservation` in [ReadonlyStatePreservation.v](pico-rocq/ReadonlyStatePreservation.v) |
| Theorem 4, TS clause | Transitive-state preservation | Method call occurs in `TransitiveState` scope; receiver and all parameters are safe | Each protected object still exists with the same runtime type, and every field retains its entry value | `transitive_state_preservation` in [TransitiveStatePreservation.v](pico-rocq/TransitiveStatePreservation.v) |
| Proof-hygiene scan | Submitted proof sources do not use the forbidden commands scanned by the artifact | Every submitted `.v` file excludes literal `Axiom`, `Admitted`, and `admit` | Mechanical forbidden-command scan passes | [scripts/check-no-axioms-admits.py](pico-rocq/scripts/check-no-axioms-admits.py) via `make check` |
| Kernel-assumption audit | Public results do not depend on global axioms | The explicit [public-theorems.txt](pico-rocq/scripts/public-theorems.txt) manifest is checked against every source `Theorem`, then each fully qualified theorem, lemma, or corollary entry is inspected with `Print Assumptions` | The manifest and sources agree, and every listed public result is closed under the global context | [scripts/check-public-assumptions.py](pico-rocq/scripts/check-public-assumptions.py) via `make check` |

## 2. Proof Organization

The Rocq development is intentionally flat: each `.v` file is listed in `_RocqProject`, and the generated `CoqMakefile` checks them in dependency order.

| File | Role |
|---|---|
| `Syntax.v`, `Notations.v`, `Helpers.v`, `Tactics.v`, `LibTactics.v` | Core syntax, notation, small helper lemmas, and proof automation support. |
| `ViewpointAdaptation.v`, `Subtyping.v`, `Typing.v` | Static semantics: viewpoint adaptation, subtype relation, statement/expression typing, method signatures, and parameter-safety predicates. |
| `Reachability.v`, `Bigstep.v` | Runtime reachability and big-step evaluation semantics. |
| `Properties.v`, `Preservation.v`, `WFNOMutationEXP.v` | Preservation support lemmas, top-level preservation theorem, and mutation-exception safety. |
| `AbstractStatePreservation.v` | Shallow abstract immutability and abstract-state-preservation results. |
| `ConcreteState.v`, `ConcreteStatePreservation.v` | CS assignability support lemmas and the concrete-state-preservation theorem. |
| `ExecutionConfinement.v`, `MutableCapability.v`, `AuthorityCapability.v`, `ProtectionHistory.v` | Fixed protected-set confinement, RDM reachability, authority-sensitive capabilities, and typed provenance. |
| `ComponentColoring.v`, `ForwardCapabilityHistory.v`, `AuthorityHistory.v` | Component separation and preservation of capability history across primitive statements and callee entry. |
| `WatchedFrames.v`, `LiveCapabilityStack.v`, `PotentialCapability.v` | Suspended caller tracking, call push/pop, latent return edges, and the structural statement-history theorem. |
| `ProtectedFieldPreservation.v` | Reusable structural field-preservation theorem shared by RS and TS. |
| `ReadonlyHelper.v`, `ReadonlyNoMutation.v`, `ReadonlyStatePreservation.v` | Readonly reachability, no-mutation support, and the readonly-state-preservation theorem. |
| `TransitiveStatePreservation.v` | Transitive-state-preservation theorem for safe method calls. |
| `ObjectCreationExamples.v` | Small mechanized examples for object creation cases. |

The optional Alectryon output described below gives a browsable view of these files and their proof states.

## 3. Frameworks and Libraries

The proof is a direct Rocq/Coq mechanization of the Pico formal model. It does not use a semantic framework such as Iris, Metalib, Autosubst, or a locally-nameless library. Finite maps/environments, heaps, reachability, typing, and evaluation relations are defined directly in the submitted sources.

The artifact depends on:

- Rocq/Coq, as installed by the Docker image and reported by `opam exec -- rocq -v`.
- OCaml and OPAM for the isolated switch.
- `LibTactics.v`, a bundled proof-engineering support file used for tactics. It is scanned together with every other submitted `.v` file by the proof-hygiene check.

## 4. Paper/Formalization Notes

- The paper presents judgments and heaps mathematically; the Rocq development encodes them as inductive relations and finite association lists.
- Variable index `0` is reserved for `this`. Following Java, `this` is not a reassignable variable, so variable assignment, object creation, and method-call typing require their destination variable to differ from `0`.
- The constructor model omits executable constructor bodies and explicit superclass-constructor calls. Consequently, the paper's `checkSuperCall` premise has no separate Rocq judgment; this is part of the constructor-body simplification declared in the paper.
- The development proves declaration-, statement-, and configuration-level results rather than a separate `WF-Prog`/`OS-P-Prog` wrapper judgment.
- `wf_field` and `wf_constructor` implement the paper's viewpoint-adapted well-formedness checks: field type uses permit an adapted subtype of the declaration, and constructor checking adapts both the parameter and field sides before comparing them. `wf_method` explicitly checks its declared return type with `wf_stypeuse`. [WellformednessRegression.v](pico-rocq/WellformednessRegression.v) exercises both field/constructor cases and supplies a positive runtime-configuration witness.
- The method-call preservation theorems use the explicit
  `signature_has_no_mutable_roots` premise for the declared receiver and formal
  parameters, so their statements expose the exact condition consumed by the
  proofs.
- The readonly-state and transitive-state preservation statements are proved over the mechanized big-step semantics and the static typing relation. Some support lemmas are split out into field-write, reachability, and preservation components rather than appearing as single paper-level proof steps.
- The paper's full method-overriding rule uses viewpoint-adapted variance. The Rocq development intentionally mechanizes invariant overriding: if a subclass method overrides a parent method, the signatures must be syntactically equal. This is the scope caveat noted in the paper's proof-mechanization section.
- The paper treats `Lost` as a helper qualifier rather than a programmer-written type qualifier. Rocq represents it in the common qualifier datatype, but `wf_stypeuse` and non-reflexive `Lost` subtyping prevent direct `Lost` type uses in well-formed static environments.
- The artifact has no intended unfinished proof obligations. `make check` builds every file, scans every submitted `.v` file for literal `Axiom`, `Admitted`, and `admit`, verifies that the public-theorem manifest matches every source `Theorem`, and uses `Print Assumptions` to check that every manifest entry is closed under the global context.

## 5. Smoke Test

Inside the container, run:

```bash
opam --version
opam exec -- rocq -v
test -f /workspace/pico-rocq/Makefile
test -f /workspace/pico-rocq/_RocqProject
```

Expected results:

- OPAM is available.
- Rocq is available through `opam exec -- ...`; the packaged environment reports
  Rocq 9.1.1 compiled with OCaml 5.2.1.
- `/workspace/pico-rocq` contains the Rocq source tree.

## 6. Build the Formalization

Run:

```bash
cd /workspace/pico-rocq
rm -f CoqMakefile CoqMakefile.conf .CoqMakefile.d .Makefile.d
rm -f ./*.vo ./*.vos ./*.vok ./*.glob ./*.aux ./.*.aux
find . -maxdepth 1 \( -name '*.v' -o -name '_RocqProject' -o -name 'Makefile' \) \
  -exec touch -c {} +
opam exec -- make
```

The existing `Makefile` generates and uses `CoqMakefile` from `_RocqProject`.

Expected result: Rocq checks all `.v` files successfully.

The cleanup commands force a real rebuild. Without removing the compiled `.vo` files, `make` may correctly report `Nothing to be done for 'real-all'` because the proof objects are already present.

Recommended budget for a clean Rocq build: 3-5 minutes on a 4-core Docker Desktop VM.

## 7. Proof Hygiene Check

For the stronger check, run:

```bash
cd /workspace/pico-rocq
opam exec -- make check
```

Expected result: the Rocq development builds successfully,
`scripts/check-no-axioms-admits.py` reports no forbidden `Axiom`, `Admitted`,
or `admit` commands, and `scripts/check-public-assumptions.py` reports that the
manifest matches every source `Theorem` and all listed public results are
closed under the global context.

Observed warm-run time: effectively instantaneous after `opam exec -- make` has completed. Recommended budget: less than 1 minute.

## 8. Optional Alectryon Inspection

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
  --network none \
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
- **State preservation**: shallow abstract immutability plus abstract-, concrete-, readonly-, and transitive-state preservation.
- **Capability history**: confinement, RDM connectivity, authority, suspended
  frames, potential connectivity, and protected-field preservation.
- **Readonly**: readonly reachability, no-mutation support, and readonly-state preservation.
- **Mutation safety**: the no-successful-forbidden-mutation theorem.

The rendered pages include proof states. Use the proof-toggle button added by the artifact's Alectryon theme to expand or hide proof scripts while browsing theorem statements.

## 9. Troubleshooting

- **`/workspace/pico-rocq` is empty or lacks `Makefile`**: the artifact archive was packaged without the Rocq sources. Recreate the archive from an author checkout where `pico-rocq/Makefile` and `pico-rocq/_RocqProject` are present.
- **Rocq command not found**: run Rocq commands through `opam exec -- ...`.
- **OPAM switch appears unavailable**: rebuild the Docker image and inspect the `scripts/install-rocq.sh` step in the Docker log.
- **Build fails after a partial run**: from `/workspace/pico-rocq`, run `opam exec -- make clean`, then rerun `opam exec -- make`.
- **`make` repeatedly regenerates `CoqMakefile` and warns that files are in the future**: the host/archive timestamps are ahead of the container clock. Run the cleanup and `find ... touch -c` commands in Section 6 before rerunning `opam exec -- make`.
- **Alectryon command not found**: rebuild the Docker image. The Dockerfile installs Alectryon during image construction.
