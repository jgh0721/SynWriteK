import os
from sw import *
from .intel_work import *

offset_lines=5

def is_wordchar(s):
    return (s=='_') or s.isalnum()
    

class Command:
    def on_complete(self, ed_self):
        fn = ed.get_filename()
        x0, y0 = ed.get_caret_xy()

        line = ed.get_text_line(y0)
        if not 0 < x0 <= len(line): 
            return True        
        
        #calc len left
        x = x0
        while x>0 and is_wordchar(line[x-1]): x -= 1
        len1 = x0-x

        #calc len right
#        x = x0
#        while x<len(line) and is_wordchar(line[x]): x += 1
#        len2 = x-x0

#        print('len1', len1)
#        print('len2', len2)
        if len1<=0: return True
        
        text = ed.get_text_all()
        if not text: return True
        
        text = handle_autocomplete(text, fn, y0, x0)
        if not text: return True
        ed.complete(text, len1, True)
        return True
        
        
    def on_goto_def(self, ed_self):
        fn = ed.get_filename()
        x0, y0 = ed.get_caret_xy()

        line = ed.get_text_line(y0)
        if not 0 <= x0 <= len(line): 
            return
            
        text = ed.get_text_all()
        if not text: return True
        
        res = handle_goto_def(text, fn, y0, x0)
        if res is None: return True
        
        fn, y, x = res
        file_open(fn)
        ed.set_top(y-offset_lines) #must be
        ed.set_caret_xy(x, y)

        print('Goto "%s", line %d' % (fn, y+1))
        return True


    def on_func_hint(self, ed_self):
        fn = ed.get_filename()
        x0, y0 = ed.get_caret_xy()

        line = ed.get_text_line(y0)
        if not 0 < x0 <= len(line): 
            return ''
            
        text = ed.get_text_all()
        if not text: return ''
        
        res = handle_func_hint(text, fn, y0, x0)
        if not res: return ''
        
        text = '\n'.join(res)
        return text
        