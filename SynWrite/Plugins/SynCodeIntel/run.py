import sys
import os
import time

PARAM_RESET = "-"
PARAM_DEBUG = "debug"
PARAM_HINT = "hint"

class Info(object):
    pass
info = Info()    
info.time = time.time()
info.timeout = 18 # timeout in sec

def log(s):
    if info.debug:
        print s

if len(sys.argv) < 2:
    log("Parameter (filename) needed")
    exit(0)
         
info.filename = sys.argv[1]
info.debug = (len(sys.argv) > 2) and (PARAM_DEBUG in sys.argv[2])
info.mode_hint = (len(sys.argv) > 2) and (PARAM_HINT in sys.argv[2])
log("File: " + info.filename)

if not info.filename == PARAM_RESET:
    if not os.path.isfile(info.filename):
        log("File not found")
        exit(0)        

_codeintel = os.path.dirname(__file__) # path to libs/arch folders
sys.path.insert(0, os.path.join(_codeintel, 'arch'))
sys.path.insert(0, os.path.join(_codeintel, 'libs'))
from codeintel2.manager import Manager
from codeintel2.environment import SimplePrefsEnvironment

if info.filename == PARAM_RESET:
    mgr = Manager()
    mgr.db.reset(False)
    print "[Msg]"
    print "CodeIntel database is reset"
    exit(0)

sys.path.append(os.path.basename(info.filename))
info.filepos = os.path.getsize(info.filename) # get end-of-file pos

mgr = Manager()

try:
    mgr.upgrade()
    mgr.initialize()
    
    #envdict = { 'env': [], 'pythonExtraPaths': [r'D:\T\Py_test\Inc', r'D:\T'] }
    #env = SimplePrefsEnvironment(**envdict)
    env = None
    
    log("Read file")
    buf = mgr.buf_from_path(info.filename, None, env)
    buf.scan()
    
    log("Get pos")
    trg = buf.trg_from_pos(info.filepos)
    if trg is None:
        print "[Msg]"
        print "Cannot parse given position"
        exit(0)
        
    if info.mode_hint:
        result = buf.calltips_from_trg(trg, info.timeout)
    else:
        result = buf.cplns_from_trg(trg, info.timeout)
         
    if result:
        print "[Res]"
        if info.mode_hint:
            # print parameter hints (strings)
            for s in result:
                # cut string after CR
                n1 = s.find('\n')
                if n1 >= 0:
                    s = s[:n1]
                # cut string before "("
                n1 = s.find('(')
                if n1 >= 0:
                    s = s[n1:]
                # cut string after ")"
                n2 = s.rfind(')')
                if n2 >= 0:
                    s = s[:n2+1]
                # output string only if it has "(" and ")"
                if (n1 >= 0) and (n2 >= 0):    
                    print s
        else:
            # print auto-completions (2-tuples)
            is_php = buf.lang == "PHP"
            for s1, s2 in result:
                # correct variables names, they aren't returned with leading "$"
                if is_php and (s1 == "variable") and (not s2.startswith("$")):
                    s2 = "$" + s2
                print s2 + "|" + s1 + "|"
    else:
        print "[Msg]"
        print "No results"

    mgr.finalize()
except Exception, e:
    print "[Msg]"
    print "Parsing error: " + str(e) 
                
info.time = time.time() - info.time
log("")               
log("Time: " + str(round(info.time, 1)) + "s")
