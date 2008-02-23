#! /bin/sh

archiveName=cocoAspell.tar

echo "*** building Service"

pbxbuild install -target Service -buildstyle Deployment

echo "*** building PreferencePane"

pbxbuild install -target PreferencePane -buildstyle Deployment

echo "*** making .tar file"

tar cvf $archiveName Documentation

curDir=`pwd`

echo "*** adding cocoAspell.service"

cd /tmp/cocoAspell.dst/Library/Services
tar rvf $curDir/$archiveName cocoAspell.service

echo "*** adding Spelling.prefPane"

cd /tmp/cocoAspell.dst/Library/PreferencePanes
tar rvf $curDir/$archiveName Spelling.prefPane

cd $curDir

echo "*** compressing"

gzip $archiveName

echo "*** done"
