#
# linter.py
# Linter for SublimeLinter3, a code checking framework for Sublime Text 3
#
# Written by NotSqrt
# Copyright (c) 2013 NotSqrt
#
# License: MIT
#

"""This module exports the Cpplint plugin class."""

import os
import sys
from io import TextIOWrapper, BytesIO
import tempfile

from SublimeLinter.lint import PythonLinter, util


class Cpplint(PythonLinter):

    """Provides an interface to cpplint."""

    syntax = ('C', 'C++')
    cmd = 'cpplint@python'

    regex = r'^.+:(?P<line>\d+):\s+(?P<message>.+)'
    tempfile_suffix = '.cpp'
    defaults = {
        '--filter=,': '',
    }
    comment_re = r'\s*/[/*]'
    inline_settings = None
    inline_overrides = 'filter'
    module = 'syn_lint_cpplint.cpplint'
    check_version = True

    def split_match(self, match):
        """
        Extract and return values from match.

        We override this method so that the error:
            No copyright message found.
            You should have a line: "Copyright [year] <Copyright Owner>"  [legal/copyright] [5]
        that appears on line 0 (converted to -1 because of line_col_base), can be displayed.

        """

        match, line, col, error, warning, message, near = super().split_match(match)

        if line is not None and line == -1 and message:
            line = 0

        return match, line, col, error, warning, message, near

    def check(self, code, filename):
        """
        Run a built-in check of code, returning errors.

        """

        old_stderr = sys.stderr
        sys.stderr = TextIOWrapper(BytesIO(), sys.stderr.encoding)

        f = None

        try:
            with tempfile.NamedTemporaryFile(suffix=self.tempfile_suffix, delete=False) as f:
                if isinstance(code, str):
                    code = code.encode('utf-8')

                f.write(code)
                f.flush()

            self.module.ProcessFile(f.name, 0)

        finally:
            if f:
                os.remove(f.name)

            sys.stderr.seek(0)
            output = sys.stderr.read()

            sys.stderr.close()
            sys.stderr = old_stderr

            return output

        return ''
