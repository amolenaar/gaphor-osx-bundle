#!/bin/sh

MACOS=`dirname $0`
CONTENTS=`dirname $MacOS`

PYTHONPATH=$CONTENTS/lib/python2.6
PYTHONPATH=$PYTHONPATH:$PYTHONPATH/site-packages

export PYTHONPATH

echo $PATH
echo ARGS: $*
$MACOS/gaphor
