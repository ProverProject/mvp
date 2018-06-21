//
// Created by babay on 20.06.2018.
//

#include "swype_detect.h"
#include "SwypeCodeDetectorBaseFrame.h"
#include "SwypeCodeDetector.h"


unsigned int SwypeCodeDetector::counter = 0;

void SwypeCodeDetector::FillResult(int &status, int &index, int &x, int &y, int &debug) {
    index = _currentStep + 1;
    x = (int) (_stepDetector._current._x * 1024);
    y = (int) (_stepDetector._current._y * 1024);

    debug = (int) (_stepDetector._current._defectX * 1024);
    debug = debug << 16;
    debug += _stepDetector._current._defectY * 1024;

    if (SwypeCodeDetector::_status < 0)
        status = 0;
    else if (SwypeCodeDetector::_status == 2)
        status = 2;
    else if (SwypeCodeDetector::_status == 1)
        status = 4;
    else
        status = 3;
}

SwypeCodeDetector::SwypeCodeDetector(SwipeCode &code, double speedMult, float targetRadius,
                                     bool relaxed,
                                     unsigned int timestamp)
        : _code(code),
          _relaxed(relaxed),
          _id(++counter),
          _stepDetector(_id) {
    _stepDetector.Configure(speedMult, targetRadius, _relaxed);
    _stepDetector.SetDirection(_code._directions[0]);
    _startTimestamp = timestamp + PAUSE_TO_ST3_MS_PER_STEP * (_code._length - 1);
    _maxTimestamp = _startTimestamp + MS_PER_SWIPE_STEP * _code._length;
}

void SwypeCodeDetector::Init(SwipeCode &code, double speedMult, float maxDeviation, bool relaxed,
                             unsigned int timestamp, bool delayStart) {
    _code = code;
    _relaxed = relaxed;
    _stepDetector.Configure(speedMult, maxDeviation, relaxed);
    _stepDetector.SetDirection(_code._directions[0]);
    _currentStep = 0;
    _status = 2;
    if (delayStart) {
        _startTimestamp = timestamp + PAUSE_TO_ST3_MS_PER_STEP * (_code._length - 1);
    } else {
        _startTimestamp = timestamp;
    }
    _maxTimestamp = _startTimestamp + MS_PER_SWIPE_STEP * _code._length;
}
