from sw import *
import os

def syn_py():
    return os.path.join(app_exe_dir(), 'Py')

def syn_plugins_ini():
    return os.path.join(app_exe_dir(), 'SynPlugins.ini')

def msg(id):
    return text_local(id, __file__)

class Command:

    def do_get_descs(self, dir):
        desc = []
        substr = '=py:' + os.path.basename(dir) + ';'
        with open(syn_plugins_ini(), 'r') as f:
            for line in f:
                if (substr in line) and not line.startswith(';'):
                    n = line.find('=')
                    if n >= 0:
                        desc.append(line[:n])
        for item in desc:
            n = item.find('\\')
            if n >= 0:
                desc = [item[:n]]
                break
        return desc

    def do_get_desc(self, dir):
        return os.path.basename(dir) + chr(9) + ', '.join(self.do_get_descs(dir))

    def do_menu(self, items, caption):
        names = [self.do_get_desc(dir) for dir in items]
        num = dlg_menu(MENU_DOUBLE, caption, '\n'.join(names))
        return num

    def do_unregister(self, pyname):
        fn_ini = syn_plugins_ini()
        fn_ini2 = syn_plugins_ini() + '.tmp'

        if os.path.isfile(fn_ini2):
            os.remove(fn_ini2)
        if os.path.isfile(fn_ini2):
            return False

        f = open(fn_ini, 'r')
        f2 = open(fn_ini2, 'w')
        substr = '=py:' + pyname + ';'
        for line in f:
            if not substr in line:
                f2.write(line)
        f2.close()
        f.close()

        if not os.path.isfile(fn_ini2):
            return False
        os.remove(fn_ini)
        os.rename(fn_ini2, fn_ini)
        if not os.path.isfile(fn_ini):
            return False
        return True

    def do_remove(self, pyname):
        dir_inst = os.path.join(syn_py(), pyname)
        dir_trash = os.path.join(syn_py(), '__trash')
        dir_dest = os.path.join(dir_trash, os.path.basename(dir_inst))
        while os.path.isdir(dir_dest):
            dir_dest += '_'

        if not os.path.isdir(dir_trash):
            os.mkdir(dir_trash)
        if not os.path.isdir(dir_trash):
            msg_box(MSG_ERROR, msg('CantCreTrash'))
            return False

        try:
            os.rename(dir_inst, dir_dest)
        except OSError:
            msg_box(MSG_ERROR, msg('CantMoveToTr'))
            return False
        return True

    def do_find(self):
        dir = syn_py()
        l = os.listdir(dir)
        l = [os.path.join(dir, fn) for fn in l if not fn.startswith('__')]
        l = [fn for fn in l if os.path.isdir(fn)]
        return l

    def menu_edit(self):
        items = self.do_find()
        num = self.do_menu(items, msg('MenuEdit'))
        if num is not None:
            fn = os.path.join(items[num], '__init__.py')
            if os.path.isfile(fn):
                file_open(fn)
            else:
                msg_box(MSG_ERROR, msg('CantFindFile') + '\n' + fn)

    def menu_remove(self):
        items = self.do_find()
        num = self.do_menu(items, msg('MenuRemove'))
        if num is not None:
            pyname = os.path.basename(items[num])
            if msg_box(MSG_CONFIRM, msg('CfmRemove') + '\n' + pyname):
                if self.do_unregister(pyname) and self.do_remove(pyname):
                    msg_box(MSG_INFO, msg('Removed'))
                else:
                    msg_box(MSG_ERROR, msg('CantRemove'))
