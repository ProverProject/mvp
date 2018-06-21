#include "swype_detect.h"
#include "common.h"
#include "SwypeCodeDetector.h"

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
    _shiftDetector.SetDetectorSize(detectorWidth, detectorHeight, sourceAspectRatio);
    setRelaxed(true);
}

void SwypeDetect::setRelaxed(bool relaxed) {
    _shiftDetector.SetRelativeDefect(relaxed ? DEFECT : DEFECT_CLIENT);
    _circleDetector.SetRelaxed(relaxed);
    _relaxed = relaxed;
    _maxDetectors = relaxed ? 32 : 1;
}

void SwypeDetect::setSwype(string swype) {
    swypeCode.Init(swype);
}

void SwypeDetect::processFrame(const unsigned char *frame_i, int width_i, int height_i,
                               uint timestamp, int &state, int &index, int &x, int &y,
                               int &debug) {
    if (S == 4) {
        x = 0;
        y = 0;
        state = S;
        return;
    }

    Mat frame(height_i, width_i, CV_8UC1, (uchar *) frame_i);
    _shiftDetector.UpdateDetectorSize(width_i, height_i);

    index = 1;
    bool filledResponce = false;

    if (_detectors.size() < _maxDetectors) {
        DetectCircle(frame, timestamp);
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

void
SwypeDetect::processFrameArgb(uint32_t *argb, int width, int height, uint timestamp, int &outState,
                              int &index, int &x, int &y, int &debug) {
    unsigned char *frame = (unsigned char *) argb;
    _colorQuantum.coloredQuantumToSingleByte(argb, frame, width, height);
    processFrame(frame, width, height, timestamp, outState, index, x, y, debug);
}

void SwypeDetect::MoveToState(int state, uint timestamp) {
    S = state;
    LOGI_NATIVE("MoveToState %d", S);
}

void SwypeDetect::AddDetector(unsigned int timestamp, cv::Mat &baseFrame) {
    if (_detectors.size() < _maxDetectors) {
        if (timestamp == 0 || timestamp >= _lastDetectorAdded + MIN_TIME_BETWEEN_DETECTORS) {
            _detectors.emplace_back(swypeCode, SWYPE_SPEED, TARGET_RADIUS, _relaxed, timestamp,
                                    _shiftDetector, baseFrame);
            _lastDetectorAdded = timestamp;
            LOGI_NATIVE("Detector added %d, t %d", _detectors.back()._id, timestamp);
        }
    }
    LOGI_NATIVE("Detectors: %d, t %d", (int) _detectors.size(), timestamp);
}

void SwypeDetect::DetectCircle(cv::Mat &frame, uint timestamp) {

    if (_detectors.size() < _maxDetectors) {
        VectorExplained windowedShift = _shiftDetector.ShiftToPrevFrame(frame, timestamp);
        if (S == 1) {
            if (!swypeCode.empty()) {
                AddDetector(timestamp, frame);
            }
        } else if (windowedShift._mod > 0) {
            _circleDetector.AddShift(windowedShift);
            if (_circleDetector.IsCircle()) {
                if (swypeCode.empty()) {
                    MoveToState(1, timestamp);
                } else {
                    AddDetector(timestamp, frame);
                    if (_detectors.size() >= _maxDetectors) {
                        _circleDetector.Clear();
                    }
                }
            }
        }
    }

}
