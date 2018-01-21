#!/bin/bash

NAME_ROOT=garlium
PYTHON_VERSION=3.5.4

# These settings probably don't need any change
export WINEPREFIX=/opt/wine64
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=22

PYHOME=c:/python$PYTHON_VERSION
PYTHON="wine $PYHOME/python.exe -OO -B"


# Let's begin!
cd `dirname $0`
set -e

cd tmp

git clone -b master https://github.com/xSke/garlium.git
#for repo in garlium garlium-locale garlium-icons; do
#    if [ -d $repo ]; then
#	cd $repo
#	git pull
#	git checkout master
#	cd ..
#    else
#	URL=https://github.com/pooler/$repo.git
#	git clone -b master $URL $repo
#    fi
#done

#pushd garlium-locale
#for i in ./locale/*; do
#    dir=$i/LC_MESSAGES
#    mkdir -p $dir
#    msgfmt --output-file=$dir/electrum.mo $i/electrum.po || true
#done
#popd

pushd garlium
if [ ! -z "$1" ]; then
    git checkout $1
fi

VERSION=`git describe --tags`
echo "Last commit: $VERSION"
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

rm -rf $WINEPREFIX/drive_c/garlium
cp -r garlium $WINEPREFIX/drive_c/garlium
cp garlium/LICENCE .
#cp -r garlium-locale/locale $WINEPREFIX/drive_c/garlium/lib/
#cp garlium-icons/icons_rc.py $WINEPREFIX/drive_c/garlium/gui/qt/

# Install frozen dependencies
$PYTHON -m pip install -r ../../requirements.txt

pushd $WINEPREFIX/drive_c/garlium
$PYTHON setup.py install
popd

cd ..

rm -rf dist/

# build standalone and portable versions
wine "C:/python$PYTHON_VERSION/scripts/pyinstaller.exe" --noconfirm --ascii --name $NAME_ROOT-$VERSION -w deterministic.spec

# set timestamps in dist, in order to make the installer reproducible
pushd dist
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

# build NSIS installer
# $VERSION could be passed to the electrum.nsi script, but this would require some rewriting in the script iself.
wine "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" /DPRODUCT_VERSION=$VERSION electrum.nsi

cd dist
mv garlium-setup.exe $NAME_ROOT-$VERSION-setup.exe
cd ..

echo "Done."
md5sum dist/electrum*exe
