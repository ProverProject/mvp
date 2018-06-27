package io.prover.provermvp.detector;

import android.media.Image;
import android.os.Build;
import android.support.annotation.Nullable;
import android.support.annotation.RequiresApi;
import android.util.Log;

import java.nio.ByteBuffer;
import java.util.Locale;

import io.prover.provermvp.BuildConfig;
import io.prover.provermvp.camera.Size;
import io.prover.provermvp.controller.CameraController;
import io.prover.provermvp.util.Frame;
import io.prover.provermvp.util.FrameRateCounter;

import static io.prover.provermvp.Const.TAG;
import static io.prover.provermvp.detector.DetectionState.State.Confirmed;
import static io.prover.provermvp.detector.DetectionState.State.InputCode;
import static io.prover.provermvp.detector.DetectionState.State.Waiting;

/**
 * Created by babay on 11.11.2017.
 */

public class ProverDetector {
    static {
        System.loadLibrary("native-lib");
        System.loadLibrary("opencv_java3");
    }

    private final int[] detectionResult = new int[5];
    private final CameraController cameraController;
    private final FrameRateCounter fpsCounter = new FrameRateCounter(60, 3);
    private final DetectorTimesCounter timesCounter = new DetectorTimesCounter(120);
    long detectionTimeSum = 0;
    int detectionCalls = 0;
    private DetectionState detectionState;
    private int orientationHint;
    private boolean swypeCodeConfirmed = false;
    private long nativeHandler;
    private String swypeCode;
    private byte[] planeY, planeU, planeV;

    public ProverDetector(CameraController cameraController) {
        this.cameraController = cameraController;
    }

    public void init(Size videoSize, Size detectorSize, int orientation) {
        this.orientationHint = orientation;
        if (nativeHandler == 0) {
            nativeHandler = initSwype(videoSize.ratio, detectorSize.width, detectorSize.height);
        }
    }

    public synchronized void setSwype(String swype) {
        String oldSwype = this.swypeCode;
        this.swypeCode = swype == null ? null : SwypeOrientationHelper.rotateSwypeCode(swype, orientationHint);

        updateSwype(swypeCode != null && !swypeCode.equals(oldSwype));
        Log.d("ProverMVPDetector", String.format("Set swype code %s/%s", swype, swypeCode));
    }

    private void updateSwype(boolean sendNotification) {
        if (nativeHandler == 0) {
            return;
        }

        setSwype(nativeHandler, swypeCode);
        if (sendNotification)
            cameraController.notifyActualSwypeCodeSet(swypeCode);
    }

    public synchronized void release() {
        if (nativeHandler != 0) {
            releaseNativeHandler(nativeHandler);
        }
        nativeHandler = 0;
        Log.d(TAG, String.format("detect3 average detect time: %f", detectionTimeSum / (double) detectionCalls));
    }

    byte[] temp = null;
    int saveFrame = 0;
    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public void detectFrame(Frame frame) {
        int width = frame.width;
        int height = frame.height;

        if (nativeHandler != 0) {
            long time = System.currentTimeMillis();
            if (frame.image != null) {

                Image.Plane planeY = frame.image.getPlanes()[0];
                /*Image.Plane planeU = frame.image.getPlanes()[1];
                Image.Plane planeV = frame.image.getPlanes()[2];
                if (temp == null || temp.length != width * height * 4)
                    temp = new byte[width * height * 4];
                detectFrameColored(nativeHandler,
                        planeY.getBuffer(), planeY.getRowStride(), planeY.getPixelStride(),
                        planeU.getBuffer(), planeU.getRowStride(), planeU.getPixelStride(),
                        planeV.getBuffer(), planeV.getRowStride(), planeV.getPixelStride(),
                        width, height, frame.timeStamp, detectionResult, temp);
                if (saveFrame > 0) {
                    BitmapHelper.saveGrayscale(temp, width, height, "temp" + saveFrame + ".png");
                    --saveFrame;
                }//*/
                detectFrameY_8BufStrided(nativeHandler, planeY.getBuffer(), planeY.getRowStride(), planeY.getPixelStride(), width, height, frame.timeStamp, detectionResult);
            } else if (frame.data != null) {
                detectFrameNV21(nativeHandler, frame.data, width, height, frame.timeStamp, detectionResult);
            }

            timesCounter.add(System.currentTimeMillis() - time);
            detectionTimeSum += (System.currentTimeMillis() - time);
            detectionCalls++;
            if (BuildConfig.DEBUG)
                Log.d(TAG, "detection took: " + (System.currentTimeMillis() - time));
            if (cameraController.enableScreenLog) {
                int rowStride = frame.image == null ? width : frame.image.getPlanes()[0].getRowStride();
                int pixelStride = frame.image == null ? width : frame.image.getPlanes()[0].getPixelStride();
                int bufSize = frame.image == null ? frame.data.length : frame.image.getPlanes()[0].getBuffer().limit();
                float dx = detectionResult[2] / 1024f;
                float dy = detectionResult[3] / 1024f;
                String text = String.format(Locale.getDefault(), "Detector: %dx%d=%d, f%d(%d,%d) %d,%d,%+.3f,%+.3f,%d, %d ms",
                        width, height, bufSize, frame.format, rowStride, pixelStride,
                        detectionResult[0], detectionResult[1], dx, dy, detectionResult[4],
                        System.currentTimeMillis() - time);
                cameraController.addToScreenLog(text);
            }
        }
        detectionDone();
    }

