# PICO Checker Framework Artifact Evaluation Guide

This document gives reviewer-facing instructions for reproducing the PICO implementation and benchmark track in a modified Checker Framework for:

**Transitive, Abstract, and Class Polymorphic Immutability**

This track uses:

- `checker-framework/`: the PICO checker implementation and benchmark tests.
- `jdk/`: the annotated OpenJDK sources for the Java Collections Framework case study.
- `scripts/count_java_annotations.pl`: the annotation-counting helper used to audit benchmark counts.

Build and start the Docker container as described in [Artifact-Evaluation.md](Artifact-Evaluation.md). Then run the commands below inside the container. The relevant directories are:

```text
/workspace/checker-framework
/workspace/jdk
/workspace/scripts
```

## Source Locations

The PICO implementation is part of the bundled Checker Framework fork:

- Main checker implementation: `checker-framework/checker/src/main/java/org/checkerframework/checker/pico/`
- Qualifier annotations: `checker-framework/checker-qual/src/main/java/org/checkerframework/checker/pico/qual/`
- Focused PICO regression and benchmark tests: `checker-framework/checker/tests/pico-constrictor/` and `checker-framework/checker/tests/pico-mutable-default/`
- Annotated JDK case study: `jdk/src/java.base/share/classes/java/util/`, with the evaluated file list in `TypecheckedList.txt`

The main implementation files are organized as follows:

- `PICOChecker` and `PICONoInitSubchecker`: checker entry points and Checker Framework integration.
- `PICONoInitAnnotatedTypeFactory` and `PICOInitializationAnnotatedTypeFactory`: qualifier defaults, tree/type annotation, initialization-aware field handling, and type-factory wiring.
- `PICONoInitVisitor`, `PICOInitializationVisitor`, and `PICOValidator`: visitor checks, initialization visitor integration, and validation of legal qualifier/assignability use.
- `PICOQualifierHierarchy`, `PICOViewpointAdapter`, and `PICOTypeUtil`: qualifier ordering, viewpoint adaptation, and shared PICO-specific type utilities.
- `PICONoInitAnalysis`, `PICONoInitStore`, `PICONoInitTransfer`, and `PICONoInitValue`: flow-analysis support classes.
- `ObjectIdentityMethodEnforcer`: checks that object identity methods use only abstract-state information.
- `messages.properties`: diagnostic message text for PICO checker errors.

### Scope of the implementation track

The Java checker implements PICO's mutability and assignability qualifiers,
class mutability polymorphism, initialization integration, and the AS-style
viewpoint adaptation used by the case studies. The AS, CS, RS, and TS method
scopes are distinguished in the core formal model and mechanized in the Rocq
track; the Java implementation does not expose those four scopes as method
annotations. Consequently, this track validates the implemented qualifier
system and case studies, while the Rocq track validates the four-mode
metatheory.

## 1. Smoke Test

Inside the container, run:

```bash
java -version
ls -d /workspace/checker-framework /workspace/jdk
count_java_annotations.pl --help
```

Expected results:

- Java 17 is available.
- The Checker Framework and JDK directories exist.
- `count_java_annotations.pl` is on `PATH`.

## 2. Checker Framework and JDK Case Study

Build the Checker Framework javac wrapper:

```bash
cd /workspace/checker-framework
bash ./gradlew --offline assembleforjavac
```

Observed warm-run time: about 1 minute 15 seconds. Recommended budget: 2-3 minutes, depending on Gradle cache state.

Run the PICO checker over the JDK `java.util` case-study files:

```bash
cd /workspace/checker-framework
./checker/bin/javac -processor pico \
  --patch-module java.base=/workspace/jdk/src/java.base \
  --add-reads java.base=ALL-UNNAMED \
  -Xmaxerrs 5000 \
  -Xlint:none \
  -Alint=-all \
  -XDignore.symbol.file=true \
  -AassumeInitialized \
  $(sed 's#^#/workspace/jdk/src/java.base/share/classes/java/util/#' \
      /workspace/jdk/src/java.base/share/classes/java/util/TypecheckedList.txt) \
  > /workspace/checker-framework/compile.log 2>&1
```

Observed time: about 25 seconds. Recommended budget: 1 minute.

The command writes the checker output to:

```text
/workspace/checker-framework/compile.log
```

Expected result: the command exits with status `0` and reports no PICO type
errors. The current run emits only javac's two informational lines about
unchecked operations in `Collections.java`; `compile.log` must contain no
`error:` diagnostics.

The file list for this case study is:

```text
/workspace/jdk/src/java.base/share/classes/java/util/TypecheckedList.txt
```

Command-line options:

- `./checker/bin/javac`: the Checker Framework wrapper around `javac`.
- `-processor pico`: runs the PICO annotation processor.
- `--patch-module java.base=/workspace/jdk/src/java.base`: compiles against the artifact's annotated `java.base` sources instead of the unannotated platform copy.
- `--add-reads java.base=ALL-UNNAMED`: permits the patched `java.base` module to read classes on the unnamed class path, including Checker Framework support classes needed during checking.
- `-Xmaxerrs 5000`: raises javac's error limit so the log records the full diagnostic set for the case study.
- `-Xlint:none`: disables ordinary javac lint warnings that are not part of the PICO evaluation.
- `-Alint=-all`: disables Checker Framework lint warnings that are not part of the PICO evaluation.
- `-XDignore.symbol.file=true`: tells javac not to use the JDK symbol file, which is necessary when checking patched JDK sources.
- `-AassumeInitialized`: uses the Checker Framework initialization assumption expected by this case study.
- `$(sed ...)`: expands `TypecheckedList.txt` into absolute paths for the 52 evaluated `java.util` files.
- `> ... 2>&1`: writes both standard output and diagnostics to `compile.log`.

