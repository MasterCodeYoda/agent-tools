"""The seed `version` command."""

from .. import __version__

NAME = "version"


def run(argv: list[str]) -> int:
    print(f"greeter {__version__}")
    return 0
