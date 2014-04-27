"""find binary operations used as exceptions
"""

__revision__ = 1

try:
    __revision__ += 1
except Exception or Exception:
    print("caught1")
except Exception and Exception:
    print("caught2")
except Exception or Exception:
    print("caught3")
except (Exception or Exception) as exc:
    print("caught4")
