import os
import string
from sw import *

fn_sample = os.path.join(os.path.dirname(__file__), 'sample.py')
fn_plugins_ini = os.path.join(app_ini_dir(), 'SynPlugins.ini')    

def is_module_name(name):
    if not name: return False
    chars = string.ascii_letters + string.digits + '_'
    for s in name:
        if not s in chars:
            return False
    return True 

class Command:
    def run(self):
        s = dlg_input_ex(2, 'New plugin', 
          'Lowercase module name, e.g. "my_sample"', 'sample',
          'Menu item caption', 'My Plugin')
        if s is None: return
        s_module = s[0]
        s_caption = s[1]
        
        if not s_module or not s_caption: return
        if not is_module_name(s_module):
            msg_box(MSG_ERROR, 'Incorrect module name: "%s"' % s_module)
            return

        s_module = 'syn_'+s_module
        dir_py = os.path.join(app_exe_dir(), 'Py')
        dir_plugin = os.path.join(dir_py, s_module)
        if os.path.isdir(dir_plugin):
            msg_box(MSG_ERROR, 'Cannot create plugin; folder already exists:\n' + dir_plugin)
            return
            
        try:
            os.mkdir(dir_plugin)
        except:
            msg_box(MSG_ERROR, 'Cannot create folder:\n' + dir_plugin)
            return
        
        fn_py = os.path.join(dir_plugin, '__init__.py')
        text = open(fn_sample).read()
        with open(fn_py, 'w') as f:
            f.write(text)
                  
        ini_write(fn_plugins_ini, 'Commands', s_caption, 'py:%s;run;' % s_module)
        
        fn_install_inf = os.path.join(dir_plugin, 'install.inf')
        fn_sample_inf = os.path.join(os.path.dirname(__file__), 'sample.inf')
        text = open(fn_sample_inf).read()
        text = text.replace('{subdir}', s_module).replace('{menuitem}', s_caption)
        with open(fn_install_inf, 'w') as f:
            f.write(text)
        
        file_open(fn_py)
        msg_box(MSG_INFO, 'Plugin was created. Menu item "Plugins - %s" will appear after restart of program.' % s_caption)
