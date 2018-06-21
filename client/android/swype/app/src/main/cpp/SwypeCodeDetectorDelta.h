//
// Created by babay on 21.06.2018.
//

#ifndef SWYPE_SWYPECODEDETECTORDELTA_H
#define SWYPE_SWYPECODEDETECTORDELTA_H


#include <opencv2/core/mat.hpp>
#include "ShiftDetector.h"
#include "SwypeCodeDetector.h"

class SwypeCodeDetectorDelta : public SwypeCodeDetector {
public:
    SwypeCodeDetectorDelta(SwipeCode &code, double speedMult, float targetRadius, bool relaxed,
                           unsigned int timestamp, const ShiftDetector &shiftDetectorSettings,
                           cv::Mat &baseFrame) : SwypeCodeDetector(code, speedMult, targetRadius,
                                                                   relaxed, timestamp),
                                                 _shiftDetector(shiftDetectorSettings) {
        _shiftDetector.SetBaseFrame(baseFrame);
    };

    void NextFrame(cv::Mat &frame_i, uint timestamp) override;

private:
    ShiftDetector _shiftDetector;
};


#endif //SWYPE_SWYPECODEDETECTORDELTA_H
