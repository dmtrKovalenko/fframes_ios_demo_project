use fframes::StaticMediaProvider;
use fframes_renderer::{fframes_logger, render, EncoderOptions, RenderOptions};
pub mod hello_world;
pub use hello_world::*;
pub mod hello_world_multiscene;
pub use hello_world_multiscene::*;
use std::os::raw::c_char;
use std::path::PathBuf;

#[no_mangle]
extern "C" fn fframes_render(slug: *const c_char, to: *const c_char, tmp_dir: *const c_char) {
    let media = HelloWorldMedia::prepare().unwrap();
    let slug = unsafe { std::ffi::CStr::from_ptr(slug).to_str().unwrap() };
    let to = unsafe { std::ffi::CStr::from_ptr(to).to_str().unwrap() };
    let tmp_dir = unsafe { std::ffi::CStr::from_ptr(tmp_dir).to_str().unwrap() };

    render(
        &HelloWorldVideo {
            media: &media,
            slug: &slug,
        },
        to,
        RenderOptions {
            media: Some(&media),
            load_system_fonts: false,
            logger: fframes_logger::FFramesLoggerVariant::Compact,
            encoder_options: EncoderOptions {
                tmp_files_directory: Some(&PathBuf::from(tmp_dir)),
                ..Default::default()
            },
            render_backend: fframes_renderer::cpu::CpuRenderingBackend {
                cache_capacity: 5,
                ..Default::default()
            },
            ..Default::default()
        },
    )
    .unwrap();
}
