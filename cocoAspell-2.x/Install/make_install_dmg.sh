#!/bin/sh

this_root=`pwd`

install_root="$this_root/../../tmp"
install_root="${HOME}/Documents/Developer/Build/cocoAspell/install"
aspell_root="$this_root/../../aspell"

dmg_name="cocoAspell.2.5"

function execute {
	echo ""
	echo $*
	$*
}



echo ""
echo ""
read -p "build aspell package? [y]" -n 1 configure_aspell

if [ "$configure_aspell" != "n" ] 
then

	read -p "Specify aspell source directory [$aspell_root]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		aspell_root="$tmp_dir"
	fi
	
	pushd "$aspell_root"
	
	tmp_aspell_install_dir="$install_root/aspell"
	apsell_install_prefix="/usr/local"

	make clean

	ARCH_FLAGS="-arch x86_64 -mmacosx-version-min=10.10"
	SDK_ROOT="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

	export CFLAGS="$SDK_ROOT $ARCH_FLAGS"
	export CXXFLAGS="$SDK_ROOT $ARCH_FLAGS"
	export LDFLAGS="$ARCH_FLAGS"

	./configure --disable-dependency-tracking

	make -j 10
	make DESTDIR="$tmp_aspell_install_dir" install
	
	mkdir -p "${tmp_aspell_install_dir}${apsell_install_prefix}/etc/"
	cp "$this_root/../../cocoAspell-2.x/Sources/aspell.conf" "${tmp_aspell_install_dir}${apsell_install_prefix}/etc/"

	popd
	
	pkgbuild --root "${tmp_aspell_install_dir}${apsell_install_prefix}" \
		--identifier "net.leuski.cocoaspell.aspell.pkg" \
		--version 1 \
		--install-location "${apsell_install_prefix}" \
		"$install_root/aspell.pkg"
fi

echo ""
echo ""
read -p "Compile Spelling prefPane? [y]" -n 1 compile_spelling


if [ "$compile_spelling" != "n" ] 
then

	cd ..
	execute xcodebuild -target cocoAspell2 -configuration Deployment DSTROOT="$install_root"
	cd "$this_root"

fi

echo ""
echo ""
read -p "Make package? [y]" -n 1 make_package


if [ "$make_package" != "n" ] 
then

	read -p "Specify the name for cocoAspell installation directory [$dmg_name]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		dmg_name="$tmp_dir"
	fi

	mkdir -p "$install_root/$dmg_name"
	execute /Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc "$install_root/cocoAspell.pmdoc" --out "$install_root/$dmg_name/cocoAspell.pkg"
	cp -R "$install_root/Resources/READ BEFORE you install.rtfd" "$install_root/$dmg_name/"
fi

echo ""
echo ""

read -p "Make disk image? [y]" -n 1 make_disk_image


if [ "$make_disk_image" != "n" ] 
then

	read -p "Specify the name for cocoAspell installation directory [$dmg_name]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		dmg_name="$tmp_dir"
	fi

	if [ ! -d "$install_root/$dmg_name" ]
	then 
		echo "Directory \"$install_root/$dmg_name\" does not exist"
		exit 1
	fi
	
	execute hdiutil create -srcfolder "$install_root/$dmg_name" -ov "$install_root/$dmg_name.dmg"
fi


echo ""
echo ""



