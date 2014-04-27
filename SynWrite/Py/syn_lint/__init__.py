import sys
import os
import sw
import sw_cmd

sys.path.append(os.path.dirname(__file__))
from SublimeLinter.lint.linter import linter_classes

class Command:
    def __init__(self):
        dir = os.path.join(sw.app_exe_dir(), 'Py')
        dirs = os.listdir(dir)
        dirs = [name for name in dirs if name.startswith('syn_lint_') and os.path.isdir(os.path.join(dir, name))]
        for lint in dirs:
            try:
                __import__(lint + '.linter', globals(), locals(), [lint + '.linter'])
            except ImportError:
                pass

    def do_lint(self, editor, show_panel=False):
        lexer = editor.get_prop(sw.PROP_LEXER_FILE)
        for linterName in linter_classes:
            Linter = linter_classes[linterName]

            if isinstance(Linter.syntax, (tuple, list)):
                match = lexer in Linter.syntax
            else:
                match = lexer == Linter.syntax

            if match:
                if not Linter.disabled:
                    linter = Linter(editor)
                    error_count = linter.lint()
                    if error_count > 0:
                        if show_panel:
                            sw.ed.focus()
                            sw.ed.cmd(sw_cmd.cmd_ToggleFocusValidate)
                            sw.ed.focus()
                        sw.msg_status('Linter "%s" found %d error(s)' % (linter.name, error_count))
                    else:
                        if show_panel:
                            sw.msg_status('Linter "%s" found no errors' % linter.name)
                    return
        else:
            if show_panel:
                sw.msg_status('No linters installed for "%s"' % lexer)
                sw.msg_box(sw.BEEP_INFO)

    def on_open(self, ed_self):
        self.do_lint(ed_self)

    def on_save(self, ed_self):
        self.do_lint(ed_self)

    def on_change_slow(self, ed_self):
        self.do_lint(ed_self)

    def run(self):
        self.do_lint(sw.ed, True)
