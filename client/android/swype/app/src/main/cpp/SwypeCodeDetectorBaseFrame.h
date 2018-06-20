//
// Created by babay on 06.01.2018.
//

#ifndef PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H
#define PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H


#include "SwypeStepDetector.h"
#include "SwipeCode.h"
#include "SwypeCodeDetector.h"

class SwypeCodeDetectorBaseFrame : public SwypeCodeDetector {
public:

    SwypeCodeDetectorBaseFrame() : SwypeCodeDetector() {}

    SwypeCodeDetectorBaseFrame(SwipeCode &code, double shiftScaleXMult,
                               double shiftScaleYMult, double speedMult,
                               float maxDeviation, bool relaxed, double defect,
                               unsigned int timestamp)
            : SwypeCodeDetector(code, shiftScaleXMult, shiftScaleYMult, speedMult, maxDeviation,
                                relaxed, defect, timestamp) {};

    void NextFrame(cv::Mat &frame_i, uint timestamp);

    void SetBaseFrame(cv::Mat &frame);


private:

    VectorExplained ShiftToBaseFrame(cv::Mat &frame_i, uint timestamp);

    cv::UMat curFrameFt;
    cv::UMat baseFt;
    cv::UMat hann;
};

#endif //PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H