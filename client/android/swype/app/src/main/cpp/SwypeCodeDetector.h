//
// Created by babay on 06.01.2018.
//

#ifndef PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H
#define PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H


#include "SwypeStepDetector.h"
#include "SwipeCode.h"

class SwypeCodeDetector {
public:
    SwypeCodeDetector() : _id(++counter), _stepDetector(_id) {};

    SwypeCodeDetector(SwipeCode &code, double shiftScaleXMult,
                          double shiftScaleYMult, double speedMult,
                          float maxDeviation, bool relaxed, double defect,
                          unsigned int timestamp);

    void Init(SwipeCode &code, double speedMult, float maxDeviation, bool relaxed,
              unsigned int timestamp,
              bool delayStart, double shiftScaleXMult, double shiftScaleYMult);

    void NextFrame(cv::Mat &frame_i, uint timestamp);

    void FillResult(int &status, int &index, int &x, int &y, int &debug);

    void SetBaseFrame(cv::Mat &frame);

    /*
     *    1 -- swype code completed
     *    0 -- processing swype code
     *    2 -- waiting to start swype code processing
     *   -1 -- swype code failed
     *   -2 -- swype input timeout
     */
    int _status = 2;

    unsigned int _id;

private:

    VectorExplained ShiftToBaseFrame(cv::Mat &frame_i, uint timestamp);


    void log2(uint timestamp, const cv::Point2d &shift, VectorExplained &scaledShift);

    SwipeCode _code;
    SwypeStepDetector _stepDetector;

    unsigned int _maxTimestamp = 0;

    unsigned int _currentStep = 0;

    bool _relaxed = true;

    unsigned int _startTimestamp = 0;

    static unsigned int counter;

    cv::UMat curFrameFt;
    cv::UMat baseFt;
    cv::UMat hann;

    double _shiftScaleXMult = 0.0;
    double _shiftScaleYMult = 0.0;

    double _defect;
};

#endif //PROVER_MVP_ANDROID_SWYPECODEDETECTOR_H