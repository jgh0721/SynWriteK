#pylint: disable=W0401,W0611
"""check unexistant names imported are reported"""

__revision__ = None

import logilab.common.tutu
from logilab.common import toto
toto.yo()

from logilab.common import modutils
modutils.nonexistant_function()
modutils.another.nonexistant.function()
print(logilab.common.modutils.yo)

import sys
print('hello world', file=sys.stdout)
print('bye bye world', file=sys.stdoout)


import re
re.finditer('*', 'yo')

from rie import *
from re import findiiter, compiile

import os
'SOMEVAR' in os.environ

