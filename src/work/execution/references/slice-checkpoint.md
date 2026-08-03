# Story / slice / sub-issue completion checkpoint

**Load when:** a decomposition unit (story/slice or sub-issue/deliverable) finishes during
execute.

**Hard refuse:** do not batch unrelated decomposition units into one commit — commit each
story/slice or sub-issue/deliverable independently.

## Per unit

1. Implement end-to-end (vertical-slice) or comprehensively against owned ACs
   (deliverable-partition)  
2. Run full test suite  
3. **Domain quality verification** (when domain/pure logic changed) — load
   `quality-checkpoints.md` › Domain verification path:
   - mutation tool present → incremental mutate + kill real gaps (timeboxed), **or**
   - no tool → sabotage 3–5 critical paths and strengthen tests that miss, **or**
   - skip with one-line reason (no domain in diff / infra-only)  
   Record evidence in session notes or commit body (files, score/summary, or sabotage list).
4. Mark TodoWrite complete  
5. **Deliverable-partition only:** verify every **inherited verbatim parent AC** against
   test/CI evidence  
6. Commit: `feat(scope): description (ISSUE-ID)`  
7. Update PM story/sub-issue Done  
8. Next unit  

**Anti-patterns:** one big commit at the end; closing a sub-issue with a **paraphrased** AC
instead of the verbatim parent AC; green suite with **no** mutation/sabotage/skip evidence when
domain/pure logic changed; full-repo mutation as default.
