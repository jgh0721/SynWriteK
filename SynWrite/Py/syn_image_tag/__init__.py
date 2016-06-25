import os
from sw import *
from .imgsize import get_image_size

css_names = ('CSS', 'Style sheets', 'SCSS', 'SASS', 'Sass', 'Stylus')
_filter = 'Images (jpeg, png, gif)|*.jpg;*.jpeg;*.png;*.gif|'
ini_fn = os.path.join(app_ini_dir(), 'SynHistory.ini')
ini_section = 'Plugins'
ini_keydir = 'ImageTagDir'

def get_text(fn, sizex, sizey):
    lex = ed.get_prop(PROP_LEXER_CARET)
    eol = ed.get_prop(PROP_EOL)
    indent_size = ed.get_prop(PROP_TAB_SIZE)
    indent_sp = ed.get_prop(PROP_TAB_SPACES)
    indent = ' '*indent_size if indent_sp else '\t'
    
    #consider image is in file's subfolder
    ed_fn = ed.get_filename()
    if ed_fn:
        path = os.path.dirname(ed_fn) + os.sep
        if fn.startswith(path):
            fn = fn[len(path):]
        else:
            fn = '?/' + os.path.basename(fn)
    else:
        fn = '?/' + os.path.basename(fn)
    
    fn = fn.replace('\\', '/')
    
    if lex in css_names:
        return \
          indent + 'background: url("%s");' % fn + eol + \
          indent + 'width: %dpx;' % sizex + eol + \
          indent + 'height: %dpx;' % sizey + eol
    else:
        return '<img src="%s" width="%d" height="%d" alt="untitled" />' % (fn, sizex, sizey)

def get_filename():
    folder = ini_read(ini_fn, ini_section, ini_keydir, '')
    fn = dlg_file(True, '', folder, _filter)
    if fn:
        ini_write(ini_fn, ini_section, ini_keydir, os.path.dirname(fn))
        return fn

class Command:
    def run(self):
        fn = get_filename()
        if not fn: return
        dim = get_image_size(fn)
        if dim is None:
            msg_box(MSG_WARN, 'Cannot detect image file:\n%s' % fn)
            return
         
        x, y = dim   
        #print('Image file: %s, %d x %d' % (fn, x, y))
        text = get_text(fn, x, y)
        if not text: return
        
        pos_offset = text.find('"')+1
        pos_caret = ed.get_caret_pos()
        
        ed.insert(text)
        ed.set_caret_pos(pos_caret + pos_offset)
        msg_status('Image info inserted')
