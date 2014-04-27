#
# linter.py
# Linter for SublimeLinter3, a code checking framework for Sublime Text 3
#
# Written by Aparajita Fishman
# Copyright (c) 2013 Aparajita Fishman
#
# License: MIT
#

"""This module exports the HtmlTidy plugin class."""

import os
from SublimeLinter.lint import Linter, util


class HtmlTidy(Linter):

    """Provides an interface to tidy."""

    syntax = 'HTML documents'
    cmd = (os.path.join(os.path.dirname(__file__), 'tidy'),
      '-errors', '-quiet', '-utf8')

    regex = r'^line (?P<line>\d+) column (?P<col>\d+) - (?:(?P<error>Error)|(?P<warning>Warning)): (?P<message>.+)'
    error_stream = util.STREAM_STDERR
