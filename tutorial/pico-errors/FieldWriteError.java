import org.checkerframework.checker.pico.qual.Mutable;
import org.checkerframework.checker.pico.qual.Readonly;
import org.checkerframework.checker.pico.qual.ReceiverDependentMutable;

class FieldWriteError {
    @ReceiverDependentMutable static class Box {
        int value;

        void rejected(@Readonly Box this) {
            // PICO reports: illegal.field.write
            this.value = 1;
        }

        void accepted(@Mutable Box this) {
            this.value = 1;
        }
    }
}
