#
# linter.py
# Linter for SublimeLinter3, a code checking framework for Sublime Text 3
#
# Written by NotSqrt
# Copyright (c) 2013 NotSqrt
#
# License: MIT
#

"""This module exports the Cppcheck plugin class."""

from SublimeLinter.lint import Linter, util


class Cppcheck(Linter):

    """Provides an interface to cppcheck."""

    syntax = ('C', 'C++')
    cmd = ('cppcheck', '--template=gcc', '--inline-suppr', '--quiet', '*', '@')

    regex = r'^.+:(?P<line>\d+):\s+(?P<message>.+)'
    error_stream = util.STREAM_BOTH  # linting errors are on stderr, exceptions like "file not found" on stdout
    tempfile_suffix = 'cpp'
    defaults = {
        '--std=,+': [],  # example ['c99', 'c89']
        '--enable=,': 'style',
    }
    inline_settings = 'std'
    inline_overrides = 'enable'

    comment_re = r'\s*/[/*]'
