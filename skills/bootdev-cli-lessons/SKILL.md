---
name: bootdev-cli-lessons
description: Work through boot.dev CLI-SUBMISSION lessons only (guided projects like "Build a Pokedex in TypeScript" where the `bootdev` CLI verifies a local repo). Use ONLY when the user asks to continue/complete a boot.dev CLI-based project or explicitly names this skill. Do NOT use for boot.dev courses/lessons where code is typed into the website's code editor or that use multiple-choice questions — those are a different project type this skill does not cover.
---

# Boot.dev CLI Lessons

Boot.dev has two kinds of hands-on work:

1. **CLI-submission projects** (this skill): guided projects like "Build a Pokedex in TypeScript". Work happens in a local repo; lessons are verified by running the `bootdev` CLI. The lesson page's Activity panel says "Run and submit the CLI tests" and shows `bootdev run` commands.
2. **Web-editor lessons** (NOT this skill): regular course lessons where code is typed into the browser's code editor, plus multiple-choice questions. Do not apply this skill's CLI workflow there; answer/submit in the page instead.

If unsure which kind a lesson is, read the lesson text (snippet below) and look for `bootdev run` — its presence means CLI type.

## Decision tree (per lesson)

1. Extract the lesson text (step 2 snippet).
2. If the lesson describes a Boot.dev CLI check or says to run and submit CLI tests, implement, verify, then submit through the CLI path.
3. If no CLI check is specified, do not call the check-and-submit helper. Follow the assignment's own verification steps (for example, run a long-running service briefly and stop it cleanly), then use the completion UI probe in step 6. If there is no completion control, advance as an informational lesson.
4. For any non-CLI completion, run the combined completion probe (step 6) once:
   - `yes: true` → click Yes.
   - `q` non-null → multiple-choice: answer it.
   - github.com input present → repo-URL form: fill and submit.
   - none of those → informational: just advance via the `next` URL the probe returned.

## Ground rules (token discipline)

- **Never** use full `preview_snapshot` or `document.body.innerText` on boot.dev pages — they return 20–35k chars of nav/notification noise.
- Extract only what you need with targeted `preview_evaluate` JS (snippets below). Keep returned strings capped (`.slice()`).
- Don't re-read a lesson you already have. Don't fetch the Next link if you can derive it from a lesson you already extracted.
- **Call `preview_status` only once** to get the `tabId`. `preview_navigate` returns the tabId and new URL in its response, so never re-poll status between lessons.

## Browser workflow

- Use the T3 integrated browser and reuse the existing Boot.dev tab. At session start, call `preview_status` once to identify the tab and lesson URL.
- Read the assignment from the lesson instructions pane with the targeted `preview_evaluate` snippet in step 2. Do not read the full page body unless the pane cannot be found; cap any fallback text.
- Before leaving a lesson, capture its Next link. Navigate the same tab, then confirm the returned URL/title identifies the expected next lesson. Do not re-read the previous lesson.
- If the instructions pane, Next link, or page state is ambiguous, use `preview_snapshot` per the repository's `AGENTS.md` browser guidance. Prefer one focused snapshot; return to targeted text extraction once the page is clear.
- Do not use external browsers, Computer Use, or Playwright for this workflow. If native browser interaction fails, report the error instead of silently switching tools.
- At lesson completion, check for a `Yes` button, a question, or a repository URL form. After clicking or submitting, verify the completion state with a fresh focused snapshot. A successful click call alone does not confirm completion.

## Startup and recovery

