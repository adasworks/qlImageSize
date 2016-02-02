#import "tools.h"


CF_RETURNS_RETAINED CGImageRef decode_raw_at_path(CFStringRef filepath,  image_infos* infos);

bool get_raw_informations_for_filepath(CFStringRef filepath, image_infos* infos);
