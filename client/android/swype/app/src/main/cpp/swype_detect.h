// @author Viacheslav Voronin
//
// I. Swype-code domain definition
//
// Swype-code is defined in the domain of 9 virtual points placed in 3x3 grid.
// Points are numbered from 1 to 9 starting from the top left corner (point 1)
// from left to right, then from top downward.
//
// II. Use cases
//
// 1. Approval of video file being captured. In this case we don't know
//    swype-code to be entered. The algorithm just should detect circular
//    motion "okey, prover" and notify about it. Only after that the swype-code
//    will be provided, and the algorithm should start to detect it.
// 2. Verification of swype-code presence in a given file. In this case a
//    swype-code is known and the goal is to find the code in the video stream.
//    The algorithm should detect circular motion "okey, prover" and then
//    search for the code within some predefined amount of time depending on
//    the code length (for example, 2 seconds for each code digit).
//
// It's suggested to implement both use cases in the single algorithm.
//
// III. General information
//
// Input: sequence of video frames (parameters? minimum possible resolution?
// color space etc...) with FPS no less than N (what's the minimum?)
//
// The algorithm behaves like a state machine, state transitions happen after
// processing a successive video frame. The following states are suggested
// (a state may have an associated parameter or set of parameters - given in
// brackets):
// * S0 (no): awaiting for circular motion "okey, prover";
// * S1 (no): circular motion is detected, the algorithm awaits for setting
//   a swype-code (this state is available for the first use-case only, when
//   the swype-code was not set yet; transition to S2 occurs after setting
//   a swype-code);
// * S2 (no): circular motion is detected, we have a swype-code and we are
//   waiting for some time: user should stabilize camera before entering swype-code
// * S3 (index of a last recognized symbol in the code, coordinates of the
//   current point of the image for trajectory visualization): entering
//   a swype-code is in progess.
// * S4 (no): swype-code entering is finished.
//
// IV. Algorithm description
//
// Initialization. The following parameters are provided: frame resolution,
// fps, swype-code (optional).
//
// Algorithm workflow:
// * Start from state S0. Right after recognition of circular motion transit to
//   one of the state:
//   - S1, if the swype-code was not specified at initialization. Immediately
//     after setting a swype-code (separate function that may be called
//     asynchronously) the algorithm transits into state S2 after receiving
//     a successive video frame.
//   - S2 (0), if the swype-code was given at initialization.
// * start to recognize a trajectory, return S2(i) and trajectory point
//   coordinates for visualization with every given video frame.
// * If the trajectory during the input fall into zone of another digit (not
//   the expected one), fall back to state S0. If swype-code was not set at
//   initialization, it should be reset too.
// * If entering a swype-code is not finished within 2*N seconds interval
//   (N denotes number of characters in the swype-code), fall back to state S0
//   and reset the swype-code provided it wasn't set at initialization. Time
//   calculation shall use FPS specified at initialization.
// * If entering a swype-code is finished, transit to state S3.
//
// V. Expected API
//
// /** @brief Initialization
//  *  @param width video frame width (pixels)
//  *  @param height video frame height (pixels)
//  *  @param fps frames per second
//  *  @param swype optional swype-code
//  */
// void init(
//    int         width,
//    int         height,
//    int         fps,
//    std::string swype="");
//
// /** @brief Set swype-code. Only for the case when the swype-code was not set
//  *         via init()
//  *  @param swype swype-code
//  */
// void setSwype(std::string swype);
//
// /** @brief Process single video frame
//  *  @param frame buffer with video frame data
//  *  @param state [out] state S
//  *  @param index [out] only for state==2, index of recognized digit of the
//  *         swype-code
//  *  @param x, y [out] only for state==2, trajectory coordinates for
//  *         visualization
//  */
// void processFrame(
//    const char *frame,
//    int        &state,
//    int        &index,
//    int        &x,
//    int        &y);
//
//
//
// /**
//  * @param frame_i frame data, only Luminance channel
//  * @param width_i frame width
//  * @param height_i frame height
//  * @param timestamp timestamp of frame relative to video start
//  * @param state [out] state S
//  * @param index [out] only for state==2, index of recognized digit of the
//  *         swype-code
//  * @param x, y [out] only for state==2, trajectory coordinates for
//  *         visualization
//  * @param debug - some debug data
//  */
//  void processFrame(
//     const unsigned char *frame_i,
//     int width_i,
//     int height_i,
//     uint timestamp,
//     int &state,
//     int &index,
//     int &x,
//     int &y,
//     int &debug);




#pragma once

#include <opencv2/opencv.hpp>
#include <cmath>
#include <ctime>
#include <cstdlib>
#include <cstring>
#include "opencv2/core/ocl.hpp"
#include "VectorExplained.h"
#include "SwypeStepDetector.h"
#include "CircleDetector.h"
#include "SwypeCodeDetectorBaseFrame.h"
#include "DetectorState.h"
#include "ColoredQuantum.h"
#include "ShiftDetector.h"
#include "SwypeCodeDetectorDelta.h"


class SwypeDetect {
public:

    SwypeDetect();

    ~SwypeDetect();

    /**
     *
     * @param sourceAspectRatio - aspect ratio (width / height) of original video
     * @param detectorWidth - detector frame width, px
     * @param detectorHeight - detector frame height, px
     */
    void init(double sourceAspectRatio, int detectorWidth, int detectorHeight);

    /**
     * set swype code
     * @param swype
     */
    void setSwype(std::string swype);

    /**
     *
     * @param frame_i
     * @param width_i
     * @param height_i
     * @param timestamp
     * @param state
     * @param index
     * @param x
     * @param y
     * @param debug
     */
    void processFrame(const unsigned char *frame_i, int width_i, int height_i,
                      uint timestamp, int &state, int &index, int &x, int &y,
                      int &debug);

    void setRelaxed(bool relaxed);

    uint32_t *getRgbBuffer(int width, int height) {
        return _colorQuantum.getRgbBuffer(width, height);
    };

    // frame - pointer to a buffer with a frame
    // state - state S
    // index - if state==3, the index  of the last entered swype number
    // x - if state==3, the X coordinate for visualisation
    // y - if state==3, the Y coordinate for visualisation
    void
    processFrameArgb(uint32_t *argb, int width, int height, uint timestamp, int &outState,
                     int &index,
                     int &x, int &y, int &debug);

private:

    void MoveToState(int state, uint timestamp);

    void AddDetector(unsigned int timestamp, cv::Mat &baseFrame);

    void DetectCircle(cv::Mat &frame_i, uint timestamp);

    SwipeCode swypeCode;//we have swype code or we will wait swype code

    int S; //state S

    DetectorState _state;

    ShiftDetector _shiftDetector;

    CircleDetector _circleDetector;

    bool _relaxed;

#ifdef USE_PER_FRAME_SHIFT
    std::list<SwypeCodeDetectorDelta> _detectors;
#else
    std::list<SwypeCodeDetectorBaseFrame> _detectors;
#endif

    SwypeCodeDetectorBaseFrame _detector;

    unsigned int _maxDetectors = 1;

    unsigned int _lastDetectorAdded = 0;

    ColoredQuantum _colorQuantum = ColoredQuantum(0xAA, 0xFF, 0x55);
};