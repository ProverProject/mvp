#include <jni.h>
#include <string>
#include "swype_detect.h"
#include "common.h"

extern "C" {

JNIEXPORT jlong JNICALL
Java_io_prover_provermvp_detector_ProverDetector_initSwype(JNIEnv *env, jobject instance, jint fps,
                                                           jstring swype_) {
    std::string swype;

    if (swype_ == NULL) {
        swype = "";
    } else {
        const char *chars = env->GetStringUTFChars(swype_, 0);
        swype = std::string(chars);
        env->ReleaseStringUTFChars(swype_, chars);
    }

    SwypeDetect *detector = new SwypeDetect();
    detector->init(fps, swype);
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
        swype = std::string(chars);
        env->ReleaseStringUTFChars(swype_, chars);
    }

    SwypeDetect *detector = (SwypeDetect *) nativeHandler;
    detector->setSwype(swype);
}

JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_detectFrame(JNIEnv *env, jobject instance,
                                                             jlong nativeHandler,
                                                             jbyteArray frameData_, jint width,
                                                             jint height, jintArray result_) {

    SwypeDetect *detector = (SwypeDetect *) nativeHandler;
    jbyte *frameData = env->GetByteArrayElements(frameData_, NULL);
    jint *result = env->GetIntArrayElements(result_, NULL);

    int state = 0, index = 0, x = 0, y = 0;
    static long counter = 0;
    LOGI_NATIVE("start frame detection %ld", counter);
    detector->processFrame((const unsigned char *) frameData, width, height, state, index, x, y);
    LOGI_NATIVE("done frame detection %ld", counter++);

    result[0] = state;
    result[1] = index;
    result[2] = x;
    result[3] = y;

    env->ReleaseIntArrayElements(result_, result, JNI_COMMIT_AND_RELEASE);
    env->ReleaseByteArrayElements(frameData_, frameData, JNI_ABORT);
}

JNIEXPORT void JNICALL
Java_io_prover_provermvp_detector_ProverDetector_releaseNativeHandler(JNIEnv *env, jobject instance,
                                                                      jlong nativeHandler) {

    SwypeDetect *detector = (SwypeDetect *) nativeHandler;
    if (detector == NULL) {
        LOGE_NATIVE("trying to close NULL detector");
    } else {
        LOGE_NATIVE("requested detector close");
        delete detector;
        LOGE_NATIVE("detector closed");
    }
}

}