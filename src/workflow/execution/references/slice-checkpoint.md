# Story / slice / sub-issue completion checkpoint

**Load when:** a decomposition unit (story/slice or sub-issue/deliverable) finishes during
execute.

**Hard refuse:** do not batch unrelated decomposition units into one commit — commit each
story/slice or sub-issue/deliverable independently.

## Per unit

1. Implement end-to-end (vertical-slice) or comprehensively against owned ACs
   (deliverable-partition)  
2. Run full test suite  
3. Mark TodoWrite complete  
4. **Deliverable-partition only:** verify every **inherited verbatim parent AC** against
   test/CI evidence  
5. Commit: `feat(scope): description (ISSUE-ID)`  
6. Update PM story/sub-issue Done  
7. Next unit  

**Anti-patterns:** one big commit at the end; closing a sub-issue with a **paraphrased** AC
instead of the verbatim parent AC.
