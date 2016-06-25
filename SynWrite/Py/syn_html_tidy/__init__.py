import os
import subprocess
import webbrowser
import sw_cmd
from sw import *

config_dir = os.path.join(os.path.dirname(__file__), 'configs')
fn_exe = os.path.join(os.path.dirname(__file__), 'tidy', 'tidy.exe')
menu_title = 'HTML Tidy'
help_url = 'http://www.htacg.org/tidy-html5/'


def do_run(command):
    si = subprocess.STARTUPINFO()
    si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    si.wShowWindow = subprocess.SW_HIDE
    subprocess.call(command, startupinfo=si)

def do_log_clear():
    app_log(LOG_SET_PANEL, LOG_PANEL_VALIDATE)
    app_log(LOG_CLEAR, '')

def do_log(fn_ed, fn_err):
    app_log(LOG_SET_REGEX, r'line (\d+) column (\d+) .+')
    app_log(LOG_SET_LINE_ID, '1')
    app_log(LOG_SET_COL_ID, '2')
    app_log(LOG_SET_NAME_ID, '0')
    app_log(LOG_SET_FILENAME, fn_ed)
    
    text = open(fn_err).read().split('\n')
    if not text: return
    for s in text:
        app_log(LOG_ADD, s)
        
    ed.focus()    
    ed.cmd(sw_cmd.cmd_ToggleFocusValidate)


def do_menu():
    l = os.listdir(config_dir)
    if not l: return
    l_full = [os.path.join(config_dir, s) for s in l]
    l_nice = [s[:s.find('.')] for s in l]
    n = dlg_menu(MENU_SIMPLE, menu_title, '\n'.join(l_nice))
    if n is None: return
    return l_full[n]


def do_tidy(validate_only):
    fn_ed = ed.get_filename()
    if not fn_ed:
        msg_status('Save file first')
        return
        
    if ed.get_prop(PROP_MODIFIED):
        file_save()

    if not validate_only:
        fn_cfg = do_menu()
        if not fn_cfg:
            return
                             
    dir_temp = os.getenv('temp')
    fn_out = os.path.join(dir_temp, 'TidyOut.txt')
    fn_err = os.path.join(dir_temp, 'TidyErr.txt')
    if os.path.isfile(fn_out):
        os.remove(fn_out)
    if os.path.isfile(fn_err):
        os.remove(fn_err)
    
    if validate_only:
        command = [fn_exe, '-file', fn_err, '-errors', '-quiet', fn_ed]
    else:
        command = [fn_exe, '-output', fn_out, '-config', fn_cfg, '-file', fn_err, '-quiet', fn_ed] 
    do_run(command)
    do_log_clear()
        
    if os.path.isfile(fn_err) and open(fn_err).read():
        msg_status('Tidy returned error')
        do_log(fn_ed, fn_err)
    elif os.path.isfile(fn_out):
        text = open(fn_out).read()
        if text:
            ed.set_text_all(text)
            msg_status('Tidy result inserted')
        else:
            msg_status('Tidy returned empty text')
    else:
        if validate_only:
            msg_status('Tidy shows OK result')
        else:
            msg_status('Tidy cannot handle this file')

    if os.path.isfile(fn_out):
        os.remove(fn_out)
    if os.path.isfile(fn_err):
        os.remove(fn_err)


class Command:
    def menu(self):
        do_tidy(False)

    def validate(self):
        do_tidy(True)

    def configs(self):
        subprocess.call(['Explorer.exe', config_dir])

    def web(self):
        webbrowser.open_new_tab(help_url)
