from sw import *
import webbrowser

def do_search(text):
    url = 'http://devdocs.io/#q=' + text.replace(' ', '%20')
    msg_status('DevDocs: opened browser for "' + text + '"')
    webbrowser.open_new_tab(url)

class Command:
    def run_input(self):
        s = dlg_input('DevDocs search:', '', '', '')
        if s:
            do_search(s)
        else:
            msg_status('Input cancelled')

    def run_text(self):
        nstart, nlen = ed.get_sel()
        if nlen > 0:
            text = ed.get_text_substr(nstart, nlen)
            do_search(text)
        else:
            x, y = ed.get_caret_xy()
            nstart, nlen, text = ed.get_word(x, y)
            if not text:
                msg_status('DevDocs: need selected text')
                msg_box(BEEP_WARN, '')
            else:
                do_search(text)

