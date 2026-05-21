import org.checkerframework.checker.pico.qual.Immutable;
import org.checkerframework.checker.pico.qual.Mutable;
import org.checkerframework.checker.pico.qual.Readonly;

class InvalidAnnotationError {
    // Checker Framework reports: type.invalid.conflicting.annos
    @Readonly @Immutable Object conflicting;

    // Checker Framework reports: type.invalid.annotations.on.use
    @Mutable int primitive;
}
