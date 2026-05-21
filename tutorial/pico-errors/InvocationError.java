import org.checkerframework.checker.pico.qual.Immutable;
import org.checkerframework.checker.pico.qual.Mutable;
import org.checkerframework.checker.pico.qual.ReceiverDependentMutable;

@ReceiverDependentMutable class InvocationError {
    @ReceiverDependentMutable InvocationError() {}

    @Immutable InvocationError(int ignored) {}

    @Mutable InvocationError(boolean ignored) {}

    void mutableOnly(@Mutable InvocationError this) {}

    void rejected() {
        InvocationError immutable = new @Immutable InvocationError();

        // PICO reports: method.invocation.invalid
        immutable.mutableOnly();

        // PICO reports: constructor.invocation.invalid
        InvocationError wrongConstructor = new @Mutable InvocationError(1);
    }
}
