#!/usr/bin/env python
# encoding: utf-8

import sys
import os

os.chdir('/home/geza/japanese-parse/knp-4.01')
os.system('echo "' + sys.argv[1] + '" | juman | knp -simple | ./to_tree.py | ./toconstituents.py')

