# PICO Constrictor Benchmark Tests

This directory contains the PICO translation of the Constrictor benchmark suite. The original benchmark artifacts are available from Zenodo: <https://zenodo.org/records/11003108>.

The tests are run by `PICOConstrictorTest`, which invokes the PICO checker over the files in this directory with:

```text
-AassumeInitialized
```

Run the test suite from the Checker Framework root:

```bash
./gradlew PICOConstrictorTest
```

From the artifact repository root, the equivalent command is:

```bash
cd checker-framework
./gradlew PICOConstrictorTest
```

## Benchmark Coverage

The translated suite covers both inheritance-based and non-inheritance Constrictor examples.

### Inheritance Benchmarks

- Lists: PICO reports the errors expected from Constrictor.
- Points: PICO reports the errors expected from Constrictor.
- Sets: PICO reports the errors expected from Constrictor, and also reports the issue in `WrongImplMoveFrontListSet.java` that Constrictor missed.
- Shapes: PICO reports most expected errors, but differs on memoized-shape examples because PICO does not directly model Constrictor's observability condition.

Notes:

- `MoveToFrontListSet.java` is reported by PICO. The Constrictor paper characterizes this result as spurious.
- `EvilMemoizedRectangle.java` and `LeakyMemoizedRectangle.java` do not behave exactly as in Constrictor because PICO tracks mutability properties rather than the same abstract-state observability relation.

### Non-Inheritance Benchmarks

- `EvilBinarySearchTree.java`: PICO reports an error; Constrictor times out.
- `EvilUnionFind.java`: PICO reports an error. The reported error may not correspond exactly to the one identified by Constrictor.
- `LongLoopMutator.java`: PICO reports an error; Constrictor times out.
- `UnreachablyMutating.java`: both PICO and Constrictor report an error. This case may be improved by stronger dataflow reasoning in PICO.
- `CachedList.java`: the benchmark requires care in deciding whether cached fields belong to the abstract state. In this translation, the caching fields are annotated with `@Assignable`.
- `DefaultDict.java`: the abstract-state boundary is subtle because Constrictor view methods are not expected to mutate abstract state.
- `StringShuffler.java`, `UnionFind.java`, and `VariableTypesMatter.java`: these examples expose precision differences between PICO and Constrictor, especially around observability and whether an assignment is externally visible.

## Annotation Translation

The benchmark was translated from Constrictor annotations to PICO annotations using the following conventions:

| Constrictor concept | PICO encoding |
| --- | --- |
| `@Immutable` class | `@Immutable` on the class and its subclasses |
| `@Immutable` method | `@Readonly` receiver parameter |
| `@Viewmethod` method | `@Readonly` receiver parameter |
| Field excluded from a view method's abstract state | `@Assignable` or `@Mutable` field annotation |

These mappings are approximate. The two systems enforce related but not identical properties, so some benchmark outcomes intentionally document differences in precision or expressiveness rather than one-to-one agreement.
