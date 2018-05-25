//
// Created by babay on 06.01.2018.
//

#include "SwypeCodeDetector.h"
#include "VectorExplained.h"
#include "swype_detect.h"

unsigned int SwypeCodeDetector::counter = 0;

SwypeCodeDetector::SwypeCodeDetector(SwipeCode &code, double shiftScaleXMult,
                                     double shiftScaleYMult,
                                     double speedMult, float maxDeviation, bool relaxed,
                                     unsigned int timestamp)
        : _code(code),
          _relaxed(relaxed),
          _id(++counter),
          _stepDetector(_id),
          _shiftScaleXMult(shiftScaleXMult),
          _shiftScaleYMult(shiftScaleYMult) {
    _stepDetector.Configure(speedMult, maxDeviation, _relaxed);
    _stepDetector.SetDirection(_code._directions[0]);
    _startTimestamp = timestamp + PAUSE_TO_ST3_MS_PER_STEP * (_code._length - 1);
    _maxTimestamp = _startTimestamp + MS_PER_SWIPE_STEP * _code._length;
}

void SwypeCodeDetector::Init(SwipeCode &code, double speedMult, float maxDeviation, bool relaxed,
                             unsigned int timestamp,
                             bool delayStart, double shiftScaleXMult, double shiftScaleYMult) {
    _code = code;
    _relaxed = relaxed;
    _stepDetector.Configure(speedMult, maxDeviation, relaxed);
    _stepDetector.SetDirection(_code._directions[0]);
    _currentStep = 0;
    _shiftScaleXMult = shiftScaleXMult;
    _shiftScaleYMult = shiftScaleYMult;
    _status = 2;
    if (delayStart) {
        _startTimestamp = timestamp + PAUSE_TO_ST3_MS_PER_STEP * (_code._length - 1);
    } else {
        _startTimestamp = timestamp;
    }
    _maxTimestamp = _startTimestamp + MS_PER_SWIPE_STEP * _code._length;
}

void SwypeCodeDetector::NextFrame(cv::Mat &frame, uint timestamp) {
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

void SwypeCodeDetector::FillResult(int &status, int &index, int &x, int &y, int &debug) {
    index = _currentStep + 1;
    x = (int) (_stepDetector._current._x * 1024);
    y = (int) (_stepDetector._current._y * 1024);

    debug = (int) (_stepDetector._current._defectX * 1024);
    debug = debug << 16;
    debug += _stepDetector._current._defectY * 1024;

    if (_status < 0)
        status = 0;
    else if (_status == 2)
        status = 2;
    else if (_status == 1)
        status = 4;
    else
        status = 3;
}

VectorExplained SwypeCodeDetector::ShiftToBaseFrame(cv::Mat &frame_i, uint timestamp) {
    frame_i.convertTo(curFrameFt, CV_64F);// converting frames to CV_64F type

    if (hann.empty()) {
        createHanningWindow(hann, curFrameFt.size(), CV_64F);
    }

    const cv::Point2d &shift = phaseCorrelate(baseFt, curFrameFt,
                                              hann); // we calculate a phase offset vector
    VectorExplained scaledShift;
    scaledShift.SetMul(shift, _shiftScaleXMult, _shiftScaleYMult);
    scaledShift.setRelativeDefect(_relaxed ? DEFECT : DEFECT_CLIENT);
    scaledShift._timestamp = timestamp;

    log2(timestamp, shift, scaledShift);

    return scaledShift;
}

void SwypeCodeDetector::SetBaseFrame(cv::Mat &frame_i) {
    frame_i.convertTo(baseFt, CV_64F);// converting frames to CV_64F type
    if (hann.empty()) {
        createHanningWindow(hann, baseFt.size(), CV_64F);
    }
}

void
SwypeCodeDetector::log2(uint timestamp, const cv::Point2d &shift, VectorExplained &scaledShift) {

    if (logLevel > 0 && scaledShift._mod > 0) {
        LOGI_NATIVE(
                "t%d shift (%+6.2f,%+6.2f), scaled |%+.4f,%+.4f|=%.4f_%3.0f_%d",
                timestamp, shift.x, shift.y,

                scaledShift._x, scaledShift._y, scaledShift._mod, scaledShift._angle,
                scaledShift._direction);
    }
}