- At course start, check the workspace contents, `node --version`, and whether `bootdev` is on `PATH`. Do this once. If Node is already installed, honor the user's preference and skip NVM; do not install or change Node versions unless requested or a lesson explicitly requires it.
- Do not run `git init` unless the lesson requires Git. If it is required, check whether the directory is already a repository before initializing it.
- Keep setup commands in small stages instead of one long `&&` chain. If a command times out or appears to keep running, inspect the expected files/directories first and continue from the first incomplete step; do not blindly rerun installs or overwrite files.
- When `tsx` fails with `listen EPERM` while creating its IPC pipe, retry the required run command in an execution context that permits local pipe/socket creation. Do not change project code to work around an environment permission error. After the run prints the expected output, submit the CLI check.
- If installation succeeds but warns that an optional package install script is pending approval, continue unless the package or the lesson explicitly needs that script; investigate only if the subsequent command fails for that reason.
- If a required command fails because the installed toolchain differs from the lesson's assumptions, use the error to identify the incompatible setting or version. Make the smallest project-local compatibility change and rerun the required check. Do not change global tool versions unless requested or required by the lesson.
- For long-running commands such as pollers, servers, and watchers, use a short controlled run. Confirm startup and one useful unit of work, then stop it with the documented signal (often Ctrl+C). Do not leave it running or treat its expected wait as a hang.

## Loop per lesson

1. **Identify the lesson.** The open browser tab URL is `https://www.boot.dev/lessons/<UUID>`; get it from `preview_status` (once — reuse the `tabId` from then on). Save the UUID — you need it for the CLI.
2. **Read the lesson text** (the only browser read you need):

```js
(()=>{const r=[...document.querySelectorAll('[aria-label]')].find(e=>/lesson instructions/i.test(e.getAttribute('aria-label')||''));return (r?r.innerText:document.body.innerText).slice(0,6000);})()
```

This returns ~1–3k chars of clean lesson content (title, assignment, code samples, and — at the bottom — the CLI check description). If 6000 chars truncates the assignment, request the next slice of the same string.

3. **Note the check** at the bottom of the lesson text:
   - `bootdev run <UUID>` checks, `bootdev run -s <UUID>` submits. Typical checks: `npm run dev` output, `npm run test` passes, or `cat repl.log` content.
   - Some lessons have **no CLI check** — they show "Have you completed this lesson? Yes", a repo-URL form, or a multiple-choice question instead (see step 6).
   - Informational lessons may have **no completion UI at all** — if the page has no "Yes", no form, and no question, just advance to the next lesson.
4. **Implement** in the local repo (the session working directory is the project). Follow the assignment's file names and exact output strings — checks match stdout literally (e.g. `Closing the Pokedex... Goodbye!`).
5. **Verify, then submit:** run the exact command the check describes (e.g. `printf "help\nexit\n" | npm run dev`), then submit only after it succeeds. The bundled helper `scripts/check-submit.sh <UUID>` runs `bootdev run <UUID>` and submits with `bootdev run -s <UUID>` only when the check passes. Run it from the course repo root. Expect `All tests passed!` and an XP summary. If the lesson requires a preparation step between check and submit, run the two CLI commands separately and perform that step; the helper assumes no intervening preparation is needed.
6. **Non-CLI completions:** first run the combined completion probe — it detects the completion type AND fetches the Next link in one call:

```js
(()=>{const yes=[...document.querySelectorAll('button')].find(b=>b.innerText.trim()==='Yes');const q=[...document.querySelectorAll('p,h1,h2,h3,div')].filter(e=>/\?\s*$/.test(e.innerText.trim())&&e.innerText.length<200);return JSON.stringify({yes:!!yes,q:q.length?q[q.length-1].innerText.slice(0,150):null,form:!![...document.querySelectorAll('input')].find(e=>e.placeholder.includes('github.com')),next:[...document.querySelectorAll('a')].filter(a=>/next/i.test(a.innerText.trim())).map(a=>a.href)[0]||null});})()
```

   Then act on the result:
   - "Yes" button (`yes: true`): click it via JS — `[...document.querySelectorAll('button')].find(b=>b.innerText.trim()==='Yes').click()` — no snapshot needed.
   - **Multiple-choice question:** read it with the question-walk-up snippet:

