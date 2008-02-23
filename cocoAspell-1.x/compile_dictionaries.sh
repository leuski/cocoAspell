#! /bin/sh -f


## make sure the directory exists and cd into it

if [ ! -d "Dictionaries" ]
then
	mkdir "Dictionaries"
fi

cd "Dictionaries"

debug=1

if [ debug -eq 0 ]
then

## load the tarball from the web

echo "loading dictionaries archive..."
curl -s -S -o aspell-all.tar http://aspell.sourceforge.net/aspell-all.tar
if [ $? -ne 0 ]
then
	echo "failed to load. error: $?"
	exit 1
fi

if [ ! -f aspell-all.tar ] 
then
	echo "file aspell-all.tar does not exist"
	exit 1
fi

## unpack the tarball

echo "unpacking dictionaries archive..."
tar xf aspell-all.tar
rm aspell-all.tar

## erase extra junk that has nothing to do with the dictionaries

if [ -f aspell-gen-0.9.1.tar.bz2 ] 
then
	echo "removing aspell-gen-0.9.1.tar.bz2"
	rm aspell-gen-0.9.1.tar.bz2
fi


## unpack archives

for f in `sh -c "ls *.bz2"`
do
	echo "unpacking $f..."
	bunzip2 $f
done

## untar archives

for f in `sh -c "ls *.tar"`
do
	echo "unpacking $f..."
	tar xf $f
	rm $f
done

fi

## export variables

export ASPELL="/Users/leuski/Library/Services/cocoAspell.service/Contents/MacOS/cocoAspell"
export PSPELL_CONFIG="/Users/leuski/Library/Services/cocoAspell.service/Contents/MacOS/cocoAspell"
export WORD_LIST_COMPRESS="/Users/leuski/Library/Services/cocoAspell.service/Contents/Resources/word-list-compress"

## run build for every dictionary


for f in `sh -c "ls -d aspell-*"`
do
	if [ -d $f ]
	then
		echo "making dictionary $f ..."

		cd $f
		
		rws=""
		rws=`sh -c "ls -d *.rws"`
		if [ -z $rws ]
		then
			./configure
			make
			rm Makefile
		else
			echo "file(s) $rws exist(s). I'll not run make again."
		fi
		
		cd ..
	fi
done




