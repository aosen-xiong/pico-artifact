import org.checkerframework.checker.pico.qual.Immutable;
import org.checkerframework.checker.pico.qual.Readonly;

class ArrayWriteError {
    void rejectedWrite(String @Immutable [] array) {
        // PICO reports: illegal.array.write
        array[0] = "updated";
    }

    void rejectedArrayCreation() {
        // PICO reports: array.new.invalid
        int[] values = new int @Readonly [] {1, 2, 3};
    }
}
