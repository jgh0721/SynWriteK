"""Test for W0623, overwriting names in exception handlers."""

__revision__ = ''

def new_style():
    """Some exceptions can be unpacked."""
    try:
        pass
    except IOError as xxx_todo_changeme: # this is fine
        (errno, message) = xxx_todo_changeme.args # this is fine
        print(errno, message)
    except IOError as xxx_todo_changeme1: # W0623 twice
        (new_style, tuple) = xxx_todo_changeme1.args # W0623 twice
        print(new_style, tuple)

