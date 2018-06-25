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
        increaseContrast(argb, width, height);
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

    void increaseContrast(uint32_t *argb, int width, int height) {
        int size = width * height;
        unsigned char minR = 0xFF, maxR = 0,
                minG = 0xFF, maxG = 0, minB = 0xFF, maxB = 0,
                r, g, b;

        for (int i = 0; i < size; ++i) {
            uint32_t value = argb[i];
            r = static_cast<unsigned char>((value & 0xff0000) >> 16);
            g = static_cast<unsigned char>((value & 0xff00) >> 8);
            b = static_cast<unsigned char>(value & 0xff);

            if (r < minR)
                minR = r;
            if (r > maxR)
                maxR = r;
            if (g < minG)
                minG = g;
            if (g > maxG)
                maxG = g;
            if (b < minB)
                minB = b;
            if (b > maxB)
                maxB = b;
        }

        float mulR = colorMul(minR, maxR);
        float mulG = colorMul(minG, maxG);
        float mulB = colorMul(minB, maxB);

        for (int i = 0; i < size; ++i) {
            uint32_t value = argb[i];
            r = static_cast<unsigned char>((value & 0xff0000) >> 16);
            g = static_cast<unsigned char>((value & 0xff00) >> 8);
            b = static_cast<unsigned char>(value & 0xff);

            r = static_cast<unsigned char>((r - minR) * mulR);
            g = static_cast<unsigned char>((g - minG) * mulG);
            b = static_cast<unsigned char>((b - minB) * mulB);

            argb[i] = 0xFF000000 | r << 16 | g << 8 | b;
        }
    }

private:

    inline float colorMul(unsigned char &min, unsigned char &max) {
        if (max > min) {
            return 255.0f / (max - min);
        } else {
            min = 0;
            max = 0xff;
            return 1;
        }
    }
    unsigned int rgbBufferSize = 0;
    uint32_t *_rgbBuffer = NULL;

    unsigned char red;
    unsigned char green;
    unsigned char blue;
};


#endif //SWYPE_COLOREDQUANTUM_H
