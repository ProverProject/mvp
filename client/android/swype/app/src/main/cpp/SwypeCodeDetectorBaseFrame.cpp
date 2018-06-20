//
// Created by babay on 06.01.2018.
//

#include "SwypeCodeDetectorBaseFrame.h"
#include "VectorExplained.h"
#include "swype_detect.h"
#include "SwypeCodeDetector.h"


void SwypeCodeDetectorBaseFrame::NextFrame(cv::Mat &frame, uint timestamp) {
    if (timestamp >= _startTimestamp) {
        if (baseFt.empty()) {
            _status = 0;
            SetBaseFrame(frame);
            return;
        }

        VectorExplained shift = ShiftToBaseFrame(frame, timestamp);
        if (shift._timestamp > _maxTimestamp) {
            _status = -2;
        } else if (shift._mod <= 0) {
            _status = 0;
        } else {
            _stepDetector.Set(shift);
            _status = _stepDetector.CheckState(_relaxed);
            if (_status == 1) {
                if (++_currentStep >= _code._length) {
                    _stepDetector.FinishStep();
                } else {
                    _stepDetector.AdvanceDirection(_code._directions[_currentStep]);
                    _status = 0;
                    SetBaseFrame(frame);
                }
            }
        }
    }
}

VectorExplained SwypeCodeDetectorBaseFrame::ShiftToBaseFrame(cv::Mat &frame_i, uint timestamp) {
    frame_i.convertTo(curFrameFt, CV_64F);// converting frames to CV_64F type

    if (hann.empty()) {
        createHanningWindow(hann, curFrameFt.size(), CV_64F);
    }

    const cv::Point2d &shift = phaseCorrelate(baseFt, curFrameFt,
                                              hann); // we calculate a phase offset vector
    VectorExplained scaledShift;
    scaledShift.SetMul(shift, _shiftScaleXMult, _shiftScaleYMult);
    scaledShift.setRelativeDefect(_defect);
    scaledShift._timestamp = timestamp;

    log2(timestamp, shift, scaledShift);

    return scaledShift;
}

void SwypeCodeDetectorBaseFrame::SetBaseFrame(cv::Mat &frame_i) {
    frame_i.convertTo(baseFt, CV_64F);// converting frames to CV_64F type
    if (hann.empty()) {
        createHanningWindow(hann, baseFt.size(), CV_64F);
    }
}
