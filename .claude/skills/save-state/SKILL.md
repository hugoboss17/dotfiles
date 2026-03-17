---
name: save-state
description: Save the current conversation state to memory so context is fully preserved when reopening Claude
---

Review our entire conversation and update this project's memory file (`MEMORY.md` inside the auto-memory directory) with a comprehensive snapshot of the current state. The goal is that when a new Claude session starts, it can read this file and pick up exactly where we left off without any re-explaining.

Update the memory file with the following sections, creating or replacing them as needed. Do not wipe unrelated existing memory — only update what's relevant to the current conversation.

Sections to write:

**## Project Overview** — What this project is, the stack, and its purpose (if not already accurate).

**## Current State** — What has been built or changed so far. Be specific: files created, configs added, decisions made.

**## In Progress** — What was actively being worked on at the time of this save. Include the specific task, any blockers, and next steps.

**## Key Decisions** — Important architectural or workflow decisions made during this project, with brief reasoning.

**## Conventions** — Patterns, naming conventions, or rules established for this project.

Be thorough. Assume the next Claude session has no memory of this conversation at all.
