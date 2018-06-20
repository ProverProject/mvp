#include <jni.h>
#include <string>
#include "swype_detect.h"
#include "common.h"

void parseRowPaddedPlane(const unsigned char *frameData, unsigned int width, unsigned int height,
                         unsigned int rowStride, unsigned char *dest) {
    int i = 0;
    if (frameData == dest) {
        frameData += rowStride;
        dest += width;
        i = 1;
    }
    for (; i < height; i++) {
        memmove(dest, frameData, width);
        frameData += rowStride;
        dest += width;
    }
}

void parsePixelPaddedPlane(const unsigned char *frameData, unsigned int width, unsigned int height,
                           unsigned int rowStride, unsigned int pixelStride,
                           unsigned char *dest) {
    for (int row = 0; row < height; row++) {
        const unsigned char *srcPos = frameData;
        for (int col = 0; col < width; col++) {
            *dest = *srcPos;
            ++dest;
            srcPos += pixelStride;
        }
        frameData += rowStride;
    }
}

void *
parsePlane(JNIEnv *env, jobject plane, jint rowStride, jint pixelStride, jint width, jint height) {
    int rowWidth = width * pixelStride;
    int rowPadding = rowStride - rowWidth;
    int pixelPadding = pixelStride - 1;
    jlong extectedBufferSize = height * rowStride - rowPadding - pixelPadding;
    jlong len = env->GetDirectBufferCapacity(plane);

    if (len < extectedBufferSize) {
        LOGE_NATIVE("detector buffers sizes: %zd, expected: %zd", len, extectedBufferSize);
        return NULL;
    }

    unsigned char *frameData = (unsigned char *) env->GetDirectBufferAddress(plane);

    if (rowStride > width) {
        if (pixelStride == 1) {
            parseRowPaddedPlane(frameData, (unsigned int) width, (unsigned int) height,
                                (unsigned int) rowStride, frameData);
        } else {
            parsePixelPaddedPlane(frameData, (unsigned int) width, (unsigned int) height,
                                  (unsigned int) rowStride, (unsigned int) pixelStride, frameData);
        }
    }
    return frameData;
}

