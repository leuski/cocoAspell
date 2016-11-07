#/bin/sh -f

ASPELL_SRC_DIR=$1
ASPELL_INSTALL_DIR=$2

cd "$ASPELL_SRC_DIR"

make clean

ARCH_FLAGS="-arch x86_64 -mmacosx-version-min=10.10"
SDK_ROOT="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

export CFLAGS="$SDK_ROOT $ARCH_FLAGS"
export CXXFLAGS="$SDK_ROOT $ARCH_FLAGS"
export LDFLAGS="$ARCH_FLAGS"

echo $CXXFLAGS


./configure --disable-dependency-tracking

make -j 10
make DESTDIR="$ASPELL_INSTALL_DIR" install
