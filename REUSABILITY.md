# Reusing and extending the PICO artifact

The reusable core consists of the PICO Checker Framework implementation, its
qualifier annotations and tests, the annotation-counting utility, and the Rocq
formalization. The annotated JDK and bundled benchmarks are primarily
evaluation inputs but can also serve as examples.

## Check a new Java program

Build the Checker Framework wrapper, then invoke PICO on one or more source
files:

```bash
cd checker-framework
bash ./gradlew assembleforjavac
./checker/bin/javac -processor pico /path/to/Example.java
```

PICO annotations are under
`checker-qual/src/main/java/org/checkerframework/checker/pico/qual/`. The
focused examples and expected diagnostics in `PICO-Error-Message-Tutorial.md`
are a small starting point for learning the qualifiers.

## Add a checker test

Add a Java file to an enabled PICO test directory:

- `checker-framework/checker/tests/pico-mutable-default/` for focused PICO
  language tests, or
- `checker-framework/checker/tests/pico-constrictor/` for Constrictor-style
  cases.

Use Checker Framework diagnostic comments such as
`// :: error: (assignment.type.incompatible)` for expected failures. Run the
corresponding Gradle task:

```bash
cd checker-framework
bash ./gradlew PICOMutableDefaultTest
bash ./gradlew PICOConstrictorTest
```

## Count annotations in new inputs

The counter accepts files, directories, or a file manifest. For example:

```bash
scripts/count_java_annotations.pl -t \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico path/to/sources
```

When adding a paper benchmark, define its evaluated file set explicitly and
add an expected total to `scripts/evaluate.sh`; this makes accidental benchmark
drift fail the automated evaluation.

## Compose PICO with other type systems

PICO is implemented as a Checker Framework checker, so it is a suitable basis
for product checkers and coordinated subcheckers. Useful extensions include:

- **Nullness.** Combine PICO with the Checker Framework Nullness Checker so a
  reference carries both a mutability qualifier and a nullness qualifier. This
  would discharge the null-dereference cases deliberately excluded from the
  PICO core calculus. A prototype should test qualifier defaulting, constructor
  initialization, flow refinement, and whether PICO viewpoint adaptation
  preserves the independently inferred nullness qualifier.
- **Universe or ownership types.** Add an ownership dimension to control which
  aliases may cross an object's representation boundary. This can strengthen
  PICO's abstract-state guarantee with encapsulation: PICO determines which
  state is protected, while the ownership checker prevents representation
  references from escaping through untrusted aliases.
- **Uniqueness.** Add unique, isolated, or capsule references to support safe
  ownership transfer and the freeze pattern. Once a unique mutable reference is
  consumed, the referenced graph can soundly transition to an immutable view
  because no competing mutable alias remains.

The repository does not bundle Universe/ownership or uniqueness checkers, and
these combinations are extension points rather than currently validated
features. A combined implementation should keep the qualifier hierarchies
orthogonal where possible, specify cross-hierarchy rules explicitly, and add
tests for casts, generics, arrays, field adaptation, overriding, initialization,
and flow-sensitive refinement. In the Checker Framework, this can be
implemented as a compound checker when one checker must consume facts
established by another.

## Extend the Rocq model

`pico-rocq/_RocqProject` lists every proof source in dependency order. The main
layers are:

1. syntax and viewpoint adaptation (`Syntax.v`, `ViewpointAdaptation.v`),
2. static semantics (`Subtyping.v`, `Typing.v`),
3. runtime semantics and reachability (`Bigstep.v`, `Reachability.v`), and
4. soundness and immutability theorems (`Preservation.v`,
   `AbstractStatePreservation.v`, `ConcreteStatePreservation.v`,
   `ReadonlyStatePreservation.v`, and `TransitiveStatePreservation.v`).

Add a new `.v` file to `_RocqProject` after its dependencies, then run:

```bash
cd pico-rocq
opam exec -- make check
opam exec -- make alectryon-doc
```

The second command renders browsable theorem statements and proof states under
`pico-rocq/alectryon/`.

## Extend the proof to concurrency and weak memory

The submitted Rocq semantics is sequential. Its syntax, qualifier relations,
viewpoint-adaptation functions, and much of the static typing layer can be
reused as the sequential core of a concurrent model. A weak-memory extension
could use PICO to study when abstract immutability remains observationally
stable in the presence of threads, caches, and reordered memory operations.

A concrete extension path is:

1. Extend `Syntax.v` with thread creation, synchronization, and atomic or
   volatile operations.
2. Replace or layer `Bigstep.v` with a concurrent event semantics containing
   thread-local configurations and relations such as program order,
   reads-from, coherence, synchronization, and happens-before.
3. Lift heap reachability and abstract-state reachability from a single heap to
   the memory visible to a thread, or define them over a global execution graph.
4. State the consistency model explicitly—for example, sequential consistency
   first, followed by a weak-memory model—and identify which PICO guarantees
   require data-race freedom, safe publication, synchronization, or atomic
   access.
5. Reprove preservation and the AS/CS/RS/TS guarantees over concurrent
   executions. The key new obligation is to show that writes by another thread
   cannot invalidate the protected-state conclusion observed by the current
   thread.

This direction can distinguish several research questions: whether abstract
immutability implies race freedom for abstract-state fields; whether mutations
of assignable cache fields remain observationally hidden; what publication
conditions make an immutable reference safe to share; and which guarantees
survive relaxed reads and writes. The current theorems do not claim these
concurrent properties, but their qualifier, adaptation, reachability, and
protected-field definitions provide reusable starting points.

## Known reuse boundaries

- The Java checker implements PICO's qualifier system and AS-style viewpoint
  adaptation, but not the AS/CS/RS/TS method-scope annotations mechanized in
  Rocq.
- The Rocq development models the paper's core calculus rather than all Java
  features supported through the Checker Framework, and its operational
  semantics is sequential rather than concurrent or weak-memory aware.
- Method overriding is invariant in the Rocq model, while the paper and Java
  implementation use the richer viewpoint-adapted rule.
- The JDK command is specialized to the supplied JDK 17 source tree and its
  module layout.

See `Artifact-Evaluation-Checker.md` and `Artifact-Evaluation-Rocq.md` for the
validated environments and detailed source maps.
