import org.checkerframework.checker.pico.qual.ReceiverDependentMutable;

class StaticRDMError {
    // PICO reports: static.receiverdependentmutable.forbidden
    static @ReceiverDependentMutable Object rejected =
            new @ReceiverDependentMutable Object();
}
