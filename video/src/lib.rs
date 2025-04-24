use fframes::StaticMediaProvider;
use fframes::{fframes_logger, EncoderOptions, RenderOptions, Video};
pub mod hello_world;
use fframes_skia_renderer::metal::SkiaMetalCtx;
use fframes_skia_renderer::skia_safe::ColorType;
use fframes_skia_renderer::{
    InstantRenderingGPUBackend, InstantRenderingVideoCtx, SkiaFFramesRenderer, SkiaPipelineConfig,
};
pub use hello_world::*;
use std::ffi::c_void;
use std::os::raw::c_char;
use std::path::PathBuf;

// !IMPORTANT!
// This is just general proof of concept so all the error handling is basically omitted.
// Please do not underestimate the danger of panics in production, this will crash the whole app.

#[no_mangle]
extern "C" fn fframes_render(slug: *const c_char, to: *const c_char, tmp_dir: *const c_char) {
    let media = HelloWorldMedia::prepare().unwrap();
    let slug = unsafe { std::ffi::CStr::from_ptr(slug).to_str().unwrap() };
    let to = unsafe { std::ffi::CStr::from_ptr(to).to_str().unwrap() };
    let tmp_dir = unsafe { std::ffi::CStr::from_ptr(tmp_dir).to_str().unwrap() };

    let metal_ctx = SkiaMetalCtx::new(HelloWorldVideo::WIDTH, HelloWorldVideo::HEIGHT).unwrap();

    fframes::render(
        to,
        &HelloWorldVideo {
            media: &media,
            slug: slug.to_string(),
        },
        fframes_skia_renderer::SkiaFFramesRenderer::new_metal(
            &metal_ctx,
            SkiaPipelineConfig {
                buffer_queue_size: 1,
                encoder_threads: 1,
                concurrency_policy:
                    fframes_skia_renderer::SkiaPipelineConcurrencyPolicy::MaxPerformance,
            },
        )
        .unwrap(),
        &RenderOptions {
            media: Some(&media),
            load_system_fonts: false,
            logger: fframes_logger::FFramesLoggerVariant::Compact,
            encoder_options: EncoderOptions {
                // hardware accelerated h264 encoder comes with videotoolbox
                preferred_video_codec: Some("h264_videotoolbox"),
                // preferred_audio_codec: Some("aac"),
                tmp_files_directory: Some(&PathBuf::from(tmp_dir)),
                ..Default::default()
            },
            ..Default::default()
        },
    )
    .unwrap();
}

#[no_mangle]
extern "C" fn create_metal_context(
    device_ptr: *mut std::ffi::c_void,
    command_queue_ptr: *mut std::ffi::c_void,
    texture_ptr: *mut std::ffi::c_void,
    width: i64,
    height: i64,
) -> *mut c_void {
    let (metal_ctx, surface, gpu_context) = SkiaMetalCtx::new_from_existing_texture(
        device_ptr,
        command_queue_ptr,
        texture_ptr,
        // default color format for metal will be used by ios mtk view
        ColorType::BGRA8888,
        width as usize,
        height as usize,
    )
    .expect("failed to create metal context");

    let instant_rendering_ctx =
        InstantRenderingGPUBackend::new_from_existing_texture(metal_ctx, surface, gpu_context);

    Box::into_raw(Box::new(instant_rendering_ctx)) as *mut c_void
}

fframes::lazy_static::lazy_static! {
    static ref MEDIA: HelloWorldMedia = HelloWorldMedia::prepare().unwrap();
}

#[no_mangle]
extern "C" fn create_video_instance(slug: *const c_char) -> *mut c_void {
    let slug = unsafe { std::ffi::CStr::from_ptr(slug).to_str().unwrap() };

    let video = HelloWorldVideo {
        media: &MEDIA,
        slug: slug.to_string(),
    };

    Box::into_raw(Box::new(video)) as *mut c_void
}

#[no_mangle]
extern "C" fn create_fframes_video_ctx(video: *const c_void) -> *mut c_void {
    let video = unsafe { &*(video as *const HelloWorldVideo) };

    let media: &'static HelloWorldMedia = &MEDIA;
    let ctx = InstantRenderingVideoCtx::new(video, Some(media));

    Box::into_raw(Box::new(ctx)) as *mut c_void
}

#[no_mangle]
extern "C" fn render_frame(
    metal_ctx: *mut c_void,
    fframes_ctx: *mut c_void,
    video_instance: *mut c_void,
    frame: i64,
) -> bool {
    let metal_ctx = unsafe { &mut *(metal_ctx as *mut InstantRenderingGPUBackend<SkiaMetalCtx>) };
    let video_ctx = unsafe { &*(fframes_ctx as *mut InstantRenderingVideoCtx<'static>) };
    let video_instance = unsafe { &*(video_instance as *const HelloWorldVideo) };

    SkiaFFramesRenderer::instant_render(
        frame.try_into().unwrap(),
        video_instance,
        Some(&*MEDIA),
        video_ctx,
        metal_ctx,
    )
    .expect("failed to render frame")
}
