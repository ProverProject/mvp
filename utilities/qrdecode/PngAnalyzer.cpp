// Blashyrkh.maniac.coding
// BTC:1Maniaccv5vSQVuwrmRtfazhf2WsUJ1KyD DOGE:DManiac9Gk31A4vLw9fLN9jVDFAQZc2zPj

#include "PngAnalyzer.h"
#include <cstdio>
#include <cstring>
#include <png.h>


PngAnalyzer::PngAnalyzer(
    const std::string &filename,
    const Config      &config) :

    _filename(filename),
    _config(config)
{
}

Analyzer::Result PngAnalyzer::analyzeFile()
{
    Result result;

    FILE *f=fopen(_filename.c_str(), "rb");
    if(!f)
    {
        fprintf(stderr, "Failed to open file\n");
        return result.setError();
    }

    png_structp png=png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if(!png)
    {
        fprintf(stderr, "png_create_read_struct failed\n");
        return result.setError();
    }

    png_infop info=png_create_info_struct(png);
    if(!info)
    {
        fprintf(stderr, "png_create_info_struct failed\n");
        return result.setError();
    }

    if(setjmp(png_jmpbuf(png)))
    {
        fprintf(stderr, "PNG decode failed\n");
        return result.setError();
    }

    png_init_io(png, f);
    png_read_info(png, info);

    unsigned int width=png_get_image_width(png, info);
    unsigned int height=png_get_image_height(png, info);

    png_set_rgb_to_gray(png, PNG_ERROR_ACTION_NONE, 54.0f/256.0f, 183.0f/256.0f);
    png_set_expand_gray_1_2_4_to_8(png);

    png_read_update_info(png, info);

    if(_config.getVerbosity()>0)
        fprintf(stderr, "Starting decompress, w=%u h=%u\n", width, height);

    std::vector<uint8_t> imagedata;
    imagedata.resize(width*height);

    std::vector<png_bytep> scanlines;
    scanlines.reserve(height);
    for(unsigned int i=0; i<height; ++i)
        scanlines.push_back(imagedata.data()+i*width);

    png_read_image(png, scanlines.data());

    fclose(f);
    // TODO: free decoder structures

    if(_config.getVerbosity()>0)
        fprintf(stderr, "Image successfully decoded\n");

    analyzeGrayscaleImage(
        width,
        height,
        (const char *)imagedata.data(),
        _config.getVerbosity(),
        result);

    return result;
}
