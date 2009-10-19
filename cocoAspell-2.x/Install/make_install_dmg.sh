#!/bin/sh

this_root=`pwd`

install_root="$this_root/../../tmp"
aspell_root="$this_root/../../aspell-0.60.5"

installed_log="$this_root/installed.log.txt"
installed_log="/Users/leuski/Documents/Projects/cocoaspell/installed.0.60.5.2.txt"
dmg_name="cocoAspell.2.1"

function execute {
	echo ""
	echo $*
	$*
}

echo ""
echo ""
read -p "Export Installer root? [y]" -n 1 export_installer

if [ "$export_installer" != "n" ] 
then
	read -p "Specify installer root [$install_root]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		install_root="$tmp_dir"
	fi
	
	execute svn --force export "http://leuski@leuski.homeip.net:8057/svn/cocoAspell/trunk/cocoAspell-2.x/Install" "$install_root"
fi

echo ""
echo ""
read -p "Configure aspell compilation? [y]" -n 1 configure_aspell

if [ "$configure_aspell" != "n" ] 
then

	read -p "Specify aspell installation directory [$aspell_root]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		aspell_root="$tmp_dir"
	fi
	
	cd Scripts
	execute ./compile_aspell_universal.sh "$aspell_root"
	cd "$this_root"

fi

echo ""
echo ""
read -p "Install aspell? [y]" -n 1 install_aspell

if [ "$install_aspell" != "n" ] 
then

	read -p "Specify aspell installation directory [$aspell_root]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		aspell_root="$tmp_dir"
	fi
	
	cd "$aspell_root"
	execute sudo make install > "$installed_log"
	cd "$this_root"
	
fi

echo ""
echo ""
read -p "Configure aspell root? [y]" -n 1 configure_aspell_root

if [ "$configure_aspell_root" != "n" ] 
then

	read -p "Specify aspell installation log [$installed_log]:" tmp_dir
	if [ -n "$tmp_dir" ]
	then
		installed_log="$tmp_dir"
	fi
	
	if [ ! -f "$installed_log" ]
	then
		echo "Cannot locate file $installed_log"
		exit 1
	fi
	
	cd Scripts
	execute ./prepare_aspell_root.sh "$installed_log" "$install_root"
	cd "$this_root"
	
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



