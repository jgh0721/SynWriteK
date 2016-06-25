import sw
from sw import ed

class Command:
    def __init__(self):
        self.data_sep = ''
        
    def run(self):
        ''' Add spaces for align text in some lines
            Example. Start lines
                a= 0
                b
                c  = 1
            Aligned lines
                a  = 0
                b
                c  = 1
        '''
        line_start, \
        line_end= ed.get_sel_lines()
        if line_start==line_end:
            return sw.msg_status('Only for multiline selection')
        pSelBgn,    \
        nSelLen = ed.get_sel()
        spr     = sw.dlg_input('Enter separator string:', self.data_sep, '','')
        spr     = '' if spr is None else spr.strip()
        if not spr:
            return # Esc
        self.data_sep    = spr
        ls_txt  = ed.get_text_substr(pSelBgn, nSelLen)
        if spr not in ls_txt: 
            return sw.msg_status("No separator '{}' in selected lines".format(spr))
        lines   = ls_txt.splitlines()
        ln_poss = [(ln, ln.find(spr)) for ln in lines]
        max_pos =    max([p for (l,p) in ln_poss])
        if max_pos== min([p if p>=0 else max_pos for (l,p) in ln_poss]):
            return sw.msg_status('Text change not needed')
        nlines  = [ln       if pos==-1 or max_pos==pos else 
                   ln[:pos]+' '*(max_pos-pos)+ln[pos:]
                   for (ln,pos) in ln_poss]
        ed.replace(pSelBgn, nSelLen, '\n'.join(nlines)+'\n')  
        sw.msg_status('Selection aligned (%d lines)' % len(nlines))
        
        