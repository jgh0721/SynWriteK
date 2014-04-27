#
# Linter for xmllint for Windows:
# http://code.google.com/p/xmllint/
#
# Author: Alexey (SynWrite)
#

import os
from SublimeLinter.lint import Linter, util

class XmlLint(Linter):

    syntax = 'XML'
    cmd = (os.path.join(os.path.dirname(__file__), 'xmllint.exe'), )

    regex = (
        r'^.+?: .+?: (?P<message>.+?) Line (?P<line>\d+), position (?P<col>\d+)'
    )
    multiline = True
    error_stream = util.STREAM_STDOUT
    tempfile_suffix = 'xml'
