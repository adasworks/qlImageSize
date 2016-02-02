#import <Foundation/Foundation.h>
#import "raw_decode.h"

static const int RAW_WIDTH = 2592;
static const int RAW_HEIGHT = 1944;
static const int RAW_BITS_PER_CHANNEL = 12;
// BAYER PATTERN GRBG

struct rgba { uint8_t r,g,b,a; };
struct bayer12bit { uint8_t a8, ab4, b8; };

CF_RETURNS_RETAINED CGImageRef decode_raw_at_path(CFStringRef filepath, image_infos* infos)
{
    // Read file
    uint8_t* buffer = NULL;
    const size_t file_size = read_file(filepath, &buffer);
    if (0 == file_size)
    {
        free(buffer);
        return NULL;
    }

    // TODO: make a WIDTH/HEIGHT guess based on file size, and resolution.
    if (file_size != RAW_WIDTH * RAW_HEIGHT * RAW_BITS_PER_CHANNEL / 8)
    {
        free(buffer);
        return NULL;
    }

    size_t w = RAW_WIDTH / 2;
    size_t h = RAW_HEIGHT / 2;
    struct rgba * pixels = malloc(w*h*sizeof(struct rgba));
    const struct bayer12bit *raw12 = (const struct bayer12bit*)buffer;

    // Basic demosaic using downsampling. Input must be "GRBG"
    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            struct rgba p;
            struct bayer12bit bay0 = raw12[2*y*w + x];
            struct bayer12bit bay1 = raw12[(2*y+1)*w + x];
            p.r = bay0.b8;
            p.g = (uint8_t)(((int)bay0.b8 + bay1.a8)/2);
            p.b = bay1.a8;
            p.a = 255;
            pixels[y*w+x] = p;
        }
    }
    free(buffer);

    if (infos != NULL)
    {
        infos->width = RAW_WIDTH;
        infos->height = RAW_HEIGHT;
        infos->filesize = (size_t)file_size;
    }

    // Create CGImage
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels, w, h, 8, 4 * w, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(color_space);
    free(pixels);
    CGImageRef img_ref = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return img_ref;
}

bool get_raw_informations_for_filepath(CFStringRef __unused filepath, image_infos* infos)
{
    infos->width = RAW_WIDTH;
    infos->height = RAW_HEIGHT;
    infos->has_alpha = false;
    infos->bit_depth = RAW_BITS_PER_CHANNEL;
    infos->colorspace = colorspace_rgb;
    return true;
}
