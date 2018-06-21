//
// Created by babay on 06.01.2018.
//

#include "SwypeCodeDetectorBaseFrame.h"
#include "VectorExplained.h"
#include "swype_detect.h"
#include "SwypeCodeDetector.h"

void SwypeCodeDetectorBaseFrame::NextFrame(cv::Mat &frame, uint timestamp) {
    if (timestamp >= _startTimestamp) {
        if (_shiftDetector.IsBaseFrameEmpty()) {
            _status = 0;
            _shiftDetector.SetBaseFrame(frame);
        }

        VectorExplained shift = _shiftDetector.ShiftToBaseFrame(frame, timestamp);
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

void SwypeCodeDetectorBaseFrame::SetBaseFrame(cv::Mat &frame_i) {
    _shiftDetector.SetBaseFrame(frame_i);
}
