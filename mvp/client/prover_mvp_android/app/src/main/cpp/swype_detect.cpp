#include "swype_detect.h"
#include "common.h"

using namespace cv;
using namespace std;

int logLevel = 0;

SwypeDetect::SwypeDetect() // initialization
{
    ocl::setUseOpenCL(true);
    count_num = -1;
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
        LOGI_NATIVE("detect2 SetDetectorSize (%d, %d) sourceAspect %f, -> (%f, %f)", detectorWidth,
                    detectorHeight, _videoAspect, _xMult, _yMult);
    }
}

void SwypeDetect::setSwype(string swype) {
    char t;
    int j;
    swype_Numbers.clear();
    swype_Numbers.resize(0);
    if (swype != "") {
        for (int i = 0; i < swype.length(); i++) {
            t = swype.at(i);
            j = t - '0';
            swype_Numbers.push_back(j);
        }
        count_num = 0;
    }
}

Point2d SwypeDetect::Frame_processor(cv::Mat &frame_i) {
    if (buf1ft.empty()) {
        frame_i.convertTo(buf1ft, CV_64F);// converting frames to CV_64F type
        createHanningWindow(hann, buf1ft.size(), CV_64F); //  create Hanning window
        _tickTock = false;
        return Point2d(0, 0);
    }

    _tickTock = !_tickTock;
    if (_tickTock) {
        frame_i.convertTo(buf2ft, CV_64F);// converting frames to CV_64F type
        return phaseCorrelate(buf1ft, buf2ft, hann); // we calculate a phase offset vector
    } else {
        frame_i.convertTo(buf1ft, CV_64F);// converting frames to CV_64F type
        return phaseCorrelate(buf2ft, buf1ft, hann); // we calculate a phase offset vector
    }
}

void SwypeDetect::processFrame_new(const unsigned char *frame_i, int width_i, int height_i,
                                   uint timestamp, int &state, int &index, int &x, int &y,
                                   int &debug) {
    Mat frame(height_i, width_i, CV_8UC1, (uchar *) frame_i);
    Point2d shift = Frame_processor(frame);

    if (_detectorWidth != width_i || _detecttorHeight != height_i) {
        SetDetectorSize(_detectorWidth, _detecttorHeight);
    }

    VectorExplained scaledShift;
    scaledShift.SetMul(shift, _xMult, _yMult);
    VectorExplained windowedShift = scaledShift;
    windowedShift.ApplyWindow(VECTOR_WINDOW_START, VECTOR_WINDOW_END);
    windowedShift._timestamp = timestamp;
    if (logLevel > 0 && windowedShift._mod >= 0) {
        LOGI_NATIVE(
                "detect2 t%d shift (%+6.2f,%+6.2f), scaled |%+.4f,%+.4f|=%.4f windowed |%+.4f,%+.4f|=%.4f",
                timestamp, shift.x, shift.y,
                scaledShift._x, scaledShift._y, scaledShift._mod,
                windowedShift._x, windowedShift._y, windowedShift._mod);
    }

    if (S == 0) {
        if (windowedShift._mod > 0) {
            _circleDetector.AddShift(windowedShift);
            if (_circleDetector.IsCircle()) {
                _circleDetector.Reset();
                if (swype_Numbers.empty()) {
                    MoveToState(1, timestamp, 0);
                } else {
                    MoveToState(2, timestamp,
                                (uint) (PAUSE_TO_STATE_3_MS_PER_STEP * swype_Numbers.size()));
                }
            }
        }
        x = (int) (windowedShift._x * 1024);
        y = (int) (windowedShift._y * 1024);
    } else if (S == 1) {
        if (!swype_Numbers.empty()) {
            MoveToState(2, timestamp, (uint) (PAUSE_TO_STATE_3_MS_PER_STEP * swype_Numbers.size()));
        }
    } else if (S == 2) {
        if (timestamp >= _maxStateEndTime) {
            _swipeStepDetector.Configure(1.5, _maxDetectorDeviation, 4);
            _swipeStepDetector.SetSwipeStep(swype_Numbers[0], swype_Numbers[1]);
            count_num = 0;
            MoveToState(3, timestamp, TIME_PER_EACH_SWIPE_STEP * (uint) (swype_Numbers.size()));
        }
    } else if (S == 3) {
        if (timestamp > _maxStateEndTime) {
            MoveToState(0, timestamp, 0);
        } else if (windowedShift._mod > 0) {
            _swipeStepDetector.Add(windowedShift);
            int status = _swipeStepDetector.CheckState();
            if (status == 0) {}
            else if (status == 1) {
                ++count_num;
                if (swype_Numbers.size() == (count_num + 1)) {
                    MoveToState(4, timestamp, 0);
                    _swipeStepDetector.FinishStep();
                } else {
                    _swipeStepDetector.AdvanceSwipeStep(swype_Numbers[count_num + 1]);
                }
            } else if (status == -1) {
                MoveToState(0, timestamp, 0);
                count_num = 0;
            }
        }
        x = (int) (_swipeStepDetector._current._x * 1024);
        y = (int) (_swipeStepDetector._current._y * 1024);
    } else if (S == 4) {
        _swipeStepDetector.Add(windowedShift);
        x = (int) (_swipeStepDetector._current._x * 1024);
        y = (int) (_swipeStepDetector._current._y * 1024);
    }
    state = S;
    index = count_num + 1;
}

void SwypeDetect::MoveToState(int state, uint currentTimestamp, uint maxStateDuration) {
    S = state;
    _maxStateEndTime = maxStateDuration == 0 ? (uint) -1 : currentTimestamp + maxStateDuration;
}

void SwypeDetect::setRelaxed(bool relaxed) {
    _maxDetectorDeviation = relaxed ? MAX_DETECTOR_DEVIATION_RELAXED
                                    : MAX_DETECTOR_DEVIATION_STRICT;
    _circleDetector.setRelaxed(relaxed);
    _swipeStepDetector.setRelaxed(relaxed);
}
