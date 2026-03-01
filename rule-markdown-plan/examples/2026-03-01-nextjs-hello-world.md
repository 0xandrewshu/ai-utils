# Next.js Hello World with App Router

A simple "Hello World" Next.js application using App Router, TypeScript, and Tailwind CSS, verified to run locally.

- **Created Date**: 2026-03-01
- **Author**: ashu
- **Related Plans**: (none)

## Task Update Workflow

You will update the task status after finishing of each task. Task status will use emojis for clear visual differentiation, and be one of: "⬜ TODO", "⌛ In Progress", "✅ Completed", "⏩ Skipped", "🚫 Blocked". After you update the task, you will also update the "Work Log" section from your conversation with the user and tool calls with key learnings such as: problems / errors encountered, design decisions / tradeoffs made.

## Task List

| # | Task | Status | Priority | Comments |
|---|------|--------|----------|----------|
|| **Phase 1: Project Setup** ||||
| 1.1 | Scaffold Next.js project with `create-next-app` (App Router, TypeScript, Tailwind) | ⬜ TODO | High | Use `npx create-next-app@latest` with flags |
| 1.2 | Verify generated project structure (`app/`, `tsconfig.json`, `tailwind.config.ts`) | ⬜ TODO | High | Sanity check that scaffolding worked |
|| **Phase 2: Hello World Implementation** ||||
| 2.1 | Update `app/page.tsx` with a Tailwind-styled "Hello World" message | ⬜ TODO | High | |
| 2.2 | Add a simple API route at `app/api/hello/route.ts` returning JSON | ⬜ TODO | High | Demonstrates backend capability |
| 2.3 | Wire frontend to fetch and display the API response | ⬜ TODO | Medium | Client component calling the API route |
|| **Phase 3: Local Verification** ||||
| 3.1 | Run `npm run dev` and verify the frontend renders at `http://localhost:3000` | ⬜ TODO | High | Visual check for styled Hello World |
| 3.2 | Verify API route responds at `http://localhost:3000/api/hello` | ⬜ TODO | High | curl or browser check |
| 3.3 | Run `npm run build` to confirm production build succeeds | ⬜ TODO | Medium | Catches type errors and build issues |

## Task Breakdown

### Phase 1: Project Setup

**Task 1.1 — Scaffold Next.js project**

Run:
```bash
npx create-next-app@latest hello-world --typescript --tailwind --eslint --app --src-dir=false --import-alias="@/*" --use-npm
```

Key flags:
- `--app` — enables App Router (not Pages Router)
- `--typescript` — TypeScript support
- `--tailwind` — Tailwind CSS pre-configured
- `--src-dir=false` — keep `app/` at root level for simplicity

**Unknowns / potential blockers:**
- Requires Node.js 18.17+ installed locally
- `npx` must be available (comes with npm 5+)

**Task 1.2 — Verify project structure**

Confirm these files/dirs exist after scaffolding:
- `app/layout.tsx`, `app/page.tsx`
- `tailwind.config.ts`
- `tsconfig.json`
- `package.json` with `next`, `react`, `typescript` deps

---

### Phase 2: Hello World Implementation

**Task 2.1 — Update `app/page.tsx`**

Replace default content with a centered "Hello World" using Tailwind utilities:
```tsx
export default function Home() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50">
      <h1 className="text-4xl font-bold text-blue-600">Hello World</h1>
    </main>
  );
}
```

**Task 2.2 — Add API route `app/api/hello/route.ts`**

```ts
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ message: "Hello from the API!" });
}
```

**Relevant files:** Only new file creation; no conflicts expected.

**Task 2.3 — Wire frontend to API**

Add a client component (`app/components/ApiGreeting.tsx`) that fetches `/api/hello` on mount and renders the response. Import it into `app/page.tsx`.

Requires `"use client"` directive since it uses `useEffect`/`useState`.

---

### Phase 3: Local Verification

**Task 3.1 — Frontend check**

```bash
npm run dev
# Open http://localhost:3000 — expect styled "Hello World" text and API greeting
```

**Task 3.2 — API route check**

```bash
curl http://localhost:3000/api/hello
# Expect: {"message":"Hello from the API!"}
```

**Task 3.3 — Production build**

```bash
npm run build
# Should exit 0 with no type errors
```

**Potential blockers:**
- Port 3000 already in use — pass `-p 3001` if needed
- Missing Node.js or npm — must be installed beforehand

## Work Log

(No entries yet — will be updated as tasks are completed.)

## TODO

When the user tells you to save this task for later, add it as a checklist item in this section.
