# Rails + React Hello World

A simple Rails API backend serving a React frontend that displays "Hello World".

- **Created Date**: 2026-02-27
- **Author**: Ashu
- **Related Plans**: (none)

## Task Update Workflow

You will update the task status after finishing of each task. Task status will use emojis for clear visual differentiation, and be one of: "⬜ TODO", "⌛ In Progress", "✅ Completed", "⏩ Skipped", "🚫 Blocked". After you update the task, you will also update the "Work Log" section from your conversation with the user and tool calls with key learnings such as: problems / errors encountered, design decisions / tradeoffs made.

## Task List

| # | Task | Status | Priority | Comments |
|---|------|--------|----------|----------|
|| **Phase 1: Rails API Setup** ||||
| 1.1 | Create new Rails API-only app | ⬜ Todo | High | `rails new` with `--api` flag |
| 1.2 | Add a HelloController with a JSON endpoint | ⬜ Todo | High | `GET /api/hello` returns `{ message: "Hello World" }` |
| 1.3 | Configure CORS for local React dev server | ⬜ Todo | High | Add `rack-cors` gem |
| 1.4 | Verify Rails API works via curl | ⬜ Todo | Medium | |
|| **Phase 2: React Frontend Setup** ||||
| 2.1 | Create React app with Vite | ⬜ Todo | High | Inside the Rails project or sibling directory |
| 2.2 | Build a simple Hello component that fetches from the API | ⬜ Todo | High | Fetch `/api/hello` and display the message |
| 2.3 | Configure Vite proxy to forward `/api` requests to Rails | ⬜ Todo | Medium | Avoids CORS issues in dev |
| 2.4 | Verify end-to-end: React renders "Hello World" from Rails | ⬜ Todo | High | |
|| **Phase 3: Polish & Documentation** ||||
| 3.1 | Add a Procfile or script to start both servers | ⬜ Todo | Medium | e.g. `foreman` or a simple shell script |
| 3.2 | Add a README with setup instructions | ⬜ Todo | Low | |

## Task Breakdown

### Phase 1: Rails API Setup

**1.1 — Create new Rails API-only app**
- Run `rails new hello_world_app --api -T` (skip tests for simplicity)
- Ruby and Rails must be installed; confirm versions first
- **Relevant files**: `Gemfile`, `config/routes.rb`, `config/application.rb`

**1.2 — Add HelloController**
- Create `app/controllers/api/hello_controller.rb`
- Single action: `index` returns `{ message: "Hello World" }` as JSON
- Add route: `namespace :api { get 'hello', to: 'hello#index' }`
- **Unknowns**: None — straightforward

**1.3 — Configure CORS**
- Add `gem 'rack-cors'` to Gemfile, `bundle install`
- Configure in `config/initializers/cors.rb` to allow `localhost:5173` (Vite default)
- **Potential blocker**: If rack-cors gem version has breaking changes, check docs

**1.4 — Verify Rails API**
- `curl http://localhost:3000/api/hello` should return `{"message":"Hello World"}`

### Phase 2: React Frontend Setup

**2.1 — Create React app with Vite**
- Run `npm create vite@latest frontend -- --template react` inside the project root
- `cd frontend && npm install`
- **Relevant files**: `frontend/vite.config.js`, `frontend/src/App.jsx`

**2.2 — Hello component**
- In `App.jsx`, use `useEffect` + `fetch('/api/hello')` to get the message
- Display the message in a simple `<h1>` tag
- Handle loading state with a simple "Loading..." fallback

**2.3 — Vite proxy config**
- In `vite.config.js`, add `server.proxy` to forward `/api` to `http://localhost:3000`
- This removes the need for CORS in development (CORS config is still useful for production)

**2.4 — End-to-end verification**
- Start Rails: `rails s` (port 3000)
- Start Vite: `npm run dev` (port 5173)
- Open `http://localhost:5173` — should display "Hello World"

### Phase 3: Polish

**3.1 — Procfile**
- Create `Procfile.dev` with `web: rails s` and `frontend: cd frontend && npm run dev`
- Use `foreman start -f Procfile.dev` or a simple `bin/dev` script
- **Potential blocker**: `foreman` gem needs to be installed globally or added to Gemfile

**3.2 — README**
- Prerequisites (Ruby, Node, Rails versions)
- Setup steps (`bundle install`, `npm install`, `bin/dev`)

## Work Log

(No work started yet)

## TODO

When the user tells you to save this task for later, add it as a checklist item in this section.
