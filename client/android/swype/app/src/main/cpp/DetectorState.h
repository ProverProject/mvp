//
// Created by babay on 20.05.2018.
//

#ifndef PROVER_MVP_ANDROID_DETECTORSTATUS_H
#define PROVER_MVP_ANDROID_DETECTORSTATUS_H


#include <sys/types.h>
#include "SwipeCode.h"
#include "settings.h"

class DetectorState {
public:
    enum State {
        WaitingForCircle = 0,
        GotCircleWaitingForSwype = 1,
        WaitingToStartSwypeCode = 2,
        DetectingSwypeCode = 3,
        SwypeCodeDone = 4
    };

    inline State Status() {
        return _state;
    }

    inline void MoveToState(State state, uint timestamp, SwipeCode &code) {
        _state = state;
        _startTimestamp = timestamp;

        switch (state) {
            case State::WaitingToStartSwypeCode:
                _maxStateEndTime =
                        timestamp + (uint) (PAUSE_TO_ST3_MS_PER_STEP * (code._length - 2));
                break;

            case State::DetectingSwypeCode:
                _maxStateEndTime = timestamp + MS_PER_SWIPE_STEP * code._length;
                break;

            default:
                _maxStateEndTime = (uint) -1;
        }
    }

    inline void GotCircle(uint timestamp, SwipeCode &code) {
        _startTimestamp = timestamp;
        if (code.empty()) {
            _state = State::GotCircleWaitingForSwype;
            _maxStateEndTime = (uint) -1;
        } else {
            _state = State::WaitingToStartSwypeCode;
            _maxStateEndTime = timestamp + (uint) (PAUSE_TO_ST3_MS_PER_STEP * (code._length - 2));
        }
    }

    inline void Restart(uint timestamp) {
        _state = State::WaitingForCircle;
        _startTimestamp = timestamp;
        _maxStateEndTime = (uint) -1;
    }

    inline void Finish(uint timestamp) {
        _state = State::SwypeCodeDone;
        _startTimestamp = timestamp;
        _maxStateEndTime = (uint) -1;
    }

    inline void StartDetection(uint timestamp, SwipeCode &code) {
        _state = State::DetectingSwypeCode;
        _startTimestamp = timestamp;
        _maxStateEndTime = timestamp + MS_PER_SWIPE_STEP * code._length;
    }

    inline bool IsStateOutdated(uint timestamp) {
        return timestamp >= _maxStateEndTime;
    }

private:
    State _state = WaitingForCircle;
    uint _startTimestamp = 0;
    uint _maxStateEndTime = static_cast<uint>(-1);
};


#endif //PROVER_MVP_ANDROID_DETECTORSTATUS_H
