package org.checkerframework.checker.pico;

import org.checkerframework.framework.type.AbstractViewpointAdapter;
import org.checkerframework.framework.type.AnnotatedTypeFactory;
import org.checkerframework.framework.type.AnnotatedTypeMirror;
import org.checkerframework.javacutil.AnnotationUtils;
import org.checkerframework.javacutil.BugInCF;

import javax.lang.model.element.AnnotationMirror;

/** A {@link AbstractViewpointAdapter} for the PICO checker. */
public class PICOViewpointAdapter extends AbstractViewpointAdapter {
    /** The PICO type factory. */
    private PICONoInitAnnotatedTypeFactory picoTypeFactory;

    /**
     * Create a new {@link PICOViewpointAdapter}.
     *
     * @param atypeFactory the type factory
     */
    public PICOViewpointAdapter(AnnotatedTypeFactory atypeFactory) {
        super(atypeFactory);
        picoTypeFactory = (PICONoInitAnnotatedTypeFactory) atypeFactory;
    }

    @Override
    protected AnnotationMirror extractAnnotationMirror(AnnotatedTypeMirror atm) {
        return atm.getAnnotationInHierarchy(picoTypeFactory.READONLY);
    }

    @Override
    protected AnnotationMirror combineAnnotationWithAnnotation(
            AnnotationMirror receiverAnnotation, AnnotationMirror declaredAnnotation) {
        if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.READONLY)) {
            return picoTypeFactory.READONLY;
        } else if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.MUTABLE)) {
            return picoTypeFactory.MUTABLE;
        } else if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.IMMUTABLE)) {
            return picoTypeFactory.IMMUTABLE;
        } else if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.BOTTOM)) {
            return picoTypeFactory.BOTTOM;
        } else if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.POLY_MUTABLE)) {
            return picoTypeFactory.POLY_MUTABLE;
        } else if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.LOST)) {
            return picoTypeFactory.LOST;
        } else if (AnnotationUtils.areSame(
                declaredAnnotation, picoTypeFactory.RECEIVER_DEPENDENT_MUTABLE)) {
            // @Readonly |> @ReceiverDependentMutable = @Lost
            if (AnnotationUtils.areSame(receiverAnnotation, picoTypeFactory.READONLY)) {
                return picoTypeFactory.LOST;
            } else {
                return receiverAnnotation;
            }
        } else {
            throw new BugInCF("Unknown declared modifier: " + declaredAnnotation);
        }
    }

    /**
     * Viewpoint adaptation for a method invocation receiver parameter.
     *
     * <p>Unlike ordinary value adaptation, an RDM receiver declaration adapts to the caller's
     * receiver qualifier. The method's ordinary parameters and return type still use value adaptation
     * through {@link #combineAnnotationWithAnnotation(AnnotationMirror, AnnotationMirror)}.
     *
     * @param receiverAnnotation qualifier on the call-site receiver
     * @param declaredAnnotation qualifier on the declared method receiver
     * @return the receiver-adapted qualifier
     */
    public AnnotationMirror combineReceiverAnnotationWithAnnotation(
            AnnotationMirror receiverAnnotation, AnnotationMirror declaredAnnotation) {
        if (AnnotationUtils.areSame(declaredAnnotation, picoTypeFactory.RECEIVER_DEPENDENT_MUTABLE)) {
            return receiverAnnotation;
        }
        return combineAnnotationWithAnnotation(receiverAnnotation, declaredAnnotation);
    }
}
