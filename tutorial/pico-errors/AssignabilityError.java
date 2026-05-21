import org.checkerframework.checker.pico.qual.Assignable;

class AssignabilityError {
    // PICO reports: assignability.declaration.invalid
    final @Assignable int rejected = 0;
}
