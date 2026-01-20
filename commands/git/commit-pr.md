---
allowed-tools: Bash(git checkout --branch:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(gh pr create:*)
description: Commit, push, and open a PR
---


## Your task

1. Create a new branch if on main
2. 1. Evalute user input, establish context, and commit changes by following all instructions in `commit.md`
3. Push the branch to origin
4. Create a pull request using `gh pr create`
5. You have the capability to call multiple tools in a single response. You MUST do all of the above in a single
   message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool
   calls.
