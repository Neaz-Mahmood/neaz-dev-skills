# neaz-dev-skills

Two [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code.

| Skill | What it does |
|---|---|
| [`plan-and-delegate`](skills/plan-and-delegate/SKILL.md) | Claude plans a feature (requirements, design, small self-contained task files), hands each task to another coding CLI (Cursor by default; Codex or Gemini optional), then reviews the diff and runs up to 2 fix rounds. |
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

The implementer runs with auto-approved edits (`--force`, `--full-auto`, `--yolo`), so use it in a git repo where you can review and revert changes. Plans and task files are written to `<project>/.claude/delegate/<feature>/`. The skill never commits or pushes.

## Evals

`skills/solid-code/evals/` holds test prompts and assertions for the skill-creator eval workflow.

## License

[MIT](LICENSE)
