"""Suspicious str.strip calls."""
__revision__ = 1

''.strip('yo')
''.strip()

''.strip('http://')
''.lstrip('http://')
b''.rstrip('http://')
