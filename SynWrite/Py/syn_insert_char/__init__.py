from sw import *

class Command:
    def run(self):
        s = dlg_input('Unicode hex code:', '', '', '')
        if not s:
            return

        s = s.upper()
        if s.startswith('0X'):
            s = s[2:]

        if len(s) == 2:
            s = '00' + s

        if len(s) != 4:
            msg_status('Not valid hex code: ' + s)
            msg_box(BEEP_ERROR)
            return

        try:
            text = chr(int(s, 16))
        except:
            msg_status('Not valid hex code: ' + s)
            msg_box(BEEP_ERROR)
            return

        ed.insert(text)
        msg_status('Char inserted: U+' + s)