```js
(()=>{const leaves=[...document.querySelectorAll('p,h1,h2,h3,div')].filter(e=>/\?\s*$/.test(e.innerText.trim())&&e.innerText.length<200);if(!leaves.length)return 'no question';let box=leaves[leaves.length-1];for(let i=0;i<8&&box.parentElement;i++){box=box.parentElement;if(box.querySelector('button'))break;}return box.innerText.slice(0,1000);})()
```

     It returns the question and numbered options (~200 chars). Answer by clicking the button whose text matches the correct option exactly. Clicking IS the submission — there is no separate submit button; a selected answer gets a gold border (`border-light-gold` in its class list).
   - Repo URL form: set the input whose placeholder contains `github.com` using the native setter, then click "Submit All Checks":

```js
(()=>{const el=[...document.querySelectorAll('input')].find(e=>e.placeholder.includes('github.com'));const s=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set;s.call(el,'<REPO_URL>');el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));[...document.querySelectorAll('button')].find(b=>b.innerText.trim()==='Submit All Checks').click();return 'submitted';})()
```

7. **Advance** to the next lesson. For non-CLI lessons the combined probe in step 6 already returned the `next` URL — use it. Otherwise:

```js
[...document.querySelectorAll('a')].filter(a=>/next/i.test(a.innerText.trim())).map(a=>a.href)[0]
```

then `preview_navigate` the same tab there and loop back to step 2. (If the lesson ended the course, "Next" is a button, not a link — stop.)

## Git publishing checkpoint

- A public repository lesson needs a real remote URL. Before pushing, check that the named repository exists and that local `origin` points to it. Exclude generated dependencies such as `node_modules` from commits.
- If no destination is provided, ask the user for the owner/name or URL before creating or pushing a remote. If the provided destination does not exist, create it only when the user's instruction clearly authorizes creating that repository; then push and verify the remote branch.
- After submitting a repository URL in Boot.dev, verify the completion state with a fresh snapshot. Do not report success based only on filling the form or clicking its button.

## Gotchas learned the hard way

- **`bootdev` CLI only runs checks** — it cannot fetch lesson text. The `api.boot.dev/v1/lessons/<UUID>` endpoint rejects the CLI's stored token; the browser is the source of truth for lesson content.
- **The project dir may not be the session cwd.** Use the `cwd` parameter on Bash calls (e.g. a sibling directory under the courses root). `bootdev run`/`submit` execute their checks in the current directory, so run them from the dir the lesson expects. A brand-new empty dir works fine for setup lessons.
- **man-page / `git help` output uses overstrike formatting** (backspace chars). Strip it before reading: `GIT_PAGER=cat git help git | sed 's/.\x08//g'`.
- **Re-running completed lessons is safe** and grants +0 XP — useful for testing. If a submission passes with `Gained +0 XP`, the lesson was already completed before; don't dwell or re-check, just advance.
- **Git identity lessons touch global machine state** (`git config set --global user.name/user.email`). If unset, derive them from `gh auth status` / `gh api user -q '.login,.email'`; when the GitHub email is private (null), use the noreply form `<login>@users.noreply.github.com`.
- **Piped stdin + async REPLs:** `printf "a\nb\n" | npm run dev` delivers all lines at once and closes stdin. Use `for await (const line of rl)` so commands run sequentially, and guard `rl.prompt()` after close (`rl.closed` works at runtime but isn't in the types — cast).
- **`repl.log` lessons:** the log is produced by `npm run dev | tee repl.log`; checks grep it for exact lines and also assert some lines are absent — run exactly the inputs the lesson lists, in order.
- **Vitest picks up compiled `dist/*.test.js`** too; harmless, but don't be confused by doubled test counts.
- **package.json trap:** if `"type"` appears twice in package.json the later value wins — must be `"module"` for the ESM imports the courses use.
- Don't create git repos or push without the user naming the remote/org; ask once, then use `gh`.

## Efficiency estimate

Full-page reads cost ~5–10x more tokens than the targeted snippets above. A disciplined run through ~10 lessons should stay in the low tens of thousands of tokens of browser I/O instead of hundreds of thousands.
