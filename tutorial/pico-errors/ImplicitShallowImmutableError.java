import org.checkerframework.checker.pico.qual.Immutable;
import org.checkerframework.checker.pico.qual.Mutable;

@Immutable class ImplicitShallowImmutableError {
    static class MutableBox {}

    // PICO reports: implicit.shallow.immutable
    MutableBox implicit = new MutableBox();

    @Mutable MutableBox explicit = new MutableBox();
}
