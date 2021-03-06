//
// Created by babay on 09.12.2017.
//

#include "BoundsChecker.h"
#include "common.h"
#include "VectorExplained.h"

void BoundsChecker::SetDirection(int targetDirection) {
    _isDiagonal = targetDirection % 2 == 0;
    SetMatForDirection(targetDirection);
    /*if (_isDiagonal) {

    } else {
        int directionDiff = (7 - targetDirection + 12) % 8 - 4;
        SetTurnMatForDirectionDiff(directionDiff);
    }*/
}

void BoundsChecker::SetTurnMatForDirectionDiff(int directionDiff) {
    switch (directionDiff) {
        case 0:
            _turnMat[0][0] = _turnMat[1][1] = 1;
            _turnMat[1][0] = _turnMat[0][1] = 0;
            break;
        case -4:
            _turnMat[0][0] = _turnMat[1][1] = -1;
            _turnMat[1][0] = _turnMat[0][1] = 0;
            break;
        case 2:
            _turnMat[0][0] = _turnMat[1][1] = 0;
            _turnMat[1][0] = 1;
            _turnMat[0][1] = -1;
            break;
        case -2:
            _turnMat[0][0] = _turnMat[1][1] = 0;
            _turnMat[1][0] = -1;
            _turnMat[0][1] = 1;
            break;
    }
}


void BoundsChecker::SetMatForDirection(int direction) {
    _turnMat[1][0] = _turnMat[0][1] = 0;
    switch (direction) {
        case 8:
        case 7:
            _turnMat[0][0] = _turnMat[1][1] = 1;
            _turnMat[1][0] = _turnMat[0][1] = 0;
            break;
        case 2:
        case 3:
            _turnMat[0][0] = -1;
            _turnMat[1][1] = 1;
            _turnMat[1][0] = _turnMat[0][1] = 0;
            break;
        case 4:
            _turnMat[0][0] = -1;
            _turnMat[1][1] = -1;
            _turnMat[1][0] = _turnMat[0][1] = 0;
            break;
        case 6:
            _turnMat[0][0] = 1;
            _turnMat[1][1] = -1;
            _turnMat[1][0] = _turnMat[0][1] = 0;
            break;
        case 1:
            _turnMat[0][0] = _turnMat[1][1] = 0;
            _turnMat[1][0] = 1;
            _turnMat[0][1] = 1;
            break;
        case 5:
            _turnMat[0][0] = _turnMat[1][1] = 0;
            _turnMat[1][0] = 1;
            _turnMat[0][1] = -1;
            break;
    }
}

/**
 *
 * @param current -- current position vector
 * @return true if we're still OK
 */
bool BoundsChecker::CheckBounds(VectorExplained p) {
    // turn _current so we should move to +x (of +x, +y for Diagonal)
    // fail if we've got too close to another swype-point
    p.MulWithDefect(_turnMat);
    float tr1 = 1 + _targetRadius;

    if (_isDiagonal) {
        if (p._x < -FIT_FACTOR_H || p._y < -FIT_FACTOR_H || p._x > tr1 || p._y > tr1) {
            if (logLevel > 0) {
                LOGI_NATIVE("Bounds_f1 %.4f, %.4f, tr: %.4f", p._x, p._y, _targetRadius);
            }
            return false;
        }

        if (p._x + p._y <= 0) {
            return true;
        }

        if (p._y > p._x) {
            p.FlipXY();
        }

        // ensure that we can't get into wrong swype-point (1,0) accounting defect
        // defect is double 'cause server can will have different result
#ifdef RECT_DEFECT
        Vector shifted = p.ShiftDefectRectToPointMagnet(1, 0, 2);
#else
        Vector shifted = p.ShiftDefectEllipseToPointMagnet(1, 0, 2);
#endif
        float distanceToWrongPoint = (float) shifted.DistanceTo(1, 0);
        if (distanceToWrongPoint <= _targetRadiusOther) {
            if (logLevel > 0) {
                LOGI_NATIVE("Bounds 2shifted (%.4f %.4f) dist = %.4f", shifted._x, shifted._y,
                            distanceToWrongPoint);
            }
            return false;
        }

        //distance to line x = y -- it is the line that goes to target point
        double d1 = (p._x - p._y) / _sqrt2;
        // distance to remaining non-target swype point
        double r2 = p.DistanceTo(1, 0);
        if (logLevel == 0)
            return d1 < r2;
        else {
            if (d1 < r2)
                return true;
            if (logLevel > 0) {
                LOGI_NATIVE("Bounds_f3 %.4f, %.4f, %f, %f", p._x, p._y, d1, r2);
            }
            return false;
        }
    } else {
        return p._x >= -FIT_FACTOR_H && p._x <= tr1 && fabs(p._y) <= FIT_FACTOR_H;
    }
}


bool BoundsChecker::CheckBoundsWithDefect(VectorExplained p) {
    p.MulWithDefect(_turnMat);
    float tr1 = 1 + _targetRadius;

    if (_isDiagonal) {
        if (!p.CheckWithinRectWithDefect(-FIT_FACTOR_H_RELAXED, -FIT_FACTOR_H_RELAXED, tr1, tr1)) {
            if (logLevel > 0) {
                LOGI_NATIVE("Bounds_f1 %.4f, %.4f", p._x, p._y);
            }
            return false;
        }

        if (p._x + p._y <= 0) {
            return true;
        }

        if (p._x < p._y) {
            p.FlipXY();
        }

        // ensure that we can't get into wrong swype-point (1,0) accounting defect
#ifdef RECT_DEFECT
        Vector shifted = p.ShiftDefectRectToPointMagnet(1, 0, 1);
#else
        Vector shifted = p.ShiftDefectEllipseToPointMagnet(1, 0, 1);
#endif
        float distanceToWrongPoint = (float) shifted.DistanceTo(1, 0);
        if (distanceToWrongPoint <= _targetRadiusOther) {
            if (logLevel > 0) {
                LOGI_NATIVE("Bounds 2shifted (%.4f %.4f) dist = %.4f", shifted._x, shifted._y,
                            distanceToWrongPoint);
            }
            return false;
        }
#ifdef RECT_DEFECT
        Vector shiftedToLine = p.ShiftDefectRectToTouchLineMagnet();
#else
        Vector shiftedToLine = p.ShiftDefectEllipseToTouchLineMagnet();
#endif
        if (shiftedToLine._x == shiftedToLine._y)
            return true;
        //a point on the diagonal within defect area, so we are definitely not failed
        if (p._x <= p._y) {
            return true;
        }

        //distance to line x = y -- it is the line that goes to target point
        double d1 = (shiftedToLine._x - shiftedToLine._y) / _sqrt2;
        // distance to remaining non-target swype point
        double r2 = shiftedToLine.DistanceTo(1, 0);
        if (logLevel == 0)
            return d1 < r2;
        else {
            if (d1 < r2)
                return true;
            if (logLevel > 0) {
                LOGI_NATIVE("Bounds_f3 %.4f, %.4f, %f, %f", shiftedToLine._x, shiftedToLine._y, d1,
                            r2);
            }
            return false;
        }
    } else {
        return p.CheckWithinRectWithDefect(-FIT_FACTOR_H_RELAXED, -FIT_FACTOR_H_RELAXED, tr1,
                                           FIT_FACTOR_H_RELAXED);
    }
}

void BoundsChecker::SetTargetRadius(float targetRadius, float targetRadiusOther) {
    _targetRadius = targetRadius;
    _targetRadiusOther = targetRadiusOther;
}

