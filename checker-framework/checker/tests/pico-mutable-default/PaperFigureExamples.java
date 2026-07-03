import org.checkerframework.checker.pico.qual.Assignable;
import org.checkerframework.checker.pico.qual.Immutable;
import org.checkerframework.checker.pico.qual.Mutable;
import org.checkerframework.checker.pico.qual.Readonly;
import org.checkerframework.checker.pico.qual.ReceiverDependentMutable;

public class PaperFigureExamples {
    // Section 2.1 shallow immutability and Section 2.2 RDA/RDM running example.
    // In the implementation, RDA is implicit for non-final instance fields without @Assignable.
    @ReceiverDependentMutable class Box {
        final @Immutable int i1 = 1;
        @Assignable @Immutable int i2 = 2;
        int i3 = 3;

        @ReceiverDependentMutable Box() {}
    }

    // Section 2.2 OuterBox running example, plus Figure 1's assignable RDM field.
    @ReceiverDependentMutable class OuterBox {
        @ReceiverDependentMutable Box box;
        @Assignable @ReceiverDependentMutable Box assignableBox;

        @ReceiverDependentMutable OuterBox(@ReceiverDependentMutable Box box) {
            this.box = box;
            this.assignableBox = box;
        }

        // Section 2.2 method receiver typing example.
        void setBox(@Mutable OuterBox this, @Mutable Box box) {
            this.box = box;
        }

        // Section 2.2 receiver-dependent return example, replacing the RO/Mut/Imm overloads.
        @ReceiverDependentMutable Box getBox(@ReceiverDependentMutable OuterBox this) {
            return this.box;
        }
    }

    // Section 2.1 qualifiers and shallow immutability examples.
    void shallowImmutability() {
        @Mutable Box mutRef = new @Mutable Box();
        mutRef.i2 = 4;

        @Mutable Object mutObject = new @Mutable Object();
        @Immutable Object immRef = new @Immutable Object();
        @Readonly Object roRef = mutObject;
        roRef = immRef;
        // :: error: (assignment.type.incompatible)
        immRef = mutObject;
    }

    // Section 2.2 transitive immutability and context-sensitive field adaptation example.
    void transitiveImmutability() {
        @Mutable OuterBox mutOuterRef = new @Mutable OuterBox(new @Mutable Box());
        mutOuterRef.box = new @Mutable Box();
        mutOuterRef.box.i3 = 5;

        @Immutable OuterBox immOuterRef = new @Immutable OuterBox(new @Immutable Box());
        // :: error: (assignment.type.incompatible) :: error: (illegal.field.write)
        immOuterRef.box = new @Mutable Box();
        // :: error: (illegal.field.write)
        immOuterRef.box.i3 = 5;
    }

    // Section 2.2 method receiver typing call-site example.
    void receiverTyping(
            @Immutable OuterBox immOuterRef,
            @Mutable OuterBox mutOuterRef,
            @Mutable Box mutableBox) {
        // :: error: (method.invocation.invalid)
        immOuterRef.setBox(mutableBox);
        mutOuterRef.setBox(mutableBox);
    }

    // Section 2.2 receiver-dependent return call-site example. A readonly receiver can invoke the
    // RDM receiver method, but the RDM return still uses value adaptation, yielding @Lost.
    void receiverDependentReturn(
            @Mutable OuterBox mutOuterRef,
            @Immutable OuterBox immOuterRef,
            @Readonly OuterBox roOuterRef) {
        @Mutable Box mutBox = mutOuterRef.getBox();
        @Immutable Box immBox = immOuterRef.getBox();
        @Readonly Box roBox = roOuterRef.getBox();
        // :: error: (assignment.type.incompatible)
        @Mutable Box mutFromReadonly = roOuterRef.getBox();
    }

    // Figure 1: cross-type aliasing is rejected because RO access to an RDM field yields @Lost.
    void swapField(@Readonly OuterBox box1, @Readonly OuterBox box2) {
        // :: error: (assignment.type.incompatible)
        box1.assignableBox = box2.assignableBox;
    }

    class HashTable<K, V> {}

    // Figure 2: fields outside the abstract state can support benign mutation/caching patterns.
    class ImmContainer<K, V> {
        @Assignable @Immutable int index;
        final @Mutable HashTable<K, V> table = new @Mutable HashTable<K, V>();
    }

    // Figure 7: immutable subclass of an RDM superclass.
    @Immutable class ImmOuterBox extends OuterBox {
        @Immutable ImmOuterBox(@Immutable Box box) {
            super(box);
        }

        @Immutable Box getBox(@Immutable ImmOuterBox this) {
            return this.box;
        }
    }

    // Figure 7: mutable subclass of an RDM superclass.
    @Mutable class MutOuterBox extends OuterBox {
        @Mutable MutOuterBox(@Mutable Box box) {
            super(box);
        }

        void setBox(@Mutable MutOuterBox this, @Mutable Box box) {
            this.box = box;
        }

        @Mutable Box getBox(@Mutable MutOuterBox this) {
            return this.box;
        }
    }

    // Figure 6: polymorphic constructor calls for Mut, Imm, and RDM creations.
    void polymorphicConstructors() {
        @Mutable OuterBox mutOuterRef = new @Mutable OuterBox(new @Mutable Box());
        @Immutable OuterBox immOuterRef = new @Immutable OuterBox(new @Immutable Box());
        @ReceiverDependentMutable OuterBox rdmOuterRef =
                new @ReceiverDependentMutable OuterBox(new @ReceiverDependentMutable Box());
    }
}
