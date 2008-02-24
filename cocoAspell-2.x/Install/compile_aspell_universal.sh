#/bin/sh -f

cd $1

export CFLAGS="-isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386 -mmacosx-version-min=10.4"
export CXXFLAGS="-isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386 -mmacosx-version-min=10.4"
export LDFLAGS="-arch ppc -arch i386 -mmacosx-version-min=10.4"

./configure --disable-dependency-tracking

make
