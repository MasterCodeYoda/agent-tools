# Debugging failing tests

Load when a test fails and you need structured diagnosis.

When a test fails, resist the urge to guess from the error message. Apply structured reasoning:

1. **Read the full test.** Understand every assertion — tests often check multiple conditions. The failing assertion may not be the most informative one.
2. **Distinguish the crash site from the root cause.** A `StackOverflowError` at line 185 doesn't mean line 185 is buggy — trace back to what caused the infinite recursion. An `AssertionError` on a return value means the bug is upstream.
3. **Trace the execution path.** Follow each function call from the test into production code to its actual definition. Don't assume behavior from names — `format()` might be shadowed by a module-level function, `equals()` might be overridden.
4. **Check the opposite hypothesis.** Before concluding you've found the bug, ask: "What if this code is correct and the issue is elsewhere?" Look for evidence that would refute your theory.

These principles are especially important for AI agents, who tend to pattern-match on error messages rather than tracing actual execution paths.

