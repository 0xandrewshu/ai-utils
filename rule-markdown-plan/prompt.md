# Instructions: creating markdown plan files for implementation

You will create a markdown plan files for implementation that will be saved to the local filesystems.

## Output directory

You will write the markdown plan file to `tmp/$YYYY-$MM-$DD-$PROJECT_NAME.md`, unless the user specifies differently. Assume the folder exists

## Plan file structure

- Title: Give a short title to the project
- Objective: Underneath the title, include the objective: 1-2 sentences describing the high level goal of this project.
- Information: "Created Date", "Author", "Related Plans". Write them as bulletpoints `- **$HEADING**: $VALUE`
    - "Related Plans" is a comma-separated list of filepaths. User may choose to split or spawn new "child plans" from original "parent plans".
- Task update workflow: you will copy this exact text to its own section:
    - `You will update the task status after finishing of each task. Task status will use emojis for clear visual differentiation, and be one of: "⬜ TODO", "⌛ In Progress", "✅ Completed", "⏩ Skipped", "🚫 Blocked". After you update the task, you will also update the "Work Log" section from your conversation with the user and tool calls with key learnings such as: problems / errors encountered, design decisions / tradeoffs made.`
- Task List: markdown table with numbered tasks. Has columns: #, Task, Status, Priority, Comments. See below for example.
    - You will group tasks into numbered phases to make implementation easier. Subtasks will be numbered with their phase numbers, e.g. `Task 3.4` refers to "Phase 3", "Sub-task 4"
- Task Breakdown: essentially an implementation design document.
    - Identify unknowns, potential blockers and relevant files related to implementation, for human and AI consumption.
- Work Log: when you update the Status in the Task List, log your work and learning in this section for future context.
    - Label each update with the task number and key learnings such as: problems / errors encountered, design decisions / tradeoffs made.
- TODO: leave this section initially blank, and copy this exact text into the section: `When the user tells you to save this task for later, add it as a checklist item in this section`.

## Example Task List

| # | Task | Status | Priority | Comments |
|---|------|--------|----------|----------|
|| **Phase 1: Backend** ||||
| 1.1 | Task description | ⬜ Todo | High | |
| 1.2 | Another task | ⌛ In Progress | Medium | |
|| **Phase 2: Frontend** ||||
| 2.1 | Frontend task | ✅ Completed | High | |
| 2.2 | Skipped task | ⏩ Skipped | Low | Reason for skip |
