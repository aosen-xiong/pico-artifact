# PICO Type-Check Error Message Tutorial

This short tutorial explains the PICO checker diagnostics that appear in the test suite and in the JDK case-study log.

Checker Framework tests mark expected diagnostics with comments such as:

```java
// :: error: (illegal.field.write)
```

The stable part of the diagnostic is the key inside parentheses. The full compiler output also includes the source location and a longer message. For PICO-specific messages, the longer text is defined in:

```text
checker-framework/checker/src/main/java/org/checkerframework/checker/pico/messages.properties
```

To browse more examples, run:

```bash
rg -n "// :: (error|warning):" \
  checker-framework/checker/tests/pico-mutable-default \
  checker-framework/checker/tests/pico-constrictor
```

## Hands-On Tutorial Files

The directory `tutorial/pico-errors/` contains small Java files intended for
manual exploration. Each file isolates one diagnostic family, so reviewers can
run the checker and read the exact compiler output without first navigating the
larger regression-test suite.

The expected transcript for these focused files is recorded in
`tutorial/pico-errors/expected-output.txt`.

| File | Main diagnostics |
|---|---|
| `FieldWriteError.java` | `illegal.field.write` |
| `ArrayWriteError.java` | `illegal.array.write`, `array.new.invalid` |
| `AssignmentArgumentError.java` | `assignment.type.incompatible`, `argument.type.incompatible` |
| `InvocationError.java` | `method.invocation.invalid`, `constructor.invocation.invalid` |
| `AssignabilityError.java` | `assignability.declaration.invalid` |
| `StaticRDMError.java` | `static.receiverdependentmutable.forbidden` |
| `InvalidAnnotationError.java` | `type.invalid.conflicting.annos`, `type.invalid.annotations.on.use` |
| `ImplicitShallowImmutableError.java` | `implicit.shallow.immutable` |

The easiest way to see the real compiler messages is to run one focused file at
a time inside the Docker image.

Start the container:

```bash
docker run --rm -it --entrypoint bash pico-artifact:latest
```

Inside the container, build the Checker Framework javac wrapper once:

```bash
cd /workspace/checker-framework
bash ./gradlew assembleforjavac
mkdir -p /workspace/results/tutorial-classes
```

Then run one tutorial file. The `|| true` suffix keeps the shell open after the
checker reports the expected error.

```bash
sh ./checker/bin/javac -processor pico \
  -Xmaxerrs 200 -Xlint:none -Alint=-all \
  -d /workspace/results/tutorial-classes \
  ../tutorial/pico-errors/FieldWriteError.java \
  || true
```

To run all tutorial files:

```bash
cd /workspace
bash scripts/run-pico-error-tutorial.sh
```

This writes the transcript to `tutorial/pico-errors/expected-output.txt`.
