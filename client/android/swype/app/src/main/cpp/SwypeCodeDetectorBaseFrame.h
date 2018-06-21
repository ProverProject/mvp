//
// Created by babay on 06.01.2018.
//

#ifndef PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H
#define PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H


#include "SwypeStepDetector.h"
#include "SwipeCode.h"
#include "SwypeCodeDetector.h"
#include "ShiftDetector.h"

class SwypeCodeDetectorBaseFrame : public SwypeCodeDetector {
public:

    SwypeCodeDetectorBaseFrame() : SwypeCodeDetector() {}

    SwypeCodeDetectorBaseFrame(SwipeCode &code, double speedMult, float targetRadius, bool relaxed,
                               unsigned int timestamp, const ShiftDetector &shiftDetectorSettings,
                               cv::Mat &baseFrame)
            : SwypeCodeDetector(code, speedMult, targetRadius, relaxed, timestamp),
              _shiftDetector(shiftDetectorSettings) {
        SetBaseFrame(baseFrame);
    };

    void NextFrame(cv::Mat &frame_i, uint timestamp) override;

    void SetBaseFrame(cv::Mat &frame);

private:
    ShiftDetector _shiftDetector;
};

#endif //PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H