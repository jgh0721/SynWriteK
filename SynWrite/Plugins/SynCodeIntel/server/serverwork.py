import sys
import os
import io
import logging
import errno

sys.path.append(os.path.join(os.path.dirname(__file__), 'arch'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'libs'))

from codeintel2.manager import Manager
from codeintel2.common import CodeIntelError, LogEvalController
from codeintel2.environment import SimplePrefsEnvironment

S_ERROR = '[error]\n'
S_RESULT = '[result]\n'
TIMEOUT = 4000

_fn = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'path.ini')
if os.path.isfile(_fn):
    with open(_fn, 'r') as f:
        paths = f.readline()
print 'Paths:\n' + '\n'.join(paths.split(os.pathsep))

d = {}
d['phpExtraPaths'] = paths
d['pythonExtraPaths'] = paths
d['perlExtraPaths'] = paths
d['javascriptExtraPaths'] = paths
d['rubyExtraPaths'] = paths
env = SimplePrefsEnvironment(**d)

mgr = Manager()
mgr.upgrade()
mgr.initialize()

#------------------------
def file_text(fn):
    try:
        with open(fn, 'r') as f:
            text = f.readlines()
        return ''.join(text)
    except IOError as e:
        if e.errno == errno.ENOENT: # No such file or directory
            logging.error(e.strerror + ': "' + fn + '"')
        else:
            logging.error(e.strerror)
        return None

# don't use standard open(), it ignores \r\n line ends
def file_pos(fn, row, col):
    n = 0
    with io.open(fn, 'rt', newline='') as f:
        lines = f.readlines()
    for i in range(row - 1):
        n += len(lines[i])
    n += col
    return n

#------------------------
def handle_autocomplete(send_data, fn, row, col):
    try:
        buf = mgr.buf_from_path(fn, lang=None, env=env)
        buf.scan()

        _pos = file_pos(fn, row, col)
        trg = buf.trg_from_pos(_pos)
        if not trg:
            dataT = S_ERROR + 'Cannot parse position'
            send_data(dataT)
            return

        result = buf.cplns_from_trg(trg, TIMEOUT)
        if result:
            dataT = S_RESULT
            # print auto-completions (2-tuples)
            is_php = buf.lang == "PHP"
            for s1, s2 in result:
                # correct variables names, they aren't returned with leading "$"
                if is_php and (s1 == "variable") and (not s2.startswith("$")):
                    s2 = "$" + s2
                pars = "( )" if s1 == "function" else ""
                dataT += s2 + "|" + s1 + "|" + pars + "\n"
        else:
            dataT = S_ERROR + 'No results'
        send_data(dataT)

    except Exception, e:
        dataT = S_ERROR + 'Exception in CodeIntel: ' + str(e)
        send_data(dataT)

#--------------------
def handle_funchint(send_data, fn, row, col):
    try:
        buf = mgr.buf_from_path(fn, lang=None, env=env)
        buf.scan()

        _pos = file_pos(fn, row, col)
        trg = buf.trg_from_pos(_pos)
        if not trg:
            dataT = S_ERROR + 'Cannot parse position'
            send_data(dataT)
            return

        result = buf.calltips_from_trg(trg, TIMEOUT)
        if result:
            dataT = S_RESULT
            for s in result:
                # cut string after CR
                n1 = s.find('\n')
                if n1 >= 0:
                    s = s[:n1]
                # cut string before "("
                n1 = s.find('(')
                if n1 >= 0:
                    s = s[n1:]
                # cut string after ")"
                n2 = s.rfind(')')
                if n2 >= 0:
                    s = s[:n2+1]
                # output string only if it has "(" and ")"
                if (n1 >= 0) and (n2 >= 0):
                    dataT += s + '\n'
        else:
            dataT = S_ERROR + 'No results'
        send_data(dataT)

    except Exception, e:
        dataT = S_ERROR + 'Exception in CodeIntel: ' + str(e)
        send_data(dataT)

#------------------------
def handle_findid(send_data, fn, row, col):
    try:
        buf = mgr.buf_from_path(fn, lang=None, env=env)
        buf.scan()

        _pos = file_pos(fn, row, col)
        trg = buf.defn_trg_from_pos(_pos)
        if not trg:
            dataT = S_ERROR + 'Cannot parse position'
            send_data(dataT)
            return

        logger = logging.getLogger("CodeIntel")
        ctlr = LogEvalController(logger)
        defs = buf.defns_from_trg(trg, TIMEOUT, ctlr)
        if defs:
            d = defs[0]
            if d.path:
                dataT = S_RESULT + '%s\n%d\n%d\n' % (d.path, d.line, 0)
            else:
                dataT = S_ERROR + 'Cannot find filename for "%s"' % d.name
        else:
            dataT = S_ERROR + 'No results'
        send_data(dataT)

    except Exception, e:
        dataT = S_ERROR + 'Exception in CodeIntel: ' + str(e)
        send_data(dataT)

#------------------------
