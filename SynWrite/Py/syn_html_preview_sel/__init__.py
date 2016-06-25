#Author: Alexey T
#License: MIT

import os
import webbrowser
from sw import *

TEMP_FN = '_Synwrite_preview.html'

class Command:
    names = []
#    def __done__(self):
#        msg_box(MSG_INFO, str(self.names))
#        for fn in self.names:
#            if os.path.isfile(fn):
#                os.remove(fn)

    def run(self):
        text = ed.get_text_sel()
        if not text:
            msg_status('Text not selected')
            msg_box(BEEP_WARN)
            return
           
        fn = ed.get_filename()                  
        if fn:
            dir = os.path.dirname(fn)
        else:
            dir = os.getenv('temp')
        fn = os.path.join(dir, TEMP_FN)
        
        if os.path.isfile(fn):
            os.remove(fn)
        with open(fn, 'w') as f:
            f.write(text)
        if os.path.isfile(fn):
            self.names.append(fn)
            webbrowser.open_new_tab(fn)
            msg_status('Selection opened for preview')
