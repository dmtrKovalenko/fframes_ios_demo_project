fn main() {
    println!("cargo:rustc-link-lib=bz2");

    println!("cargo:rustc-link-lib=z");

    println!("cargo:rustc-link-lib=framework=CoreFoundation");

    println!("cargo:rustc-link-lib=framework=CoreMedia");

    println!("cargo:rustc-link-lib=framework=CoreVideo");

    println!("cargo:rustc-link-lib=framework=VideoToolbox");

    println!("cargo:rustc-link-lib=framework=Security");

    println!("cargo:rustc-link-lib=framework=Metal");

    println!("cargo:rustc-link-lib=c++");
}
