#include "swype_detect.h"
#include "common.h"

using namespace cv;
using namespace std;

int logLevel = 0;

SwypeDetect::SwypeDetect() // initialization
{
    ocl::setUseOpenCL(true);
    S = 0;
}

SwypeDetect::~SwypeDetect() {
    ocl::setUseOpenCL(false);
}

void SwypeDetect::init(double sourceAspectRatio, int detectorWidth, int detectorHeight) {
    _videoAspect = sourceAspectRatio > 1 ? sourceAspectRatio : 1.0 / sourceAspectRatio;
    SetDetectorSize(detectorWidth, detectorHeight);
    setRelaxed(true);
}

void SwypeDetect::SetDetectorSize(int detectorWidth, int detectorHeight) {
    _detectorWidth = detectorWidth;
    _detecttorHeight = detectorHeight;
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

void SwypeDetect::setSwype(string swype) {
    swypeCode.Init(swype);
}

VectorExplained SwypeDetect::ShiftToPrevFrame2(cv::Mat &frame_i, uint timestamp) {
    if (buf1ft.empty()) {
        frame_i.convertTo(buf1ft, CV_64F);// converting frames to CV_64F type
        createHanningWindow(hann, buf1ft.size(), CV_64F); //  create Hanning window
        _tickTock = false;
        return VectorExplained();
    }

    Point2d shift;

    _tickTock = !_tickTock;
    if (_tickTock) {
        frame_i.convertTo(buf2ft, CV_64F);// converting frames to CV_64F type
        shift = phaseCorrelate(buf1ft, buf2ft, hann); // we calculate a phase offset vector
    } else {
        frame_i.convertTo(buf1ft, CV_64F);// converting frames to CV_64F type
        shift = phaseCorrelate(buf2ft, buf1ft, hann); // we calculate a phase offset vector
    }
    VectorExplained scaledShift;
    scaledShift.SetMul(shift, _xMult, _yMult);
    VectorExplained windowedShift = scaledShift;
    windowedShift.ApplyWindow(VECTOR_WINDOW_START, VECTOR_WINDOW_END);
    windowedShift.setRelativeDefect(_relaxed ? DEFECT : DEFECT_CLIENT);
    windowedShift._timestamp = timestamp;

    if (logLevel & LOG_CIRCLE_DETECTION) {
        log1(timestamp, shift, scaledShift, windowedShift);
    }

    return windowedShift;
}

void SwypeDetect::SetBaseFrame(cv::Mat &frame_i) {
    frame_i.convertTo(baseFt, CV_64F);// converting frames to CV_64F type
    if (hann.empty()) {
        createHanningWindow(hann, baseFt.size(), CV_64F);
    }
}

void SwypeDetect::log1(uint timestamp, cv::Point2d &shift, VectorExplained &scaledShift,
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

void
SwypeDetect::processFrame3(const unsigned char *frame_i, int width_i, int height_i, uint timestamp,
                           int &outState, int &index, int &x, int &y, int &debug) {
    Mat frame(height_i, width_i, CV_8UC1, (uchar *) frame_i);

    if (_detectorWidth != width_i || _detecttorHeight != height_i) {
        SetDetectorSize(_detectorWidth, _detecttorHeight);
    }

    bool filledResponce = false;

    switch (_state.Status()) {
        case DetectorState::WaitingForCircle: {
            VectorExplained windowedShift = ShiftToPrevFrame2(frame, timestamp);
            _circleDetector.AddShift(windowedShift);
            if (_circleDetector.IsCircle()) {
                _state.GotCircle(timestamp, swypeCode);
            }
        }
            break;

        case DetectorState::GotCircleWaitingForSwype:
            if (!swypeCode.empty()) {
                _state.GotCircle(timestamp, swypeCode);
            }
            break;

        case DetectorState::WaitingToStartSwypeCode:
            if (_state.IsStateOutdated(timestamp)) {
                _state.StartDetection(timestamp, swypeCode);
                SetBaseFrame(frame);
                _detector.Init(swypeCode, SWYPE_SPEED, TARGET_RADIUS, _relaxed, timestamp,
                               false, _xMult, _yMult);
                _detector.SetBaseFrame(frame);
            }
            break;

        case DetectorState::DetectingSwypeCode: {
            _detector.NextFrame(frame, timestamp);

            if (_detector._status < 0) {
                _state.Restart(timestamp);
            } else if (_detector._status == 1) {
                _state.Finish(timestamp);
            }
            _detector.FillResult(outState, index, x, y, debug);
            filledResponce = true;
        }
            break;

        case DetectorState::SwypeCodeDone:
            break;
    }

    if (!filledResponce) {
        x = 0;
        y = 0;
        outState = _state.Status();
    }
}

void SwypeDetect::processFrame(const unsigned char *frame_i, int width_i, int height_i,
                               uint timestamp, int &state, int &index, int &x, int &y,
                               int &debug) {
    Mat frame(height_i, width_i, CV_8UC1, (uchar *) frame_i);

    if (_detectorWidth != width_i || _detecttorHeight != height_i) {
        SetDetectorSize(_detectorWidth, _detecttorHeight);
    }
    if (S == 4) {
        x = 0;
        y = 0;
        state = S;
        return;
    }

    index = 1;
    bool filledResponce = false;

    if (_detectors.size() < _maxDetectors) {
        VectorExplained windowedShift = ShiftToPrevFrame2(frame, timestamp);
        if (S == 1) {
            if (!swypeCode.empty()) {
                AddDetector(timestamp, frame, _relaxed ? DEFECT : DEFECT_CLIENT);
            }
        } else if (windowedShift._mod > 0) {
            _circleDetector.AddShift(windowedShift);
            if (_circleDetector.IsCircle()) {
                if (swypeCode.empty()) {
                    MoveToState(1, timestamp);
                } else {
                    AddDetector(timestamp, frame, 0);
                }
            }
        }

    }

    if (_detectors.size() > 0) {
        for (auto it = _detectors.begin(); it != _detectors.end();) {
            it->NextFrame(frame, timestamp);
            if (it->_status < 0) {
                if (_maxDetectors == 1) {
                    it->FillResult(state, index, x, y, debug);
                    filledResponce = true;
                }
                it = _detectors.erase(it);
            } else {
                if (it->_status == 1) {
                    S = 4;
                }
                ++it;
            }
        }
    } else {
        state = S;
    }

    if (!filledResponce) {
        if (S == 4) {
            if (_detectors.size() > 0)
                _detectors.front().FillResult(S, index, x, y, debug);
            state = S;
        } else if (_detectors.size() == 0) {
            x = 0;
            y = 0;
            state = S;
        } else {
            _detectors.front().FillResult(state, index, x, y, debug);
        }
    }
}

void SwypeDetect::MoveToState(int state, uint timestamp) {
    S = state;
    LOGI_NATIVE("MoveToState %d", S);
}

void SwypeDetect::setRelaxed(bool relaxed) {
    _circleDetector.SetRelaxed(relaxed);
    _relaxed = relaxed;
    _maxDetectors = relaxed ? 32 : 1;
}

void SwypeDetect::AddDetector(unsigned int timestamp, cv::Mat &baseFrame, double defect) {
    if (_detectors.size() < _maxDetectors) {
        if (timestamp == 0 || timestamp >= _lastDetectorAdded + MIN_TIME_BETWEEN_DETECTORS) {
            _detectors.emplace_back(swypeCode, _xMult, _yMult, SWYPE_SPEED, TARGET_RADIUS,
                                    _relaxed, defect, timestamp);
            _lastDetectorAdded = timestamp;
            LOGI_NATIVE("Detector added %d, t %d", _detectors.back()._id, timestamp);
        }
    }
    LOGI_NATIVE("Detectors: %d, t %d", (int) _detectors.size(), timestamp);
}
