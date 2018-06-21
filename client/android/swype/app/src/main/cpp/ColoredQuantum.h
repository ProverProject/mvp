//
// Created by babay on 20.06.2018.
//

#ifndef SWYPE_COLOREDQUANTUM_H
#define SWYPE_COLOREDQUANTUM_H


#include <cstddef>
#include <malloc.h>
#include <cstdlib>
#include "settings.h"

class ColoredQuantum {
public:

    ColoredQuantum(unsigned char red, unsigned char green, unsigned char blue) : red(red),
                                                                                 green(green),
                                                                                 blue(blue) {}

    virtual ~ColoredQuantum() {
        if (_rgbBuffer != NULL) {
            free(_rgbBuffer);
            _rgbBuffer = NULL;
        }
    }

    uint32_t *getRgbBuffer(int width, int height) {
        if (rgbBufferSize != width * height) {
            if (_rgbBuffer != NULL)
                free(_rgbBuffer);
            rgbBufferSize = static_cast<unsigned int>(width * height);
            _rgbBuffer = (uint32_t *) (malloc(4 * rgbBufferSize));
        }
        return _rgbBuffer;
    };

    void coloredQuantumToSingleByte(uint32_t *argb, unsigned char *target, int width, int height) {
        int size = width * height;
        int r, g, b;

        for (int i = 0; i < size; ++i) {
            uint32_t value = argb[i];
            r = static_cast<unsigned char>((value & 0xff0000) >> 16);
            g = static_cast<unsigned char>((value & 0xff00) >> 8);
            b = static_cast<unsigned char>(value & 0xff);

            if (abs(r - g) < QUANTUM_ALPHA || abs(r - b) < QUANTUM_ALPHA ||
                abs(g - b) < QUANTUM_ALPHA)
                *target = 0;
            else {
                if (r > g) {
                    *target = r > b ? red : blue;
                } else {
                    *target = g > b ? green : blue;
                }
            }
            ++target;
        }
    }

private:
    unsigned int rgbBufferSize = 0;
    uint32_t *_rgbBuffer = NULL;

    unsigned char red;
    unsigned char green;
    unsigned char blue;
};


#endif //SWYPE_COLOREDQUANTUM_H
