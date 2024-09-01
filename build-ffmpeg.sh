#!/bin/bash

IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
IOS_CC=$(xcrun --sdk iphoneos -f clang)
IOS_CXX=$(xcrun --sdk iphoneos -f clang++)

./configure \
    --prefix=$(pwd)/ios-build \
    --enable-cross-compile \
    --disable-programs \
    --disable-debug \
    --disable-audiotoolbox \
    --target-os=darwin \
    --arch=arm64 \
    --cc=$IOS_CC \
    --cxx=$IOS_CXX \
    --sysroot=$IOS_SDK \
    --extra-cflags="-arch arm64 -isysroot $IOS_SDK" \
    --extra-ldflags="-arch arm64 -isysroot $IOS_SDK" \
    --enable-pic \
    --disable-shared \
    --enable-static

make -j$(sysctl -n hw.ncpu)
make install

