#Author: Alexey T
#Licence: MIT

from sw import *

def str_get_indent(s):
	n = 0
	while (n<len(s)) and (s[n] in [' ', '\t']):
		n += 1
	return s[:n]
    
def str_indented(s, indent_add):
    if s:
        s = indent_add + s
    return s
  
class Command:
    def run(self):
        n1, n2 = ed.get_sel_lines()
        lines = [ed.get_text_line(i) for i in range(n1, n2+1)]
        if not lines: return
        
        indent = str_get_indent(lines[0])
        tab_spaces = ed.get_prop(PROP_TAB_SPACES)
        tab_size = ed.get_prop(PROP_TAB_SIZE)
        eol = ed.get_prop(PROP_EOL)
        indent_add = ' '*tab_size if tab_spaces else '\t'
        
        lines = [str_indented(s, indent_add) for s in lines]
        lines = [indent + '{'] + lines + [indent + '}']
        newtext = eol.join(lines) + eol
        
        nstart = ed.xy_pos(0, n1)
        nend = ed.xy_pos(0, n2+1)
        ed.set_caret_pos(nstart)
        ed.replace(nstart, nend-nstart, newtext)
        msg_status('Indented %d lines' % (n2-n1+1))
                
