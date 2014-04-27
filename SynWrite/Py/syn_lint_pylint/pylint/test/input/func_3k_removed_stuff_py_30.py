"""test relative import
"""
__revision__ = list(map(*(str, (1, 2, 3))))


from . import func_w0302

def function():
    """something"""
    print(func_w0302)
    unic = "unicode"
    low = unic.looower
    return low


