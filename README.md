# Agent Skills

Coding-agent skills for Claude Code, Codex, Cursor, OpenCode and any agent that
reads the open [Agent Skills](https://agentskills.io/specification) format.

This repository is a read-only snapshot exported from a private source repo, so
pull requests can't be merged here. Open an issue instead.

## Install

With the [skills CLI](https://skills.sh), pick skills and agents interactively:

```bash
npx skills add GonsalvesMedia/agent-skills
npx skills add GonsalvesMedia/agent-skills --skill handoff   # one skill
npx skills add GonsalvesMedia/agent-skills -g                # every project, not just this one
```

Or clone this repository and link each skill into the folders your agents read.
Existing entries with the same name are left alone:

```bash
for dest in ~/.agents/skills ~/.claude/skills; do
  mkdir -p "$dest"
  for skill in $(find "$PWD/skills" -name SKILL.md -exec dirname {} \;); do
    target="$dest/$(basename "$skill")"
    if [ -e "$target" ] || [ -L "$target" ]; then echo "skip: $target exists"; else ln -s "$skill" "$target"; fi
  done
done
```

## Skills

| Skill | Path |
|---|---|
| `handoff` | `skills/engineering/delegation/handoff` |
| `use-claude` | `skills/engineering/delegation/use-claude` |
| `use-codex` | `skills/engineering/delegation/use-codex` |
| `use-cursor` | `skills/engineering/delegation/use-cursor` |
| `use-kimi` | `skills/engineering/delegation/use-kimi` |
| `create-plan` | `skills/engineering/planning/create-plan` |
| `explore-unknowns` | `skills/engineering/planning/explore-unknowns` |
| `implement-plan` | `skills/engineering/planning/implement-plan` |
| `eval-skills` | `skills/engineering/quality/eval-skills` |
| `refactor-clean` | `skills/engineering/quality/refactor-clean` |
| `review-changes` | `skills/engineering/quality/review-changes` |
| `write-tests` | `skills/engineering/quality/write-tests` |

## License

MIT. See [LICENSE](LICENSE).