extern "C" {

JNIEXPORT jlong JNICALL
Java_io_prover_provermvp_detector_ProverDetector_initSwype(JNIEnv *env, jobject instance,
                                                           jfloat videoAspectRatio,
                                                           jint detectorWidth,
                                                           jint detectorHeight) {
    SwypeDetect *detector = new SwypeDetect();
    detector->init(videoAspectRatio, detectorWidth, detectorHeight);
    detector->setRelaxed(false);
    logLevel = 0;//5;
    return (jlong) detector;
}

JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_setSwype(JNIEnv *env, jobject instance,
                                                          jlong nativeHandler, jstring swype_) {
    std::string swype;

    if (swype_ == NULL) {
        swype = "";
    } else {
        const char *chars = env->GetStringUTFChars(swype_, 0);
        int len = env->GetStringUTFLength(swype_);
        char *chars2 = new char[len + 1];;
        chars2[len] = 0;
        memcpy(chars2, chars, len);
        swype = std::string(chars);
        delete[] chars2;
        env->ReleaseStringUTFChars(swype_, chars);
    }

    LOGI_NATIVE("detection: set swype %s", swype.c_str());

    SwypeDetect *detector = (SwypeDetect *) nativeHandler;
    detector->setSwype(swype);
}

JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_detectFrameNV21(JNIEnv *env, jobject instance,
                                                                 jlong nativeHandler,
                                                                 jbyteArray frameData_, jint width,
                                                                 jint height, jint timestamp,
                                                                 jintArray result_) {

    SwypeDetect *detector = (SwypeDetect *) nativeHandler;
    jbyte *frameData = env->GetByteArrayElements(frameData_, NULL);
    jint *res = env->GetIntArrayElements(result_, NULL);

    static long counter = 0;
    LOGI_NATIVE("start frame detection %ld", counter);

    detector->processFrame((const unsigned char *) frameData, width, height, (uint) timestamp,
                           res[0], res[1], res[2], res[3], res[4]);

    env->ReleaseIntArrayElements(result_, res, JNI_COMMIT_AND_RELEASE);
    env->ReleaseByteArrayElements(frameData_, frameData, JNI_ABORT);
}

JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_detectFrameY_18BufStrided(JNIEnv *env,
                                                                           jobject instance,
                                                                           jlong nativeHandler,
                                                                           jobject planeY,
                                                                           jint rowStride,
                                                                           jint pixelStride,
                                                                           jint width, jint height,
                                                                           jint timestamp,
                                                                           jintArray result_) {
    jint *res = env->GetIntArrayElements(result_, NULL);

    unsigned char *frameData = (unsigned char *) (parsePlane(env, planeY, rowStride, pixelStride,
                                                             width, height));

    if (frameData != NULL) {
        SwypeDetect *detector = (SwypeDetect *) nativeHandler;
        detector->processFrame(frameData, width, height, (uint) timestamp, res[0], res[1], res[2],
                               res[3], res[4]);
    }

    env->ReleaseIntArrayElements(result_, res, JNI_COMMIT_AND_RELEASE);
}

JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_releaseNativeHandler(JNIEnv *env, jobject instance,
                                                                      jlong nativeHandler) {

    SwypeDetect *detector = (SwypeDetect *) nativeHandler;
    if (detector == NULL) {
        LOGE_NATIVE("trying to close NULL detector");
    } else {
        LOGI_NATIVE("requested detector close");
        delete detector;
        LOGI_NATIVE("detector closed");
    }
}

}
extern "C"
JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_parsePaddedPlane(JNIEnv *env, jobject instance,
                                                                  jobject plane, jint rowStride,
                                                                  jint pixelStride, jint width,
                                                                  jint height, jbyteArray result_) {
    jbyte *res = env->GetByteArrayElements(result_, NULL);

    int rowWidth = width * pixelStride;
    int rowPadding = rowStride - rowWidth;
    int pixelPadding = pixelStride - 1;
    jlong extectedBufferSize = height * rowStride - rowPadding - pixelPadding;
    jlong len = env->GetDirectBufferCapacity(plane);

    if (len < extectedBufferSize) {
        LOGE_NATIVE("detector buffers sizes: %zd, expected: %zd", len, extectedBufferSize);
        res[0] = static_cast<jbyte>(len);
        res[1] = static_cast<jbyte >(extectedBufferSize);
        env->ReleaseByteArrayElements(result_, res, JNI_COMMIT_AND_RELEASE);
        return;
    }

    unsigned char *frameData = (unsigned char *) env->GetDirectBufferAddress(plane);

    if (rowStride > width) {
        if (pixelStride == 1) {
            parseRowPaddedPlane(frameData, (unsigned int) width, (unsigned int) height,
                                (unsigned int) rowStride, (unsigned char *) res);
        } else {
            parsePixelPaddedPlane(frameData, (unsigned int) width, (unsigned int) height,
                                  (unsigned int) rowStride, (unsigned int) pixelStride,
                                  (unsigned char *) res);
        }
    } else {
        memcpy(res, frameData, static_cast<size_t>(len));
    }

    env->ReleaseByteArrayElements(result_, res, JNI_COMMIT_AND_RELEASE);
}

inline int clamp262143(int value) {
    return value < 0 ? 0 : value > 262143 ? 262143 : value;
}

void yuvToRgb(jbyte *yArr, jbyte *uArr, jbyte *vArr, jint *argb, int width, int height) {
    int r, g, b, y1192, y, i, uvp, u, v;
    int halfWidth = width >> 1;
    for (int j = 0; j < height; j++) {
        uvp = (j >> 1) * halfWidth;
        u = 0;
        v = 0;
        for (i = 0; i < width; i++, ++yArr) {
            y = (0xff & ((int) (*yArr))) - 16;
            if (y < 0) y = 0;
            if ((i & 1) == 0) {
                u = (0xff & uArr[uvp]) - 128;
                v = (0xff & vArr[uvp]) - 128;
                ++uvp;
            }
            y1192 = 1192 * y;
            r = clamp262143((y1192 + 1634 * v));
            g = clamp262143((y1192 - 833 * v - 400 * u));
            b = clamp262143((y1192 + 2066 * u));

            *(argb++) =
                    0xff000000 | ((r << 6) & 0xff0000) | ((g >> 2) & 0xff00) | ((b >> 10) & 0xff);
        }
    }
}

