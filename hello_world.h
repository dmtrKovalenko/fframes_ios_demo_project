#include <stdint.h>
#include <stdbool.h>

void fframes_render(const char *slug, const char *to, const char *tmp_dir);

// this are only required for real time rendering on the canvas 
void* create_metal_context(void* device_ptr, void* command_que_ptr, void* texture_ptr, int64_t width, int64_t height);
void* create_video_instance(const char* slug);
void* create_fframes_video_ctx(void* video);
bool render_frame(void* metal_ctx, void* fframes_ctx, void* video_instance, int64_t frame);
