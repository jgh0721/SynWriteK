import sys
import os
sys.path.append(os.path.dirname(__file__))
import jedi


def handle_autocomplete(text, fn, row, col):
    row += 1 #Jedi has 1-based
    script = jedi.Script(text, row, col, fn)
    completions = script.completions()
    if not completions: return
        
    text = ''
    for c in completions:
        desc = c.description.split(':')[0]
        pars = '( )' if desc == 'function' else ''
        if hasattr(c, 'params'):
            pars = '('+', '.join([p.name for p in c.params])+')'
        text += c.name + '|' + desc + '|' + pars + '\n'
    return text


def handle_goto_def(text, fn, row, col):
    row += 1 #Jedi has 1-based
    script = jedi.Script(text, row, col, fn)
    defs = script.goto_assignments()
    if not defs: return

    d = defs[0]
    modfile = d.module_path
    if modfile is None: return
    
    if not os.path.isfile(modfile):
        # second way to get symbol definitions
        defs = script.goto_definitions()
        if not defs: return

        d = defs[0]
        modfile = d.module_path # module_path is all i need?
        if modfile is None: return
        if not os.path.isfile(modfile): return

    return (modfile, d.line-1, d.column)



def handle_func_hint(text, fn, row, col):
    row += 1 #Jedi
    script = jedi.Script(text, row, col, fn)
    sign = script.call_signatures()
    if not sign: return
    
    res = []
    for s in sign:
        par = [p.get_code().replace('\n', '') for p in s.params]
        res += ['(' + ', '.join(par) + ')']
    return res
