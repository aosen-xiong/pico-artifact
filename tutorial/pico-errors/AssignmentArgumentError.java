import org.checkerframework.checker.pico.qual.Immutable;
import org.checkerframework.checker.pico.qual.Mutable;
import org.checkerframework.checker.pico.qual.Readonly;

class AssignmentArgumentError {
    static void needsMutable(@Mutable Object value) {}

    void rejected(@Immutable Object immutable, @Readonly Object readonly) {
        // Checker Framework reports this PICO qualifier mismatch as:
        // assignment.type.incompatible
        @Mutable Object mutable = immutable;

        // Checker Framework reports this PICO qualifier mismatch as:
        // argument.type.incompatible
        needsMutable(readonly);
    }
}
