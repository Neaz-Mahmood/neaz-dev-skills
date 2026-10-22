---
name: plan-and-delegate
description: Claude does the high-level feature planning (requirements, architecture, task breakdown), then hands each implementation task to another AI coding provider (Cursor CLI by default; Codex or Gemini CLI optional) and reviews the result. Use when the user says "plan and delegate", "plan this feature and let cursor/codex/gemini implement it", or asks to split planning (Claude) from implementation (another model/provider).
argument-hint: "<feature description> [--provider cursor|codex|gemini] [--model <model>] [--no-review]"
---

# Plan with Claude, implement with another provider

Claude owns **thinking**: understanding the codebase, designing the feature, cutting it into small tasks, and judging the output. The implementer provider owns **typing**: editing files for one well-specified task at a time.

## Arguments

Parse from the user's request (defaults in brackets):

- feature description (required; ask if missing)
- `--provider` [`cursor`]: `cursor` → `cursor-agent`, `codex` → `codex exec`, `gemini` → `gemini -p`
- `--model` [provider default]: passed through, e.g. `gpt-5`, `gemini-2.5-pro`. For cursor, `cursor-agent --list-models` shows options.
- `--no-review`: skip Claude's review/fix loop and just report

Before starting, check that the provider's CLI is installed (`command -v cursor-agent` etc.). If it is missing, tell the user how to install it and stop.

## Phase 1 — Plan (Claude only, no code edits)

1. Explore the codebase enough to plan concretely: read the project's CLAUDE.md/README, find the files, patterns, and conventions the feature touches, and the commands for lint/build/test.
2. Write the plan to `<project-root>/.claude/delegate/<feature-slug>/plan.md`:
   - **Goal**: one paragraph, plus acceptance criteria
   - **Design**: the approach, key decisions and why, and the data/API/UI shape
   - **Tasks**: an ordered list. Each task is small (roughly one PR-sized commit, about 1–5 files), independently verifiable, and names its dependencies.
   - **Verification**: the exact commands to run (lint, typecheck, tests, build)
3. Write one file per task, `task-01.md`, `task-02.md`, …, using the template below. The implementer sees **only** this file, so make it fully self-contained: name exact file paths, existing functions/components to reuse or mirror (with paths), conventions to follow, what NOT to touch, and how to verify.
4. Show the user the plan summary (goal, design bullets, task list) and **wait for approval** before delegating. Adjust the plan if they ask.

### Task file template

```markdown
# Task NN: <title>

## Context
<2–5 sentences: the feature, and where this task fits in it>

## Do
- <concrete change 1, with file path>
- <concrete change 2>

## Follow these existing patterns
- <path/to/similar-file.tsx> — <what to mirror>

## Do not
- Touch files outside: <list>
- Add dependencies, reformat unrelated code, or commit

## Done when
- <observable criterion>
- `<verify command>` passes
```

## Phase 2 — Delegate (one task at a time, in order)

For each task:

1. Snapshot the starting state. In a git repo, run `git status --porcelain` and `git diff --stat` so you can tell the implementer's changes apart from earlier ones. In a non-git directory, note the files the task should touch.
2. Run the implementer through the wrapper script `scripts/delegate.sh` in this skill's base directory. Run it in the background when it may take more than a couple of minutes:
   ```bash
   <this-skill-dir>/scripts/delegate.sh \
     --provider cursor --workdir <project-root> \
     --task <project-root>/.claude/delegate/<slug>/task-NN.md \
     [--model <model>]
   ```
   The script writes the provider's full output to `task-NN.log` next to the task file and prints its tail.
3. If the script exits non-zero (auth error, timeout, missing CLI), show the user the error and stop. Do not silently do the task yourself.

## Phase 3 — Review (skip with `--no-review`)

After each task:

1. Read the actual diff (`git diff`, or read the touched files). Don't trust the implementer's own summary.
2. Check the diff against the task's "Done when" and "Do not" sections and the plan's design. Run the verification commands.
3. If something is wrong, write `task-NN-fix-K.md`. It should be self-contained: what's wrong, file:line, the expected outcome. Delegate it the same way. Allow at most **2 fix rounds** per task.
4. If it is still failing after 2 rounds, stop and report to the user. Include what's wrong and offer to fix it directly with Claude or to re-plan the task.
5. Add a status line per task to `plan.md` (✅ done / ⚠️ needs attention).

Small nits (a typo, a missing import) may be fixed directly by Claude if the user agrees. Note each one in the report.

## Final report

Tell the user:
- each task's status and which provider/model did it
- verification results, with real command output for any failures
- deviations from the plan, and anything Claude fixed directly
- the path to the plan folder

Never commit or push unless the user asks.