    private void detectionDone() {
        if (detectionState == null || !detectionState.isEqualsArray(detectionResult)) {
            final DetectionState oldState = detectionState;
            final DetectionState newState = new DetectionState(detectionResult);
            detectionState = newState;
            cameraController.notifyDetectionStateChanged(oldState, newState);
            if (oldState != null && oldState.state == InputCode && newState.state == Waiting) {
                updateSwype(true);
            }
            if (detectionState != null && detectionState.state == Confirmed && !swypeCodeConfirmed) {
                cameraController.onSwypeCodeConfirmed();
                swypeCodeConfirmed = true;
            }
        }
        float fps = fpsCounter.addFrame();
        if (fps >= 0) {
            cameraController.onDetectorFpsUpdate(fps);
        }
    }

    /**
     * initialize swype with specific fps and swype code
     *
     * @param videoAspectRatio
     * @param detectorWidth
     * @param detectorHeight
     */
    private native long initSwype(float videoAspectRatio, int detectorWidth, int detectorHeight);

    /**
     * set swype code
     *
     * @param nativeHandler
     * @param swype
     */
    private native void setSwype(long nativeHandler, String swype);

    private void ensureBuffers(int width, int height) {
        int size = width * height;
        if (planeY == null || planeY.length != size)
            planeY = new byte[size];
        size = size / 4;
        if (planeU == null || planeU.length != size)
            planeU = new byte[size];
        if (planeV == null || planeV.length != size)
            planeV = new byte[size];
    }

    private void parsePaddedPlane(Image.Plane plane, int width, int height, byte[] result) {
        ByteBuffer planeBuf = plane.getBuffer();
        int rowStride = plane.getRowStride();
        int pixelStride = plane.getPixelStride();
        parsePaddedPlane(planeBuf, rowStride, pixelStride, width, height, result);
    }

    /**
     * detect single frame
     *
     * @param frameData
     * @param width
     * @param height
     * @param result    -- an array with 4 items: State, Index, X, Y
     */
    private native void detectFrameNV21(long nativeHandler, byte[] frameData, int width, int height, int timestamp, int[] result);

    private native void detectFrameY_8BufStrided(long nativeHandler, ByteBuffer planeY, int rowStride, int pixelStride, int width, int height, int timestamp, int[] result);

    private native void detectFrameColored(long nativeHandler, ByteBuffer planeY, int yRowStride, int yPixelStride,
                                           ByteBuffer planeU, int uRowStride, int uPixelStride,
                                           ByteBuffer planeV, int vRowStride, int vPixelStride,
                                           int width, int height, int timestamp, int[] result, @Nullable byte[] debugImage);

    private native void releaseNativeHandler(long nativeHandler);

    private native void parsePaddedPlane(ByteBuffer plane, int rowStride, int pixelStride, int width, int height, byte[] result);

    private native void yuvToRgb(byte[] y, byte[] u, byte[] v, int[] rgb, int width, int height);
}
