from sw import *
import sys
import os
import webbrowser
import tempfile

sys.path.append(os.path.dirname(__file__))
from docutils.core import publish_string

fn_temp = os.path.join(tempfile.gettempdir(), 'rest_preview.html')


class Command:
    def run(self):
        text = ed.get_text_all()
        if not text: return

        text = publish_string(text, writer_name='html')
        text = text.decode('utf8') 

        with open(fn_temp, 'w') as f:
            f.write(text)

        if os.path.isfile(fn_temp):
            msg_status('Opening HTML preview...')
            webbrowser.open_new_tab(fn_temp)
        else:
            msg_status('Cannot convert text to HTML')
