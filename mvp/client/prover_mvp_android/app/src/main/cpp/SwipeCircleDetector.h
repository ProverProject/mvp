//
// Created by babay on 08.12.2017.
//

#ifndef PROVER_MVP_ANDROID_SWIPECIRCLEDETECTOR_H
#define PROVER_MVP_ANDROID_SWIPECIRCLEDETECTOR_H


#include "VectorExplained.h"

#define SHIFTS 64

#ifdef __ANDROID_API__

#define MIN_CIRCLE_AREA 2000
#define MAX_DEVIATION 10
#define MAX_CIRCLE_DURATION_MS 2500
#define MIN_AREA_BY_P2_TO_CIRCLE 0.67

#else

#define MIN_CIRCLE_AREA 1800
#define MAX_DEVIATION 14
#define MAX_CIRCLE_DURATION_MS 2600
#define MIN_AREA_BY_P2_TO_CIRCLE 0.6

#endif

class SwipeCircleDetector {
public:
    void AddShift(VectorExplained shift);

    bool IsCircle();

    void Reset() {
        pos_ = 0;
        total_ = 0;
    }

    const double Circle_S_by_P2 = (const double) (0.25f / CV_PI);

private:
    double Area(int amount, double &perimeter);

    VectorExplained shifts_[SHIFTS];
    int pos_ = 0;
    int total_ = 0;
};


#endif //PROVER_MVP_ANDROID_SWIPECIRCLEDETECTOR_H
