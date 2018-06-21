//
// Created by babay on 21.06.2018.
//

#include "ShiftDetector.h"
#include "common.h"
#include "settings.h"

ShiftDetector::ShiftDetector(const ShiftDetector &source) :
        _videoAspect(source._videoAspect), _detectorWidth(source._detectorWidth),
        _detecttorHeight(source._detecttorHeight), _xMult(source._xMult), _yMult(source._yMult),
        _relativeDefect(source._relativeDefect) {
}


void
ShiftDetector::SetDetectorSize(int detectorWidth, int detectorHeight, double sourceAspectRatio) {
    _detectorWidth = detectorWidth;
    _detecttorHeight = detectorHeight;
    _videoAspect = sourceAspectRatio > 1 ? sourceAspectRatio : 1.0 / sourceAspectRatio;
    if (detectorWidth > detectorHeight) {
        _yMult = -2.0 / detectorHeight;
        _xMult = -2.0 / detectorWidth * _videoAspect;
    } else {
        _xMult = -2.0 / detectorWidth;
        _yMult = -2.0 / detectorHeight * _videoAspect;
    }

    if (logLevel > 0) {
        LOGI_NATIVE("SetDetectorSize (%d, %d) sourceAspect %f, -> (%f, %f)", detectorWidth,
                    detectorHeight, _videoAspect, _xMult, _yMult);
    }
}

VectorExplained ShiftDetector::ShiftToPrevFrame(cv::Mat &frame_i, uint timestamp) {
    if (_tickFrame.empty()) {
        frame_i.convertTo(_tickFrame, CV_64F);// converting frames to CV_64F type
        createHanningWindow(_hann, _tickFrame.size(), CV_64F); //  create Hanning window
        _tickTock = false;
        return VectorExplained();
    }

    cv::Point2d shift;

    _tickTock = !_tickTock;
    if (_tickTock) {
        frame_i.convertTo(_tockFrame, CV_64F);// converting frames to CV_64F type
        shift = phaseCorrelate(_tickFrame, _tockFrame, _hann); // we calculate a phase offset vector
    } else {
        frame_i.convertTo(_tickFrame, CV_64F);// converting frames to CV_64F type
        shift = phaseCorrelate(_tockFrame, _tickFrame, _hann); // we calculate a phase offset vector
    }
    VectorExplained scaledShift;
    scaledShift.SetMul(shift, _xMult, _yMult);
    VectorExplained windowedShift = scaledShift;
    windowedShift.ApplyWindow(VECTOR_WINDOW_START, VECTOR_WINDOW_END);
    windowedShift.setRelativeDefect(_relativeDefect);
    windowedShift._timestamp = timestamp;

    if (logLevel & LOG_VECTORS) {
        log1(timestamp, shift, scaledShift, windowedShift);
    }

    return windowedShift;
}

void ShiftDetector::SetBaseFrame(const cv::Mat &frame) {
    frame.convertTo(_tickFrame, CV_64F);// converting frames to CV_64F type
    if (_hann.empty()) {
        createHanningWindow(_hann, _tickFrame.size(), CV_64F);
    }
    _tickTock = false;
}

VectorExplained ShiftDetector::ShiftToBaseFrame(cv::Mat &frame, uint timestamp) {
    frame.convertTo(_tockFrame, CV_64F);// converting frames to CV_64F type

    if (_hann.empty()) {
        createHanningWindow(_hann, _tockFrame.size(), CV_64F);
    }

    const cv::Point2d &shift = phaseCorrelate(_tickFrame, _tockFrame,
                                              _hann); // we calculate a phase offset vector
    VectorExplained scaledShift;
    scaledShift.SetMul(shift, _xMult, _yMult);
    scaledShift.setRelativeDefect(_relativeDefect);
    scaledShift._timestamp = timestamp;

    if (logLevel & LOG_VECTORS) {
        log2(timestamp, shift, scaledShift);
    }

    return scaledShift;
}


void ShiftDetector::log1(uint timestamp, cv::Point2d &shift, VectorExplained &scaledShift,
                         VectorExplained &windowedShift) {
    if (logLevel > 0 && windowedShift._mod > 0) {
        LOGI_NATIVE(
                "t%d shift (%+6.2f,%+6.2f), scaled |%+.4f,%+.4f|=%.4f windowed |%+.4f,%+.4f|=%.4f_%3.0f_%d",
                timestamp, shift.x, shift.y,
                scaledShift._x, scaledShift._y, scaledShift._mod,
                windowedShift._x, windowedShift._y, windowedShift._mod, windowedShift._angle,
                windowedShift._direction);
    }
}

void ShiftDetector::log2(uint timestamp, const cv::Point2d &shift, VectorExplained &scaledShift) {
    if (logLevel > 0 && scaledShift._mod > 0) {
        LOGI_NATIVE(
                "t%d shift (%+6.2f,%+6.2f), scaled |%+.4f,%+.4f|=%.4f_%3.0f_%d",
                timestamp, shift.x, shift.y,

                scaledShift._x, scaledShift._y, scaledShift._mod, scaledShift._angle,
                scaledShift._direction);
    }
}

void ShiftDetector::SetRelativeDefect(double defect) {
    _relativeDefect = defect;
}



