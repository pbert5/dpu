#!/usr/bin/env python
import os
import sys

if __name__ == "__main__":
    import collections
    import collections.abc
    import gettext
    import inspect

    for name in (
        "Callable",
        "Container",
        "Iterable",
        "Iterator",
        "Mapping",
        "MutableMapping",
        "Sequence",
    ):
        if not hasattr(collections, name):
            setattr(collections, name, getattr(collections.abc, name))
    if not hasattr(inspect, "getargspec"):
        inspect.getargspec = inspect.getfullargspec
    if "codeset" not in inspect.signature(gettext.translation).parameters:
        _translation = gettext.translation

        def translation(*args, **kwargs):
            kwargs.pop("codeset", None)
            return _translation(*args, **kwargs)

        gettext.translation = translation

    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "cloudevolution.settings")

    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)
