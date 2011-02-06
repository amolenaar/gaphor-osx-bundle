PYVER=2.6
INSTALLDIR=Gaphor.app/Contents
LIBDIR=$INSTALLDIR/lib

mkdir -p $INSTALLDIR

virtualenv --python=python$PYVER --no-site-packages $INSTALLDIR

$INSTALLDIR/bin/easy_install gaphor

#virtualenv --relocatable $INSTALLDIR

# Temp. solution
SITEPACKAGES=$LIBDIR/python$PYVER/site-packages

mkdir -p $SITEPACKAGES

pygtk=`python -c "import pygtk; print pygtk.__file__[:-1]"`
oldsite=`dirname $pygtk`

# Copy PyGtk and related libraries

cp $pygtk $SITEPACKAGES
cp -r $oldsite/cairo $SITEPACKAGES
cp -r $oldsite/gtk-2.0 $SITEPACKAGES
cp $oldsite/pygtk.pth $SITEPACKAGES

# Somehow files are writen with mode 444
find $LIBDIR -type f -exec chmod u+w {} \;

function log() {
  echo $* >&2
}

function resolve_deps() {
  local lib=$1
  local dep
  otool -L $lib | grep -e '^./usr/local/' |\
      while read dep _; do
    if test "$dep" != "$lib"; then
      echo $dep
    fi
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

binlibs=`find $SITEPACKAGES -type f -name '*.so'`

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
