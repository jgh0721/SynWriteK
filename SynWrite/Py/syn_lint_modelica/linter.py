#
# linter.py
# Linter for SublimeLinter3, a code checking framework for Sublime Text 3
#
# Written by tbeu
# Copyright (c) 2014 tbeu
#
# License: MIT
#

"""This module exports the moparser plugin class."""

from SublimeLinter.lint import Linter, util


class Moparser(Linter):

    """Provides an interface to moparser."""

    syntax = 'Modelica'
    cmd = ('moparser', '-e', '@')

    regex = r'^.+ on line (?P<line>\d+).+:\s+(?P<message>.+)'
    tempfile_suffix = '.mo'
    error_stream = util.STREAM_STDOUT
