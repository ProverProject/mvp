package io.prover.provermvp.viewholder;

import android.content.res.Resources;
import android.graphics.Matrix;
import android.os.Build;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.constraint.ConstraintLayout;
import android.support.graphics.drawable.AnimatedVectorDrawableCompat;
import android.support.graphics.drawable.VectorDrawableCompat;
import android.transition.TransitionManager;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;

import java.io.File;
import java.util.Arrays;

import io.prover.provermvp.Const;
import io.prover.provermvp.R;
import io.prover.provermvp.Settings;
import io.prover.provermvp.controller.CameraController;
import io.prover.provermvp.detector.DetectionState;
import io.prover.provermvp.view.DefectView;

import static io.prover.provermvp.detector.DetectionState.State.InputCode;

/**
 * Created by babay on 22.11.2017.
 */

public class SwypeViewHolder implements CameraController.OnDetectionStateCahngedListener,
        CameraController.OnSwypeCodeSetListener, CameraController.OnRecordingStartListener, CameraController.OnRecordingStopListener {
    private final ConstraintLayout root;
    private final CameraController cameraController;
    private final SwipePointImageViewHolder[] swypePoints = new SwipePointImageViewHolder[9];
    private final RedPointHolder redPoint;
    private final Handler handler = new Handler();
    private final SwypeArrowHolder swypeArrowHolder;
    private final Matrix rotateScaleMatrix = new Matrix();
    //private final Matrix pointMatrix = new Matrix();
    //private final float[] point = new float[2];
    private final Resources res;
    float xMult, yMult;
    DefectView defectView;
    private String swype;
    private SwipePointImageViewHolder[] swypeSequence;
    private int[] sequenceIndices;
    private boolean[] pointVisited;
    private int detectProgressPos;
    private VectorDrawableCompat emptyPointDrawable;
    private SwypeHolderState state = SwypeHolderState.Hidden;
    private boolean flipxy;

    public SwypeViewHolder(ConstraintLayout root, CameraController cameraController) {
        this.res = root.getResources();
        this.root = root;
        this.cameraController = cameraController;

        swypePoints[0] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint1), 1);
        swypePoints[1] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint2), 2);
        swypePoints[2] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint3), 3);
        swypePoints[3] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint4), 4);
        swypePoints[4] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint5), 5);
        swypePoints[5] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint6), 6);
        swypePoints[6] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint7), 7);
        swypePoints[7] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint8), 8);
        swypePoints[8] = new SwipePointImageViewHolder(root.findViewById(R.id.swypePoint9), 9);

        redPoint = new RedPointHolder(root.findViewById(R.id.swypeCurrentPosition));
        swypeArrowHolder = new SwypeArrowHolder(root, swypePoints);

        cameraController.detectionState.add(this);
        cameraController.swypeCodeSet.add(this);
        cameraController.onRecordingStart.add(this);
        cameraController.onRecordingStop.add(this);
        root.setVisibility(View.GONE);

        if (Settings.SHOW_DEFECT) {
            defectView = new DefectView(root.getContext());
            ConstraintLayout.LayoutParams lp = new ConstraintLayout.LayoutParams(0, 0);
            lp.leftToLeft = ConstraintLayout.LayoutParams.PARENT_ID;
            lp.topToTop = ConstraintLayout.LayoutParams.PARENT_ID;
            lp.rightToRight = ConstraintLayout.LayoutParams.PARENT_ID;
            lp.bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID;
            root.addView(defectView, lp);
        }
    }

    @Override
    public void onDetectionStateChanged(@Nullable DetectionState oldState, @NonNull DetectionState newState) {
        boolean shouldProcess = setState(newState.state);

        if (shouldProcess && swypeSequence != null) {

            int index = newState.index - 1;
            if (index >= swypeSequence.length)
                index = swypeSequence.length - 1;
            if (index >= 0 && !pointVisited[index] && shouldProcess) {
                pointVisited[index] = true;
                swypeSequence[index].setState(SwipePointImageViewHolder.State.Visited);
                detectProgressPos = index;
                if (detectProgressPos < swypeSequence.length - 1) {
                    swypeArrowHolder.show(sequenceIndices[detectProgressPos], sequenceIndices[detectProgressPos + 1]);
                } else {
                    swypeArrowHolder.hide();
                }
                redPoint.setRedPointPositionMatrixTo(swypeSequence[index].view, rotateScaleMatrix);
                if (index + 1 < swypeSequence.length) {
                    swypeSequence[index + 1].setState(SwipePointImageViewHolder.State.Unvisited);
                }
                redPoint.setVisible(true);
                if (defectView != null && index + 1 < swypeSequence.length) {
                    defectView.configureBorder(swypeSequence[index].num, swypeSequence[index + 1].num);
                    defectView.setVisibility(View.VISIBLE);
                }
            }
            redPoint.setTranslation(newState.x, newState.y);

            if (defectView != null) {
                float dx = (newState.d >> 16) * xMult;
                float dy = (newState.d & 0xFFFF) * yMult;
                if (flipxy) {
                    float tmp = dy;
                    dy = dx;
                    dx = tmp;
                }
                defectView.set(redPoint.centerX(), redPoint.centerY(), dx, dy);
            }
        }
    }

    @Override
    public void onSwypeCodeSet(String swypeCode, String actualSwypeCode) {
        this.swype = swype;

        loadDrawables();
        swypeSequence = new SwipePointImageViewHolder[swypeCode.length()];
        sequenceIndices = new int[swypeCode.length()];
        pointVisited = new boolean[swypeCode.length()];
        char[] charArray = swypeCode.toCharArray();

        for (int i = 0; i < charArray.length; i++) {
            char ch = charArray[i];
            int pos = ch - '1';
            if (pos >= 0 && pos < 9) {
                swypeSequence[i] = swypePoints[pos];
                sequenceIndices[i] = pos;
            }
        }
        rotateScaleMatrix.reset();
        int orientation = cameraController.getOrientationHint();
        rotateScaleMatrix.postScale(1, 1);
        rotateScaleMatrix.postRotate(orientation, 0, 0);
        rotateScaleMatrix.postScale(xMult, yMult);
        flipxy = orientation % 180 == 90;
    }

    @Override
    public void onRecordingStart() {
        float size = res.getDisplayMetrics().density * 96;
        xMult = size / 1024.0f;
        yMult = size / 1024.0f;
    }

    private void loadDrawables() {
        if (emptyPointDrawable == null) {
            emptyPointDrawable = VectorDrawableCompat.create(res, R.drawable.ic_swype_empty, null);
            emptyPointDrawable.setBounds(0, 0, emptyPointDrawable.getIntrinsicWidth(), emptyPointDrawable.getIntrinsicHeight());
        }
    }

    private void show() {
        Log.d(Const.TAG + "Swype", "swype show");
        root.setVisibility(View.VISIBLE);
        detectProgressPos = -1;
        int animationDuration = res.getInteger(R.integer.swypeBlinkAnimationDuration);
        Arrays.fill(pointVisited, false);
        swypeArrowHolder.hide();

        for (SwipePointImageViewHolder swypePoint : swypePoints) {
            swypePoint.setState(SwipePointImageViewHolder.State.None, emptyPointDrawable);
        }

        for (int i = 0; i < swypeSequence.length; i++) {
            final int pos = i;
            handler.postDelayed(() -> {
                if (swypeSequence == null)
                    return;
                swypeSequence[pos].setState(SwipePointImageViewHolder.State.Unvisited);
            }, animationDuration * i);
        }

        redPoint.setVisible(false);
        redPoint.setRedPointPositionMatrixTo(swypeSequence[0].view, rotateScaleMatrix);
        redPoint.setTranslation(0, 0);

        handler.postDelayed(() -> {
            redPoint.setVisible(true);
            if (swypeSequence != null) {
                swypeSequence[0].setState(SwipePointImageViewHolder.State.Visited);
            }
        }, animationDuration * (swypeSequence.length + 1));
        if (defectView != null)
            defectView.setVisibility(View.GONE);
    }

    private void applyAnimatedVectorDrawable(ImageView view, int id) {
        AnimatedVectorDrawableCompat dr = AnimatedVectorDrawableCompat.create(root.getContext(), id);
        dr.setBounds(0, 0, dr.getIntrinsicWidth(), dr.getIntrinsicHeight());
        view.setImageDrawable(dr);
        dr.start();
    }

    public void hide() {
        root.setVisibility(View.GONE);
    }

    @Override
    public void onRecordingStop(File file, boolean isVideoConfirmed) {
        hide();
        swypeSequence = null;
    }

    private void showFailed() {
        for (SwipePointImageViewHolder swypePoint : swypePoints) {
            swypePoint.setState(SwipePointImageViewHolder.State.Failed);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            TransitionManager.beginDelayedTransition(root);
        }
        redPoint.setVisible(false);
        swypeArrowHolder.hide();

        handler.postDelayed(() -> {
            if (state == SwypeHolderState.Failed) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    TransitionManager.beginDelayedTransition(root);
                }
                hide();
            }
        }, 1500);
    }


    /*private void showCompleted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            TransitionManager.beginDelayedTransition((ViewGroup) root.getParent());
        }
        ObjectAnimator animator = ObjectAnimator.ofFloat(root, "alpha", 1, 0);
        animator.setDuration(400);
        animator.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                root.setAlpha(1);
                root.setVisibility(View.GONE);
            }
        });
        animator.start();
    }*/

    /**
     * @param state
     * @return true if state should be processed
     */
    public boolean setState(DetectionState.State state) {
        SwypeHolderState oldState = this.state;
        this.state = SwypeHolderState.ofDetectorState(state, this.state);
        if (this.state == SwypeHolderState.Showing && swypeSequence == null) {
            this.state = SwypeHolderState.Hidden;
        }

        switch (this.state) {
            case Hidden:
                if (oldState != this.state)
                    hide();
                return false;

            case Showing:
                if (oldState != this.state)
                    show();
                return state == InputCode;

            case Completed:
                /*if (oldState != this.state)
                    showCompleted();*/
                return true;

            case Failed:
                if (oldState != this.state) {
                    showFailed();
                    return true;
                }
                return false;

        }
        return false;
    }

    private enum SwypeHolderState {
        Hidden, Showing, Failed, Completed;

        public static SwypeHolderState ofDetectorState(DetectionState.State state, SwypeHolderState current) {
            switch (state) {
                case Waiting:
                case GotProverNoCode:
                    switch (current) {
                        case Failed:
                        case Showing:
                            return Failed;

                        case Completed:
                            return Completed;

                        case Hidden:
                            return Hidden;
                    }
                    return Hidden;

                case GotProverWaiting:
                case InputCode:
                    return Showing;

                case Confirmed:
                    return Completed;
            }
            return Hidden;
        }
    }
}
