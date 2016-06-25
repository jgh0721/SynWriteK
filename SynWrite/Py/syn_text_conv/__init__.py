#Author: Alex (Synwrite)
#License MIT

import os
from sw import *

dir_conv = os.path.join(app_exe_dir(), 'Data', 'conv')
ext_conv = '.txt'

fn_encode1 = 'HTML - all entities.txt'
fn_encode2 = 'HTML - entities except brackets.txt'

def do_conv(fn, is_back):
    nstart, nlen = ed.get_sel()
    is_all = nlen==0
    if is_all:
        text = ed.get_text_all()
    else:
        text = ed.get_text_sel()
    if not text: return
        
    text_conv = text_convert(text, fn, is_back)
    if not text_conv:
        msg_status('Cannot convert text (bad filename?)')
        return
    if text_conv==text:
        msg_status('Converter didn\'t change text')
        return

    if is_all:
        ed.set_caret_pos(0)
        ed.set_text_all(text_conv)
    else:            
        ed.set_caret_pos(nstart)
        ed.replace(nstart, nlen, text_conv)
        
    name = os.path.basename(fn)
    name = name[:name.find('.')]           
    msg_status('Converted using "%s"' % name)


def do_menu():
    fnames = os.listdir(dir_conv)
    fnames = [os.path.join(dir_conv, fn) for fn in fnames if fn.endswith(ext_conv)]

    items = []
    for fn in fnames:
        title = os.path.basename(fn)
        title = title[:title.find('.')]
        if title.endswith('_'):
            items += [ (fn, title[:-1], False) ]
        else:
            items += [ (fn, title+' -- encode', False) ]
            items += [ (fn, title+' -- decode', True) ]
            
    n = dlg_menu(MENU_SIMPLE, 'Text converters', '\n'.join([s[1] for s in items]))
    if n is None: return

    fn = items[n][0]
    is_back = items[n][2]
    return (fn, is_back)


class Command:
    def run_menu(self):
        res = do_menu()
        if res:
            fn, is_back = res
            do_conv(fn, is_back)

    def run_encode1(self):
        fn = os.path.join(dir_conv, fn_encode1)
        do_conv(fn, False)
         
    def run_encode2(self):
        fn = os.path.join(dir_conv, fn_encode2)
        do_conv(fn, False)