## 3. Regression Tests

Run the two focused PICO test suites:

```bash
cd /workspace/checker-framework
bash ./gradlew --offline PICOConstrictorTest
bash ./gradlew --offline PICOMutableDefaultTest
```

Expected result: both Gradle tasks finish successfully.

Observed warm-run time: about 40 seconds total. Recommended budget: 1-2 minutes after `assembleforjavac` has built the project.

## 4. Annotation and Suppression Counts

The artifact includes a helper script for counting PICO annotations and `@SuppressWarnings` entries.

The common `count_java_annotations.pl` option set used below is:

```bash
-a @Assignable -a @Immutable -a @Readonly \
-a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
-s pico
```

The `-s pico` option counts `@SuppressWarnings` values whose warning key starts with `pico`, including both `pico` and keys such as `pico:argument.type.incompatible`.

The table counts explicit `@Assignable` annotations. Receiver-dependent assignability (RDA) is implicit in the checker for non-final instance fields without an explicit `@Assignable`; it is not a separate source annotation and therefore is not counted by `count_java_annotations.pl`.

### 4.1 JDK Case Study

`TypecheckedList.txt` contains filenames relative to the JDK `java.util` directory, so run the counter from that directory:

```bash
cd /workspace/jdk/src/java.base/share/classes/java/util
count_java_annotations.pl -l \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico \
  -f TypecheckedList.txt
```

This prints a LaTeX table with one row per file and columns for:

```text
LOC
@Assignable
@Immutable
@Readonly
@ReceiverDependentMutable
@Mutable
@PolyMutable
@SuppressWarnings:pico
```

For CSV output, replace `-l` with `-t`.

For a human-readable per-file breakdown, omit both `-l` and `-t`.

The automated evaluation also writes the generated tables to:

```text
/workspace/results/counts/java-util-annotation-counts.csv
/workspace/results/counts/java-util-annotation-counts.txt
/workspace/results/counts/java-util-annotation-counts.tex
```

The current generated total row for the JDK case study is:

| Files | LOC | `@Assignable` | `@Immutable` | `@Readonly` | `@ReceiverDependentMutable` | `@Mutable` | `@PolyMutable` | `@SuppressWarnings:pico` |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 52 | 22,992 | 66 | 349 | 1,919 | 241 | 736 | 650 | 94 |

The artifact was updated and cleaned up after the paper submission to include the final JDK case-study annotations. The generated artifact counts above are the current reproducible counts for this artifact version and are the numbers to use for the final paper version.

The JDK source tree contains PICO annotations outside these 52 files. The authors intentionally annotated additional JDK files while exploring a broader retrofit, so a repository-wide search for PICO annotations will find more occurrences than this table reports. The case-study count is limited to the files in `TypecheckedList.txt`, which are the files used for the reproducible JCF evaluation.

Observed time: about 1 second. Recommended budget: less than 1 minute.

### 4.2 Constrictor Benchmark

Run from `/workspace`:

```bash
cd /workspace
count_java_annotations.pl -l \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico \
  checker-framework/checker/tests/pico-constrictor
```

Expected total:

| Files | LOC | `@Assignable` | `@Immutable` | `@Readonly` | `@ReceiverDependentMutable` | `@Mutable` | `@PolyMutable` | `@SuppressWarnings:pico` |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 51 | 1,184 | 12 | 16 | 85 | 0 | 1 | 0 | 4 |

The automated evaluation writes this table to
`/workspace/results/counts/constrictor-annotation-counts.csv` and verifies its
total row.

### 4.3 PICO Mutable-Default Benchmark

`PaperFigureExamples.java` is an illustrative paper-example test rather than a
member of the evaluated mutable-default benchmark. Run from `/workspace` while
excluding it:

```bash
cd /workspace
count_java_annotations.pl -l \
  -a @Assignable -a @Immutable -a @Readonly \
  -a @ReceiverDependentMutable -a @Mutable -a @PolyMutable \
  -s pico \
  $(find checker-framework/checker/tests/pico-mutable-default -name '*.java' \
      ! -name '._*.java' \
      ! -name 'PaperFigureExamples.java' | sort)
```

Expected total:

| Files | LOC | `@Assignable` | `@Immutable` | `@Readonly` | `@ReceiverDependentMutable` | `@Mutable` | `@PolyMutable` | `@SuppressWarnings:pico` |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 36 | 1,738 | 29 | 224 | 84 | 137 | 150 | 41 | 0 |

The automated evaluation writes this table to
`/workspace/results/counts/mutable-default-annotation-counts.csv` and verifies
its total row.

## 5. Troubleshooting

- **Gradle fails because of memory pressure**: rerun Docker with more memory
  assigned in Docker Desktop.
- **Diagnostics mention a `._*.java` file**: this is macOS AppleDouble metadata,
  not Java source. Use a fresh artifact copy, or remove the metadata with
  `find /workspace -type f -name '._*' -delete` before rerunning the test.
- **The checker command cannot find Java files**: ensure it is run inside the
  container and that
  `/workspace/jdk/src/java.base/share/classes/java/util/TypecheckedList.txt`
  exists.
- **Annotation counting reports missing files**: run the JDK count command from
  `/workspace/jdk/src/java.base/share/classes/java/util`, because
  `TypecheckedList.txt` contains filenames relative to that directory.
