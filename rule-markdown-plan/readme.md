# Rule: Markdown Plan

A reusable prompt rule that instructs AI coding agents (Claude Code, Cursor, etc.) to create structured markdown plan files for multi-step implementation work.

Instead of relying on built-in planning modes, this rule produces a markdown file artifact you can control: edit, commit, archive, or feed into other tools.

## Installation

Copy `prompt.md` into your project or personal configuration. You have several options:

- **Project-level (AGENT.md / CLAUDE.md):** Paste the contents into your root `AGENT.md` or `.claude/CLAUDE.md` so every conversation in the project picks it up. See [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/memory) and [Cursor rules docs](https://cursor.com/docs/context/rules).
- **Personal Cursor Rule:** Add it as a user-level Cursor Rule so it applies across all your projects. See [Cursor user rules](https://docs.cursor.com/context/rules#user-rules).
- **Personal Claude Code config:** Add it to `~/.claude/CLAUDE.md` for use across all Claude Code sessions. See [Claude Code memory docs](https://docs.anthropic.com/en/docs/claude-code/memory).

## Usage

### Creating a plan

Tell the agent to create a markdown plan. 

You can try being concise, e.g.:

```
Create a plan for a simple Rails hello world server with a React frontend.
```

But sometimes I find the AI to switch to the builtin planning mode, which I don't want. 

So then I switch to being explicit:

```
Create a md plan according to guidelines for migrating the database from Postgres to CockroachDB.
```

The agent will research the task, then write a structured plan file with a task list, task breakdown, and empty work log and TODO sections.

### Working through the plan

Once the plan exists, reference tasks by number:

```
Do tasks 1.1 through 1.3, but skip 1.4.
```

```
Start phase 2.
```

The agent updates task statuses and logs learnings in the Work Log as it goes.

### Updating the plan

Plans change as you discover new information. Tell the agent:

```
Add a new task to phase 1 for handling rate limiting. Mark it as high priority.
```

```
Split task 2.3 into a separate child plan — it's bigger than we thought.
```

```
Log this error in the work log for future reference: [paste error]
```

### Adding a task to the TODO section

```
Add a todo to fix this problematic CSS issue with the UI table alignment.
```


### Closing the plan

When done, you can simply delete the plan file, or archive it for future reference.

**Archive approaches:**

- If you use a directory structure like `plan/{active,completed,todo,inactive}`, move the file to `completed/` and commit it.
- If you want to keep your git repo clean, write the plan to an external system:
  - Copy it to an Obsidian vault via a local filesystem write
  - Push it to a Notion database via MCP
  - Export it to any other knowledge base

**Automating plan closure with a Skill:** You can create a reusable Skill (e.g. `finish-plan`) that runs when you close out a plan. Ideas for what it could do:

- Review the code written during the plan for security issues, cleanup, or missing tests
- Check that documentation is up to date
- Validate that file paths referenced in the plan or docs still exist
- Move TODO items from the plan into your backlog or issue tracker

## Ideas for Customization

The prompt is meant to be edited. Here are some things you might change:

**Output directory.** The default is `tmp/$YYYY-$MM-$DD-$PROJECT_NAME.md`. Alternatives:
- `plan/active/` for active plans, with `plan/completed/` for archiving
- A shared team directory for collaborative visibility
- A path outside the repo (e.g. an Obsidian vault) if you don't want plans in git

**Remove the Work Log section.** If you find per-task logging to be overkill for your workflow, remove the Work Log section and the related instruction in the "Task update workflow" block. The plan still works fine without it.

**Remove the TODO section.** If you track future work elsewhere (e.g. GitHub Issues, Linear), you may not need the in-plan TODO list.

**Adjust the task list columns.** The default columns are `#, Task, Status, Priority, Comments`. You could drop `Priority` for simpler plans or add an `Assignee` column for multi-person work.

**Change the status emojis.** The defaults are `⬜ TODO`, `⌛ In Progress`, `✅ Completed`, `⏩ Skipped`, `🚫 Blocked`. Swap them for whatever is readable to you.

**Prompts embedded in the plan.** If you read the prompt, it inserts some prompts into your plan. You may choose to remove the prompt, update it, or add to it. Examples include:

- In the `## Task Update Workflow` section, `You will update the task status after finishing of each task...`
- In the `## TODO` section, `When the user tells you to save this task for later...`