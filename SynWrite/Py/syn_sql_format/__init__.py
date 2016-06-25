import sys
import os
import shutil
from sw import *
from . import format_proc

sys.path.append(os.path.dirname(__file__))
from . import sqlparse3 as sqlparse

format_proc.MSG = '[SQL Format] '
format_proc.INI = 'sql_format_options.py'

ini = os.path.join(os.path.dirname(__file__), 'sql_format_options.py')
ini0 = os.path.join(os.path.dirname(__file__), 'sql_format_options.sample.py')
if os.path.isfile(ini0) and not os.path.isfile(ini):
    shutil.copy(ini0, ini)

def opt():
    ini = format_proc.ini_filename()
    with open(ini) as f:
        text = f.read()
    return eval(text)

def do_format(text):
    return sqlparse.format(text, **opt() )

class Command:
    def config_global(self):
        format_proc.config_global()

    def config_local(self):
        format_proc.config_local()

    def run(self):
        format_proc.run(do_format)
