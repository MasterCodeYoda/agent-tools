"""taskcli — a tiny CLI task manager (swarm test-harness scenario seed).

The backlog builds this out: core model + store, then add/list, complete/delete,
search, and stats. The seed ships only the command registry, a dispatcher, and a
`version` command, plus a shared integration test the backlog items must keep green.
"""

__version__ = "0.0.1"
