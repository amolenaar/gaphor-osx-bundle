#!/bin/bash
#
# Package script for Gaphor.
#
# Thanks: http://stackoverflow.com/questions/1596945/building-osx-app-bundle

# Also fix $INSTALLDIR/MacOS/gaphor in case this number changes
PYVER=2.6
APP=Gaphor.app
INSTALLDIR=$APP/Contents
LIBDIR=$INSTALLDIR/lib

LOCALDIR=/usr/local

virtualenv --python=python$PYVER --no-site-packages $INSTALLDIR

$INSTALLDIR/bin/easy_install gaphor

# Make hashbang for python scripts in bin/ relative (#!/usr/bin/env python2.6)
#virtualenv -v --relocatable $INSTALLDIR

# Temp. solution
SITEPACKAGES=$LIBDIR/python$PYVER/site-packages

mkdir -p $SITEPACKAGES

# This locates pygtk.pyc. We want the source file
pygtk=`python -c "import pygtk; print pygtk.__file__[:-1]"`
oldsite=`dirname $pygtk`

# Copy PyGtk and related libraries

cp $pygtk $SITEPACKAGES
cp -r $oldsite/cairo $SITEPACKAGES
cp -r $oldsite/gtk-2.0 $SITEPACKAGES
cp $oldsite/pygtk.pth $SITEPACKAGES

# Modules, config, etc.
for dir in etc/pango lib/pango etc/gtk-2.0 lib/gtk-2.0 share/themes lib/gdk-pixbuf-2.0; do
  mkdir -p $INSTALLDIR/$dir
  cp -r $LOCALDIR/$dir/* $INSTALLDIR/$dir
done

# Resources, are processed on startup
for dir in etc/gtk-2.0 etc/pango lib/gdk-pixbuf-2.0/2.10.0; do
  mkdir -p $INSTALLDIR/Resources/$dir
  cp $LOCALDIR/$dir/* $INSTALLDIR/Resources/$dir
done

# Somehow files are writen with mode 444
find $INSTALLDIR -type f -exec chmod u+w {} \;

function log() {
  echo $* >&2
}

function resolve_deps() {
  local lib=$1
  local dep
  otool -L $lib | grep -e "^.$LOCALDIR/" |\
      while read dep _; do
    echo $dep
  done
}

function fix_paths() {
  local lib=$1
  log Fixing $lib
  for dep in `resolve_deps $lib`; do
    #log Fixing `basename $lib`
    log "|  $dep"
    install_name_tool -change $dep @executable_path/../lib/`basename $dep` $lib
  done
}

binlibs=`find $INSTALLDIR -type f -name '*.so'`

for lib in $binlibs; do
  log Resolving $lib
  resolve_deps $lib
  fix_paths $lib
done | sort -u | while read lib; do
  log Copying $lib
  cp $lib $LIBDIR
  chmod u+w $LIBDIR/`basename $lib`
  fix_paths $LIBDIR/`basename $lib`
done

function fix_config() {
  local file=$1
  local replace=$2

  mv $file $file.orig
  sed "$replace" $file.orig > $file
}

# Fix config files

#fix_config $INSTALLDIR/etc/pango/pango.modules 's#/usr/local/.*lib/#${CWD}/../lib/#'
#fix_config $INSTALLDIR/etc/gtk-2.0/gtk.immodules 's#/usr/local/.*lib/#${CWD}/../lib/#'
#fix_config $INSTALLDIR/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache 's#/usr/local/.*lib/#${CWD}/../lib/#'

# Normalize paths (Homebrew refers everything from it's Cellar)
fix_config $INSTALLDIR/Resources/etc/pango/pango.modules 's#/usr/local/.*lib/#/usr/local/lib/#'
fix_config $INSTALLDIR/Resources/etc/gtk-2.0/gtk.immodules 's#/usr/local/.*lib/#/usr/local/lib/#'
fix_config $INSTALLDIR/Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache 's#/usr/local/.*lib/#/usr/local/lib/#'

# Package!

VERSION=`find . -name 'gaphor*egg' | sed -e 's|.*/gaphor-||' -e 's|-py.*egg$||'`
zip -r Gaphor-$VERSION-osx-x11.zip $APP
hdiutil create -srcfolder $APP Gaphor-$VERSION-x11.dmg
