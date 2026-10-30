---
name: memory-adr-sync
description: Capture non-obvious engineering decisions, persistent project rules, constraints, and user preferences in project memory and architecture decisions. Use when starting or resuming project work, when the user specifies a lasting rule, or when an engineering choice should survive future sessions.
---

# Memory & Architecture Decision Sync

1. Before generating code in a new session, load `.codex/MEMORY.md` and relevant entries in `docs/decisions/` into the working context. Create the memory file if it does not exist.
2. Whenever the user specifies a persistent rule, append it to `.codex/MEMORY.md` or the appropriate category in `docs/decisions/`. Capture non-obvious engineering decisions, constraints, and user preferences.
3. Structure each entry as:
   - **Context**: Why the choice was made.
   - **Decision**: The hard rule or principle.
   - **Status**: Accepted.
4. Preserve the user's latest explicit rule when it conflicts with an older one. Mark the old decision superseded instead of silently keeping contradictory rules active.
5. Distinguish accepted design rules from implementation or verification status. Do not label an untested implementation complete or record a guess as a user preference.
