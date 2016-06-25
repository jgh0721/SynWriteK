from sw import *
import sys
import os
import shutil

INI = 'jsformat.cfg'
MSG = '[JS Format] '

def ini_global():
    return os.path.join(os.path.dirname(__file__), INI)

def ini_local():
    fn = ed.get_filename()
    if fn:
        return os.path.join(os.path.dirname(fn), INI)
    else:
        return ''

def ini_filename():
    ini_g = ini_global()
    ini_l = ini_local()
    if os.path.isfile(ini_l):
        return ini_l
    else:
        return ini_g

def config_global():
    ini = ini_global()
    if os.path.isfile(ini):
        file_open(ini)
    else:
        msg_box(MSG_ERROR, 'Global config file "%s" not found' % INI)

def config_local():
    if not ed.get_filename():
        msg_box(MSG_ERROR, 'Cannot open local config file for untitled tab')
        return
    ini = ini_local()
    ini0 = ini_global()
    if os.path.isfile(ini):
        file_open(ini)
        return
    if not os.path.isfile(ini0):
        msg_box(MSG_ERROR, 'Global config file "%s" not found' % INI)
        return
    if msg_box(MSG_CONFIRM, 'Local config file "%s" not found.\nDo you want to create it?' % INI):
        shutil.copyfile(ini0, ini)
        if os.path.isfile(ini):
            file_open(ini)
        else:
            msg_box(MSG_ERROR, 'Cannot copy global config file "%s" to local folder' % INI)


def run(do_format):
    if ed.get_sel_mode() != SEL_NORMAL:
        msg_status(MSG + "Column/line selections not supported")
        msg_box(BEEP_ERROR)
        return
    nstart, nlen = ed.get_sel()
    if nlen > 0:
        text = ed.get_text_sel()
        text = do_format(text)
        if text:
            msg_status(MSG + "Formatting selected text")
            ed.set_caret_pos(nstart)
            ed.replace(nstart, nlen, text)
        else:
            msg_status(MSG + "Cannot format selected text")
    else:
        text = ed.get_text_all()
        text = do_format(text)
        if text:
            msg_status(MSG + "Formatting entire text")
            ed.set_caret_xy(0, 0)
            ed.set_text_all(text)
        else:
            msg_status(MSG + "Cannot format entire text")
