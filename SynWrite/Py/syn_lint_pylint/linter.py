#
# linter.py
# Linter for SublimeLinter3, a code checking framework for Sublime Text 3
#
# Written by NotSqrt
# Copyright (c) 2013 NotSqrt
#
# Changes for SynWrite by Alexey Torgashin
#
# License: MIT
#

"""This module exports the Pylint plugin class."""

import sys
import os

sys.path.append(os.path.dirname(__file__))
from SublimeLinter.lint import PythonLinter, util

class Pylint(PythonLinter):
    """Provides an interface to pylint."""

    syntax = 'Python'
    module = 'syn_lint_pylint'
    cmd = None

    version_args = '--version'
    version_re = r'^pylint.* (?P<version>\d+\.\d+\.\d+),'
    version_requirement = '>= 1.0'
    regex = (
        r'^(?P<line>\d+):(?P<col>\d+):'
        r'(?:(?P<error>[RFE])|(?P<warning>[CIW]))\d+: '
        r'(?P<message>.*)'
    )
    multiline = True
    line_col_base = (0, -1)
    tempfile_suffix = '.py'
    error_stream = util.STREAM_STDOUT  # ignore missing config file message
    defaults = {
        '--disable=,': '',
        '--enable=,': '',
        '--rcfile=': ''
    }
    inline_overrides = ('enable', 'disable')
    check_version = True

    def split_match(self, match):
        """
        Return the components of the error message.
        We override this to deal with the idiosyncracies of pylint's error messages.
        """
        match, line, col, error, warning, message, near = super().split_match(match)
        if match:
            if col == 0:
                col = None
        return match, line, col, error, warning, message, near

    def check(self, code, filename):
        """Check method needed for this linter"""
        text = run_pylint(code)
        return text

#
# Helper functions
#

class WritableObject(object):
    def __init__(self):
        self.content = []
    def write(self, text):
        self.content.append(text)
    def read(self):
        return self.content


def run_pylint(code):
    # Clear cache
    from astroid import MANAGER
    MANAGER.astroid_cache.clear()

    from pylint import lint
    from pylint.reporters.text import TextReporter

    args = get_args()
    tempname = get_tempname(code)
    pylint_output = WritableObject()

    lint.Run([tempname]+args, reporter=TextReporter(pylint_output), exit=False)
    return pylint_output.read()

def get_tempname(code):
    import tempfile
    with tempfile.NamedTemporaryFile(suffix='.py', delete=False) as f:
        f.write(code.encode('ascii', 'replace')) # encode needed because file is binary
    return f.name

def get_args():
    rc = os.path.join(os.path.dirname(__file__), 'pylint.rc')
    args = [
           '--msg-template=\'{line}:{column}:{msg_id}: {msg}\'',
           '--module-rgx=.*',
           '--reports=n',
           '--persistent=n',
           '--rcfile=%s' % rc,
           ]
    return args
