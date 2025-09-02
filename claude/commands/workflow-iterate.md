# repository num_iterations task_desc

Create an iterative implementation using sequential data-engineer and code-reviewer subagents that cycle between worker and reviewer to iteratively improve the solution.

## Usage

```
/iterate $ARGUMENTS
```

## Description

This command creates a single git worktree where Claude will implement a task through iterative cycles of work and review. A data-engineer subagent performs the initial work, then a code-reviewer subagent reviews and provides feedback, then the data-engineer incorporates the feedback, and so on for the specified number of iterations.

## Examples

```
/iterate 3 Refactor the authentication system to use JWT tokens

/iterate 5 Add comprehensive data package testing

/iterate 2 Optimize the database queries for better performance
```

## Tree Diagram of Example Folder Structure
  parent-directory/
  ├── analytics-platform/                           # Main repository
  │   ├── .git/
  │   ├── src/
  │   ├── package.json
  │   └── ... (other project files)
  │
  └── analytics-platform.worktrees/                 # Worktrees folder
      └── iterate-20250116-143022/                  # Single iterative worktree
          ├── .git                                  # (file pointing to main repo)
          ├── src/
          ├── package.json
          ├── ITERATION_LOG.md                      # Track of iterations and feedback
          └── ... (iteratively improved files)

## What happens

1. Creates a single git worktree from the current commit
2. For each iteration cycle:
   1. **Worker Phase**: Data-engineer subagent implements/improves the task
   2. **Review Phase**: Code-reviewer subagent reviews the work and provides feedback
   3. **Documentation**: Both phases are logged to ITERATION_LOG.md
3. Each iteration builds on the previous work and feedback
4. Final implementation is left uncommitted for review
5. User can review the complete iteration history and final result

## Implementation

Instead of using MCP tools, follow these steps:
1. Get current commit: `git rev-parse HEAD`
2. Generate session ID: `iterate-$(date +%Y%m%d-%H%M%S)`
3. Get repository name: `basename "$(pwd)"`
4. Create single worktree: `git worktree add ../<repo-name>.worktrees/<session-id> -b <session-id>`
5. Create ITERATION_LOG.md to track progress
6. For each iteration (1 to num_iterations):
   - **Worker Phase**: Execute task with context from previous iterations
   - **Review Phase**: Review current state and provide improvement feedback
   - **Log Phase**: Document the iteration results and feedback in ITERATION_LOG.md
7. Leave final changes uncommitted for review
8. Present summary of all iterations and final result

## Iteration Log Format

Each iteration will be documented in ITERATION_LOG.md with:
- Iteration number
- Worker phase summary (what was implemented/changed)
- Reviewer phase feedback (what should be improved)
- Files modified in this iteration
- Timestamp

## Next steps

After running this command:
- Check worktree status with `git worktree list`
- Navigate to the worktree to review the final implementation
- Review ITERATION_LOG.md to understand the evolution of the solution
- Test and validate the final implementation
