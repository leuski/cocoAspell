#/bin/sh -f

cd $1

ARCH_FLAGS="-arch ppc -arch i386 -arch ppc64 -arch x86_64 -mmacosx-version-min=10.5"
SDK_ROOT="-isysroot /Developer/SDKs/MacOSX10.5.sdk"

export CFLAGS="$SDK_ROOT $ARCH_FLAGS"
export CXXFLAGS="$SDK_ROOT $ARCH_FLAGS"
export LDFLAGS="$ARCH_FLAGS"

./configure --disable-dependency-tracking

make
