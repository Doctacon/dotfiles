---
allowed-tools: Bash, Read
description: Load context for a new agent session by analyzing the analytics-platform codebase structure and documentation
---

# Prime

This command loads essential context for a new agent session by examining the analytics-platform repository structure and reading the project documentation.

## Instructions
- Understand that the current working directory is a parent folder containing:
  - `analytics-platform/` - The main git repository
  - `analytics-platform.worktrees/` - Git worktree folder for parallel development
- Navigate to the analytics-platform directory and examine its structure
- Read the CLAUDE.md and README.md to understand the project purpose and setup
- Provide a concise overview of the Harness DataOps Platform

## Context
- Parent folder structure: !`ls -la`
- Analytics platform structure: !`ls analytics-platform | head -20`
- Project documentation: @analytics-platform/CLAUDE.md
- Project README: @analytics-platform/README.md
- Repository tree view: !`ls -la analytics-platform/workspaces`

When you finish run the tts summary agent, and let the user know you're ready to build.
