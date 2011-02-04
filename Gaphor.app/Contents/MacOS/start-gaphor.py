#!/usr/bin/python

# Do some stiff with sys.path

# Set CWD
import os
print 'CWD:', os.getcwd()

import sys
print 'ARGV:', sys.argv
print 'PATH:', sys.path

# Start app
import gaphor
gaphor.launch()

