# Build fframes for ios

This example shows how to cross compile fframes for ios platform and link it with xcode project. Including the real metal-powered GPU rendering backend and real-time rendering to the metal drawable canvas.

To run this example: clone this repository, install the rust toolchain for cross compiling to IOS and build the rust library for dedicated target.

```bash
rustup target add aarch64-apple-ios
cargo build  --target aarch64-apple-ios --release
```

Make sure that this only works on arm64 macs if you need to compile for x86_64 you need to add the target `x86_64-apple-ios` and run the same command with the target `x86_64-apple-ios` or you can create a universal binary using [cargo lipo](https://github.com/TimNN/cargo-lipo).

```bash
rustup target add x86_64-apple-ios aarch64-apple-ios
cargo lipo --release
```

## Canvas real-time rendering

The Xcode example also features real-time rendering on the drawable canvas, controlled by Swift. To run it, make sure you have `fframe-skia-renderer` dependency installed in Cargo.toml (you might need to install [additional tools and libraries](https://github.com/rust-skia/rust-skia) to build it on your machine).

> [!CAUTION]
> Most of the Swift code for player controlling the canvas was AI generated, it is working but please be extra cautios by integrating this to your app

## Linking fframes binaries

Your target folder now should be have `target/aarch64-apple-ios/release/libhello_world_example.a` file. Which is ready to be linked with your xcode project. Please make sure to add it as a framework and add library search path in your xcode project (it is already added in this example).

This is already done by the example xcode project, but you will have to repeat this if you would like to link fframes binary yourself:

![library path](./search_path.png)

add it as a dependency to your xcode project

![framework](./framework.png)

now your project will be able to run the basic version of fframes example.
