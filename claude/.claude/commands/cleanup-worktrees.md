# Clean up all git worktrees in the analytics-platform.worktrees/ directory.

## Usage

```
/cleanup-worktrees
```

## Description

This command removes all git worktrees that were created in the analytics-platform.worktrees/ directory, typically from voting workflows or other parallel implementation tasks. It safely prunes the worktrees from git and removes the directories.

## What happens

1. Lists all directories in analytics-platform.worktrees/
2. For each worktree directory:
   - Runs `git worktree remove` to properly unregister it
   - If that fails (e.g., worktree already removed), forcefully removes with `git worktree remove --force`
3. Runs `git worktree prune` to clean up any stale worktree references
4. Reports the number of worktrees cleaned up

## Safety features

- Only removes worktrees in the analytics-platform.worktrees/ directory
- Uses git's built-in worktree management commands for safe removal
- Prunes stale references to prevent git metadata issues
- Reports what was cleaned up for transparency

## Example output

```
Found 3 worktrees to clean up:
- Removing analytics-platform.worktrees/task-variant-1
- Removing analytics-platform.worktrees/task-variant-2  
- Removing analytics-platform.worktrees/optimization-attempt-1
✓ Successfully cleaned up 3 worktrees
```