extern "C"
JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_yuvToRgb(JNIEnv *env, jobject instance,
                                                          jbyteArray y_, jbyteArray u_,
                                                          jbyteArray v_, jintArray argb_,
                                                          jint width, jint height) {
    jbyte *y = env->GetByteArrayElements(y_, NULL);
    jbyte *u = env->GetByteArrayElements(u_, NULL);
    jbyte *v = env->GetByteArrayElements(v_, NULL);
    jint *argb = env->GetIntArrayElements(argb_, NULL);

    yuvToRgb(y, u, v, argb, width, height);

    env->ReleaseByteArrayElements(y_, y, JNI_ABORT);
    env->ReleaseByteArrayElements(u_, u, JNI_ABORT);
    env->ReleaseByteArrayElements(v_, v, JNI_ABORT);
    env->ReleaseIntArrayElements(argb_, argb, 0);
}

/*

extern "C"
JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_detectFrameColored(JNIEnv *env, jobject instance,
                                                                    jlong nativeHandler,
                                                                    jobject planeY, jint yRowStride,
                                                                    jint yPixelStride,
                                                                    jobject planeU, jint uRowStride,
                                                                    jint uPixelStride,
                                                                    jobject planeV, jint vRowStride,
                                                                    jint vPixelStride, jint width,
                                                                    jint height, jint timestamp,
                                                                    jintArray result_) {
    jint *res = env->GetIntArrayElements(result_, NULL);

    jbyte *frameY = (jbyte *) (parsePlane(env, planeY, yRowStride, yPixelStride,
                                          width, height));
    jbyte *frameU = (jbyte *) (parsePlane(env, planeU, uRowStride, uPixelStride,
                                          width, height));
    jbyte *frameV = (jbyte *) (parsePlane(env, planeV, vRowStride, vPixelStride,
                                          width, height));

    if (frameY != NULL && frameV != NULL && frameU != NULL) {
        SwypeDetect *detector = (SwypeDetect *) nativeHandler;
        jint *argb = detector->getRgbBuffer(width, height);
        yuvToRgb(frameY, frameU, frameV, argb, width, height);
        detector->processFrameArgb(argb, width, height, (uint) timestamp, res[0], res[1], res[2],
                                   res[3], res[4]);
    }

    env->ReleaseIntArrayElements(result_, res, JNI_COMMIT_AND_RELEASE);
}
*/
extern "C"
JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_detectFrameColored(JNIEnv *env, jobject instance,
                                                                    jlong nativeHandler,
                                                                    jobject planeY, jint yRowStride,
                                                                    jint yPixelStride,
                                                                    jobject planeU, jint uRowStride,
                                                                    jint uPixelStride,
                                                                    jobject planeV, jint vRowStride,
                                                                    jint vPixelStride, jint width,
                                                                    jint height, jint timestamp,
                                                                    jintArray result_,
                                                                    jbyteArray debugImage_) {
    jbyte *debugImage = env->GetByteArrayElements(debugImage_, NULL);
    jint *res = env->GetIntArrayElements(result_, NULL);

    jbyte *frameY = (jbyte *) (parsePlane(env, planeY, yRowStride, yPixelStride,
                                          width, height));
    jbyte *frameU = (jbyte *) (parsePlane(env, planeU, uRowStride, uPixelStride,
                                          width / 2, height / 2));
    jbyte *frameV = (jbyte *) (parsePlane(env, planeV, vRowStride, vPixelStride,
                                          width / 2, height / 2));

    if (frameY != NULL && frameV != NULL && frameU != NULL) {
        SwypeDetect *detector = (SwypeDetect *) nativeHandler;
        jint *argb = detector->getRgbBuffer(width, height);

        yuvToRgb(frameY, frameU, frameV, argb, width, height);


        detector->processFrameArgb(argb, width, height, (uint) timestamp, res[0], res[1], res[2],
                                   res[3], res[4]);

        memcpy(debugImage, argb, width * height * 4);

    } else {
        debugImage[0] = 12;
        debugImage[1] = 22;
    }


    env->ReleaseIntArrayElements(result_, res, JNI_COMMIT_AND_RELEASE);
    env->ReleaseByteArrayElements(debugImage_, debugImage, JNI_COMMIT_AND_RELEASE);
}