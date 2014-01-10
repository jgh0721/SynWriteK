# Implementation of socket server for autocompletion
# Authors: tbeu, Alexey T. (SynWrite)
#
# Python 2.x
# Usage: python.exe server.py [portNumber]

import os
import sys
import logging
import socket
import urlparse
from serverwork import *

# Use level = logging.DEBUG to debug socket communication
logging.basicConfig(level = logging.ERROR, format = '%(message)s')

HOST = 'localhost'
if len(sys.argv) == 2:
    PORT = int(sys.argv[1])
else:
    PORT = 11112
BUFSIZE = 4096
s = None
for res in socket.getaddrinfo(HOST, PORT, socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP, socket.AI_PASSIVE):
    af, socktype, proto, canondata, sa = res
    try:
        s = socket.socket(af, socktype, proto)
    except socket.error as msg:
        s = None
        continue
    try:
        logging.debug('Binding')
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(sa)
        logging.debug('Listening')
        s.listen(1)
    except socket.error as msg:
        logging.error(msg)
        s.close()
        s = None
        continue
    break

if s is None:
    logging.error('Could not open socket')
    sys.exit(1)

logging.error('Python server started')
logging.debug('Accepting')
conn, addr = s.accept()
logging.debug('Connected by %s', addr)

#------------------------
def send_data(dataT):
    conn.send(dataT)

#------------------------
def init_params(d):
    fn = ''
    row = 0
    col = 0
    try:
        fn = d['fn'][0]
        row = int(d['line'][0])
        col = int(d['column'][0])
        if col > 0:
            col -= 1
        return (fn, row, col)
    except KeyError:
        msg = 'No file name / row number / line number defined in query'
        logging.error(msg)
        return None


while True:
    dataR = conn.recv(BUFSIZE)
    if dataR:
        url = bytes.decode(dataR)
        logging.debug('Recv %s', url)
        query = urlparse.urlparse(url).query
        d = urlparse.parse_qs(query)
        try:
            action = d['action'][0]
        except KeyError:
            action = ''

        if action == 'autocomp':
            params = init_params(d)
            handle_autocomplete(send_data, *params)
        elif action == 'funchint':
            params = init_params(d)
            handle_funchint(send_data, *params)
        elif action == 'findid':
            params = init_params(d)
            handle_findid(send_data, *params)
        elif action == 'close':
            logging.debug('Closing')
            conn.close()
            s.close()
            sys.exit(0)
        elif action == 'noclose':
            conn.close()
            logging.debug('Accepting')
            conn, addr = s.accept()
            logging.debug('Connected by %s', addr)
        elif action == '':
            msg = 'Nil action processed'
            dataT = S_ERROR + msg
            send_data(dataT)
        else:
            msg = 'Unknown action defined in query: ' + action
            logging.error(msg)
            dataT = S_ERROR + msg
            send_data(dataT)
