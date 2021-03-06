//
// Created by babay on 07.12.2017.
//

#ifndef PROVER_MVP_ANDROID_VECTOREXPLAINED_H
#define PROVER_MVP_ANDROID_VECTOREXPLAINED_H

#include <opencv2/opencv.hpp>
#include "Vector.h"
#include "common.h"

class VectorExplained : public Vector {
public:
    VectorExplained() {};

    VectorExplained(double x, double y) : Vector(x, y) {
        CalculateExplained();
    };

    void Set(cv::Point2d other);

    void Set(double x, double y) {
        _x = x;
        _y = y;
        CalculateExplained();
    }

    void SetMul(cv::Point2d other, double mulX, double mulY);

    void ApplyWindow(double windowStart, double windowEnd);

    virtual void Add(VectorExplained other);

    inline void Reset();

    void SetLength(double length);

    void operator*=(double mul);

    bool CheckWithinRectWithDefect(float left, float top, float right, float bottom);

    void AttractTo(Vector other, double force);

    inline int DirectionDiff(VectorExplained other) {
        return (_direction - other._direction + 12) % 8 - 4;
    }

    inline void MulWithDefect(double mat[2][2]) {
        double t = mat[0][0] * _x + mat[0][1] * _y;
        _y = mat[1][0] * _x + mat[1][1] * _y;
        _x = t;
        t = mat[0][0] * _defectX + mat[0][1] * _defectY;
        _defectY = fabsf((float) (mat[1][0] * _defectX + mat[1][1] * _defectY));
        _defectX = fabsf((float) t);
    }

    inline void FlipXY() {
        double t = _x;
        _x = _y;
        _y = t;
        float t2 = _defectX;
        _defectX = _defectY;
        _defectY = t2;
    }

    void Log();

    /**
     * calculates angle to another vector, result in [-180, 180]
     * @param other
     * @return
     */
    inline double AngleTo(VectorExplained other) {
        return fmod(other._angle - _angle + 540.0, 360.0) - 180.0;
    }

    inline VectorExplained operator-(VectorExplained other) {
        VectorExplained result;
        result._x = _x - other._x;
        result._y = _y - other._y;
        result._defectX2sum = other._defectX * other._defectX + _defectX * _defectX;
        result._defectY2sum = other._defectY * other._defectY + _defectY * _defectY;
        result._defectX = sqrtf((float) _defectX2sum);
        result._defectY = sqrtf((float) _defectY2sum);

        return result;
    }

    void setRelativeDefect(double relativeDefect) {
        _defectX = fabsf((float) (_x * relativeDefect));
        _defectY = fabsf((float) (_y * relativeDefect));
    }

    inline Vector ShiftDefectEllipseToTouchLineMagnet() {
        return ShiftEllipseToTouchLineMagnet(_defectX, _defectY);
    }

    inline Vector ShiftDefectRectToTouchLineMagnet() {
        return ShiftRectToTouchLineMagnet(_defectX, _defectY);
    }

    inline Vector ShiftDefectEllipseToPointMagnet(float targetX, float targetY, float mul) {
        return EllipticalShiftMagnet(_defectX * mul, _defectY * mul, targetX, targetY);
    }

    inline Vector ShiftDefectRectToPointMagnet(float targetX, float targetY, float mul) {
        return RectShiftMagnet(_defectX * mul, _defectY * mul, targetX, targetY);
    }

    /**
     * set 1-sized vector for specified direction
     * @param direction
     */
    void SetDirection(int direction);

    /**
     * set 1-sized vector for specified swype-points movement
     * @param from
     * @param to
     */
    void SetSwipePoints(int from, int to);

    float ModDefect() {
        if (_mod == 0)
            return 0;

        if (_defectX2sum == 0 && _defectY2sum == 0) {
            float t1 = _defectX * (float) _x;
            float t2 = _defectY * (float) _y;
            return sqrtf(t1 * t1 + t2 * t2);
        } else
            return (float) (sqrt(_x * _x * _defectX2sum + _y * _y * _defectY2sum) / _mod);
    }

    double MinDistanceToWithDefect(Vector other) {
#ifdef RECT_DEFECT
        Vector shifted = ShiftDefectRectToPointMagnet((float) other._x, (float) other._y, 1);
#else
        Vector shifted = EllipticalShiftMagnet(_defectX, _defectY, other._x, other._y);
#endif
        LOGI_NATIVE(
                "DistanceWithDefect (%.4f %.4f) shifted (%.4f, %.4f) to (%.4f, %.4f) distance = %.4f",
                _x, _y, shifted._x, shifted._y, other._x, other._y, shifted.DistanceTo(other)
        );
        return shifted.DistanceTo(other);
/*        double dx = fabs(other._x - _x);
        double dy = fabs(other._y - _y);
        dx = dx < _defectX ? 0.0 : dx - _defectX;
        dy = dy < _defectY ? 0.0 : dy - _defectY;
        return sqrt(dx * dx + dy * dy);*/
    }

    double _angle = 0;
    /**
     * 1 -- down, 3 -- left, 5 -- top, 7 -- right, 8 -- bottom-right
     */
    int _direction = 0;

    float _defectX = 0;
    float _defectY = 0;
    double _defectX2sum = 0;
    double _defectY2sum = 0;

private:
    void CalculateExplained();
};

inline void VectorExplained::Reset() {
    _x = 0;
    _y = 0;
    _mod = 0;
    _angle = 0;
    _direction = 0;
    _defectX = 0;
    _defectY = 0;
    _defectX2sum = 0;
    _defectY2sum = 0;
}


#endif //PROVER_MVP_ANDROID_VECTOREXPLAINED_H
