from sw import *
import sys
import os

sys.path.append(os.path.dirname(__file__))
from csscompressor import compress
import format_proc

format_proc.MSG = '[CSS Minifier] '
format_proc.INI = ''

def do_format(text):
    return compress(text)

class Command:
    def run(self):
        format_proc.run(do_format)
