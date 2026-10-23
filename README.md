# neaz-dev-skills

Two [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code.

| Skill | What it does |
|---|---|
| [`plan-and-delegate`](skills/plan-and-delegate/SKILL.md) | Claude plans a feature (requirements, design, small self-contained task files), hands each task to another coding CLI (Cursor by default; Codex, Gemini or agy optional), then reviews the diff and runs up to 2 fix rounds. |
| [`solid-code`](skills/solid-code/SKILL.md) | Applies SOLID and clean-code practices when writing, refactoring, or reviewing code, scaled to the size of the code so it doesn't over-engineer. Includes React rules (no unnecessary `useEffect`, SPA architecture). |

## Install

### As a Claude Code plugin (recommended)

In Claude Code:

```
/plugin marketplace add Neaz-Mahmood/neaz-dev-skills
/plugin install neaz-dev-skills@neaz-dev-skills
```

### Manually

Copy the skill folders into your personal skills directory (or `.claude/skills/` in a project):

```bash
git clone https://github.com/Neaz-Mahmood/neaz-dev-skills.git
cp -r neaz-dev-skills/skills/* ~/.claude/skills/
```

## Usage

Skills trigger on their own when a request matches. You can also call them by name:

- `/plan-and-delegate add CSV export to the reports page --provider codex`
- `/solid-code review src/orders/processor.py`

### plan-and-delegate requirements

You need at least one implementer CLI installed and logged in:

| Provider | CLI | Install |
|---|---|---|
| `cursor` (default) | `cursor-agent` | https://cursor.com/cli |
| `codex` | `codex` | `npm i -g @openai/codex` |
| `gemini` | `gemini` | `npm i -g @google/gemini-cli` |
| `agy` | `agy` | [Antigravity CLI](https://antigravity.google) (edits files only; Claude installs and verifies) |

The implementer runs with auto-approved edits (`--force`, `--full-auto`, `--yolo`), so use it in a git repo where you can review and revert changes. Plans and task files are written to `<project>/.claude/delegate/<feature>/`. The skill never commits or pushes.

### Does plan-and-delegate save Claude tokens?

**Not in our tests.** Delegating cost more Claude usage than letting Claude build the feature alone, added up to millions of implementer tokens on top, and took much longer (4–9× on the landing page). Code quality came out about the same.

Each run gave headless `claude -p` (Claude Opus 5.5) the same feature spec in a fresh copy of the project, either on its own or as `/plan-and-delegate --provider <cursor|agy>` with the plan pre-approved. The implementer CLIs used their default models. A separate grader the agents never saw checked every result. October 2026.

**Animated landing page** (React + Vite + GSAP + React Three Fiber, built from an empty repo; 4 runs per setup):

| Setup | Claude cost (avg, range) | Implementer tokens (avg) | Time (avg) | Runs that finished |
|---|---|---|---|---|
| Claude alone | **$1.50** ($1.15–$2.16) | none | **11 min** | 4 of 4 |
| plan-and-delegate + agy | $1.96 ($1.55–$2.45) | 4.3M | 41 min | 4 of 4 |
| plan-and-delegate + Cursor | $2.61 ($2.39–$2.84) | 7.7M | 95 min | 2 of 4 |

The grader built each page and loaded it in headless Chromium. It checked the section order, that the 3D scene animates, the pinned scroll-scrubbed showcase, 375px layout, reduced motion, console errors and the README. Every finished run passed every check except one: the scroll-triggered card reveal failed in 2 of the 4 runs of Claude alone and 2 of the 4 agy runs, and we didn't find the cause. The table's Cursor figures cover only the 2 finished runs. The other 2 stopped when Cursor hung on a task until the 20-minute timeout ($1.46 and $1.65 of Claude usage spent by then). Cursor had started a dev server that never exits. `delegate.sh` has since been fixed: implementers are told not to start long-running commands, and a timeout now stops everything the implementer started.

**Small feature** (tags, due dates and CSV/JSON export for a ~100-line Node CLI; 2 runs per setup, graded by 15 hidden acceptance tests):

| Setup | Claude cost (avg) | Implementer tokens (avg) | Time | Hidden tests |
|---|---|---|---|---|
| Claude alone | **$0.41** | none | **1.4 min** | 15/15 both runs |
| plan-and-delegate + Cursor | $0.91 | 0.7M | 13–41 min* | 15/15 both runs |

\* The 41-minute run hit a hang in `delegate.sh` that has since been fixed.

**Why it costs more:** Claude still reads the codebase, writes a self-contained spec per task, and then reads every diff and runs the checks itself. Typing the code, the only part it hands off, is the cheap part. Each delegated task also makes the implementer rediscover the project from scratch. The review step does catch real bugs in the implementer's work, but Claude alone produced code that passed the same checks.

**Caveats:** this is a small sample (2–4 runs per setup), and the cost of Claude alone varied almost 2× between runs of the same spec. Implementer tokens are billed by Cursor or Google, not Anthropic, so the table doesn't price them. Larger features, a leaner review step or a different implementer model could change the result.

Use plan-and-delegate when you want a different model to write the code, or want Claude's review over another agent's work. Don't use it to save Claude usage.

## Evals

`skills/solid-code/evals/` holds test prompts and assertions for the skill-creator eval workflow.

## License

[MIT](LICENSE)
