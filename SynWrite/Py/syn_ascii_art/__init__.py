from sw import *
import sys
import os

sys.path.append(os.path.dirname(__file__))
from pyfiglet import Figlet

ini_fn = os.path.join(os.path.dirname(__file__), 'ascii_art.ini')

class Command:
    op_font='slant'
    op_direction='auto'
    op_justify='auto'
    op_width='80'

    def ini_get(self):
        self.op_font = ini_read(ini_fn, 'op', 'font', self.op_font)
        self.op_direction = ini_read(ini_fn, 'op', 'direction', self.op_direction)
        self.op_justify = ini_read(ini_fn, 'op', 'justify', self.op_justify)
        self.op_width = ini_read(ini_fn, 'op', 'width', self.op_width)

    def ini_set(self):
        ini_write(ini_fn, 'op', 'font', self.op_font)
        ini_write(ini_fn, 'op', 'direction', self.op_direction)
        ini_write(ini_fn, 'op', 'justify', self.op_justify)
        ini_write(ini_fn, 'op', 'width', self.op_width)

    def render(self):
        self.ini_get()
        f = Figlet(font=self.op_font, direction=self.op_direction, justify=self.op_justify, width=int(self.op_width))
        text = dlg_input('Text:', '', '', '')
        if text:
            text = f.renderText(text)
            x, y = ed.get_caret_xy()
            if x > 0:
                ed.insert('\n')
            ed.insert(text)
            msg_status('Text inserted')

    def config_font(self):
        dir = os.path.join(os.path.join(os.path.dirname(__file__), 'pyfiglet'), 'fonts')
        dirs = os.listdir(dir)
        dirs = [d[:-4] for d in dirs if d.endswith('.flf')]
        num = dlg_menu(MENU_SIMPLE, 'Select font', '\n'.join(dirs))
        if num is None:
            return
        self.ini_get()
        self.op_font = dirs[num]
        msg_status('Selected font: '+self.op_font)
        self.ini_set()
        self.render()

    def config_all(self):
        self.ini_get()
        self.ini_set()
        if os.path.isfile(ini_fn):
            file_open(ini_fn)
        else:
            msg_box(MSG_ERROR, 'Cannot create ini file')
