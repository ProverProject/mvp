//
// Created by babay on 21.06.2018.
//

#ifndef SWYPE_SHIFTDETECTOR_H
#define SWYPE_SHIFTDETECTOR_H


#include <opencv2/core/mat.hpp>
#include "VectorExplained.h"

class ShiftDetector {
public:

    ShiftDetector() {};

    ShiftDetector(const ShiftDetector &source);

    void SetDetectorSize(int detectorWidth, int detectorHeight, double sourceAspectRatio);

    VectorExplained ShiftToPrevFrame(cv::Mat &frame_i, uint timestamp);

    VectorExplained ShiftToBaseFrame(cv::Mat &frame, uint timestamp);

    void SetBaseFrame(const cv::Mat &frame);

    inline void UpdateDetectorSize(int width, int height) {
        if (_detectorWidth != width || _detecttorHeight != height) {
            SetDetectorSize(width, height, _videoAspect);
        }
    }

    void SetRelativeDefect(double defect);

    bool IsBaseFrameEmpty() { return _tickFrame.empty(); };

private:
    void log1(uint timestamp, cv::Point2d &shift, VectorExplained &scaledShift,
              VectorExplained &windowedShift);

    void log2(uint timestamp, const cv::Point2d &shift, VectorExplained &scaledShift);

    cv::UMat _tickFrame;
    cv::UMat _tockFrame;
    cv::UMat _hann;
    bool _tickTock = false;

    double _videoAspect = 0.0;
    int _detectorWidth = 0;
    int _detecttorHeight = 0;
    double _xMult = 0.0;
    double _yMult = 0.0;

    double _relativeDefect;// relaxed ? DEFECT : DEFECT_CLIENT
};


#endif //SWYPE_SHIFTDETECTOR_H
