"""Seed smoke tests. Each new command module is picked up by discovery automatically."""

from greeter.cli import discover, main


def test_help_exits_zero():
    assert main(["--help"]) == 0


def test_seed_has_version_command():
    assert "version" in discover()


def test_unknown_command_nonzero():
    assert main(["nope"]) == 2
