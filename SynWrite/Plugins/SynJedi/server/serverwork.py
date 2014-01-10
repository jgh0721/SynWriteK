import sys
import os
import logging
import errno

sys.path.append(os.path.dirname(__file__))
import jedi

S_ERROR = '[error]\n'
S_RESULT = '[result]\n'

#------------------------
_fn = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'path.ini')
if os.path.isfile(_fn):
    with open(_fn, 'r') as f:
        paths = f.readline().split(os.pathsep)
        sys.path.extend(paths)
        print('Paths:\n' + '\n'.join(paths))

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

#------------------------
def handle_autocomplete(send_data, fn, row, col):
    text = file_text(fn)
    if not text:
        return

    try:
        script = jedi.Script(text, row, col, fn)
        completions = script.complete()
    except:
        completions = None
        logging.error('Exception in Jedi')

    if not completions:
        dataT = S_ERROR + 'No results'
    else:
        dataT = S_RESULT
        for c in completions:
            desc = c.description.split(':')[0]
            pars = '( )' if desc == 'function' else ''
            dataT += c.name + '|' + desc + '|' + pars + '\n'
        logging.debug('Sent reply')

    send_data(dataT)

#--------------------
def handle_funchint(send_data, fn, row, col):
    text = file_text(fn)
    if not text:
        return

    try:
        script = jedi.Script(text, row, col, fn)
        sign = script.call_signatures()
    except:
        sign = None
        logging.error('Exception in Jedi');

    if not sign:
        dataT = S_ERROR + 'No results'
    else:
        dataT = S_RESULT
        for s in sign:
            parlist = [p.get_code().replace('\n', '') for p in s.params]
            dataT += '(' + ', '.join(parlist) + ')' + '\n'
        logging.debug('Sent reply')

    send_data(dataT)

#------------------------
def handle_findid(send_data, fn, row, col):
    text = file_text(fn)
    if not text:
        return

    msg = S_ERROR + 'No results'
    try:
        script = jedi.Script(text, row, col, fn)
        defs = script.goto_assignments()
        if not defs:
            return

        d = defs[0]
        modfile = d.module_path
        msg = ''
        if not os.path.isfile(modfile):
            # second way to get symbol definitions
            defs = script.goto_definitions()
            if not defs:
                return

            d = defs[0]
            modfile = d.module_path # module_path is all i need?
            if not os.path.isfile(modfile):
                msg = S_ERROR + 'Cannot find file of module: ' + modfile
                logging.error(msg)
        else:
            msg = S_RESULT + '%s\n%d\n%d\n' % (modfile, d.line, d.column)
    except:
        msg = S_ERROR + 'Exception in Jedi'
        logging.error(msg);

    dataT = msg
    send_data(dataT)
