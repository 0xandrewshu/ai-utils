# AI Utilities: collection of scripts, prompts and docs

As I use AI for vibe coding or other types of work, I find it helpful to collect reusable prompts, skills, subagent files, configs, etc. I'm creating this repository to deposit artifacts that I've found useful.

## Compatibility

The intent is for these snippets to be reusable across AI coding tools (e.g. Claude Code, Cursor, Codex, Gemini / Antigravity, Copilot, etc.). There are occasionally differences in capabilities, but they have typically "caught up" with one another pretty quickly after that.

## Repository organization

Initially, I plan to organize these as a flat directory until more organization is necessary.

- `rule-$NAME/` - e.g. CLAUDE.md, AGENT.md, AGENTS.md
- `skill-$NAME/` - e.g. Claude Skills, Cursor Skills
- `subagent-$NAME/` - e.g. Claude Subagents, Cursor Subagents
- `prompt-$NAME/` - e.g. reusable prompts to copy/paste into vibe coding tools (Claude Code, Cursor) or chat AI tools (Claude.ai, ChatGPT)

In each directory, I'll aim to have:

- `readme.md` - read this for instructions
- `prompt.md`, `skill.md`, etc - this is the "asset" that you can copy/paste into your directory
    - I may also bundle everything into a subfolder like `rule-$NAME/name/` to make it easier for you to "copy it in" to your directory

## Technology

TBD, but there's going to be a lot of prompts / context as markdown files. I've found shell files and Typescript scripts to be useful, so I may include those in here as well.

## Security

- I've written all of this to have minimal security impact
- But since I'm working on tooling, I try to call out in each subfolder's `readme.md` factors to consider as you use these tools
- If I didn't include a `Security` section, then it's because I think there is nothing worth noting.

