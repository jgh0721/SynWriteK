import os
import webbrowser
from sw import *

fn_include = os.path.join(os.path.dirname(__file__), 'include.html')

def do_report(fn):
    with open(fn, 'w', encoding='utf8') as f:
        f.write('<html>\n')
        f.write('<head>\n')
        f.write('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n')
        f.write('<title>SynWrite key mapping</title>\n')
        f.write('</head>\n')
        f.write('<body>\n')
        f.write(open(fn_include).read())
        f.write('<table width="600">\n')
                  
        info = []
        list_cat = []
        n = 0
        while True:
            item = app_proc(PROC_GET_COMMAND, str(n))
            if item is None: break
            cmd = item[0]
            name = item[1]
            if cmd>0:
                if not name in list_cat:
                    list_cat += [name]
                info += [item]
            n += 1
          
        f.write('<p>\n')  
        for index_cat, item_cat in enumerate(list_cat):
            f.write('<a href="#c%d">%s</a> |\n' % (index_cat, item_cat))
        f.write('<p>\n')
        
        for index_cat, item_cat in enumerate(list_cat):
            f.write('<tr><td class="h" align="center" colspan=2> <a name="c%d">' % index_cat + item_cat + '</td></tr>\n')
            for item in info:
                if item[1]==item_cat:
                    name = item[2]
                    keys = item[3]
                    if item[4]:
                        keys += '<br>'+item[4]
                    f.write('<tr><td>'+name+'</td><td>'+keys+'</td></tr>\n')
        
        f.write('</table></body></html>')

class Command:
    def run(self):
        fn = os.path.join(os.getenv('temp'), 'SynWrite_key_mapping.html')
        do_report(fn)    
        webbrowser.open_new_tab('file://'+fn)
        msg_status('Browser opened')
