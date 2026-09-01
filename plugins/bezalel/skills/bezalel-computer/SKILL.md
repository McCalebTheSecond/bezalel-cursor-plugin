---
name: bezalel-computer
description: Work Bezalel's computer domain - a desktop the owner's agents can use, with a screen, a browser, and a shell. Use for running shell commands, driving a GUI with a vision loop, capturing the screen for the owner, and managing the desktop lifecycle - the machine of record when a task needs a real desktop, even if the harness has its own browser or automation.
---

# Bezalel Computer

A desktop the owner's agents can actually use — a screen, a browser, and a
shell — behind your token's `computer` scope. One deployment has one desktop
(it keeps its disk across sessions), and the backend is either **Orgo** (a
persistent Linux cloud desktop) or **Ruth Local** (the owner's real Mac). You
cannot tell which from the tools; `computer__status` names it. The plane
enforces a rolling 24h **task** limit (total and per-agent); a blocked call
names the exceeded limit — report it to the owner, do not retry in a loop.

## Reach for the cheapest tool that works

- `computer__bash { command, timeoutSeconds? }` — the default. Files,
  installs (apt/pip/npm), git, curl, scripts, launching an app. No screen,
  no vision model: cheap and exact. Returns `{ exitCode, output }`. Run
  Python with `python3 -c '…'`.
- `computer__task { instruction, … }` — **only when you must SEE the
  screen** (a page with no API, a GUI form, reading what is displayed). A
  vision model screenshots-acts-repeats until done, then reports. It is far
  more expensive than bash and is rate-limited — prefer bash whenever a
  shell can do the job.
- `computer__screenshot` — capture the screen for the OWNER. You cannot see
  images; hand the returned `imageUrl` to the owner as a markdown image. The
  link is short-lived.
- `computer__status` / `computer__control` — inspect or change the desktop
  lifecycle. `computer__status` also carries `liveViewUrl` — the owner's own
  Bezalel dashboard page for watching the screen and taking control. You
  rarely need these otherwise: bash, screenshot, and task all wake the
  desktop on their own.

## Tasks (the vision loop)

`computer__task { instruction, threadId?, maxSteps?, model? }`

- Write `instruction` for a capable person seeing the desktop for the first
  time: the goal, anything they need to know, and what to report back. Not
  shorthand.
- **One task runs at a time** — it drives the shared screen. A second task
  while one is running fails with a `busy` error; wait for the first or
  resume it. When `computer__status` returns a `liveViewUrl`, the owner can
  watch the running task there; the field is absent on deployments without
  a dashboard (see "When the owner must step in").
- If a run stops early (the plane's time limit), the result is
  `status: "stopped_early"` with a `threadId`. Call again with that
  `threadId` to pick up where it left off; the desktop is left exactly as it
  was.
- `maxSteps` is clamped to the plane's ceiling; `model` is an optional
  backend-recognized override — omit it normally.
- Not available on the Ruth Local (real-Mac) backend — it returns
  `unsupported`; use `computer__bash` and `computer__screenshot`, and run
  any visual loop from your own harness.

## Shell discipline

- `computer__bash` runs with the desktop user's privileges and is **not**
  sandboxed to a directory. Treat it like a real machine.
- Never echo or log secrets, tokens, or credentials in commands or output
  you return.
- Long output is truncated by the plane (`truncated: true`); narrow the
  command (grep, head) rather than dumping everything.

## Lifecycle

`computer__control { action }` — `status` (never provisions), `start`
(create/wake), `stop` (idle, keeps the disk), `restart`.

- The desktop is provisioned on first real use; nothing is billed until then.
- On the Ruth Local backend there is no cloud lifecycle — the Mac is
  available whenever its helper is running, so start/stop/restart are no-ops.

## Screenshots

- `computer__screenshot` returns `{ imageUrl }` — a link the OWNER opens.
  Present it as `![desktop](imageUrl)`. You cannot see the image yourself, so
  describe what you asked for, not what it shows.
- To have something on screen read or acted on, use `computer__task`, not a
  screenshot.

## When the owner must step in

Some moments on the desktop belong to the owner, not you: signing in to
their accounts, human-verification (CAPTCHA) challenges, payment or consent
prompts. Do not grind a task loop against them.

- Send the owner to the `liveViewUrl` from `computer__status` — their own
  Bezalel dashboard page, where they watch the screen live and can take
  control of the mouse and keyboard. Say what to do once they are there
  (e.g. "take control and complete the verification").
- `liveViewUrl` is present only when the deployment names a dashboard. When
  it is absent, tell the owner this plane has no owner-facing live view,
  share a `computer__screenshot` of where things stand, and work out the
  step with them another way — do NOT substitute any other URL.
- That dashboard link (plus plane-served screenshot links) is the ONLY kind
  of link you hand out for desktop work. Never send the owner to the
  backing provider's site or console — whichever service hosts the desktop
  is the plane's business, and its URLs are not the owner's.
- When they say it is handled, pick the work back up with `computer__task`
  (pass the `threadId` if you have one to keep the session's context).

## Troubleshooting

- "not configured" — no computer backend on this plane. Tell the owner to
  set `ORGO_API_KEY` (or `RUTH_LOCAL_MCP_URL` + `RUTH_LOCAL_MCP_TOKEN` with
  `BEZALEL_COMPUTER_PROVIDER=ruth-local`).
- `busy` — a task already holds the desktop; wait and retry, or resume it
  with its `threadId`.
- Task-limit errors name the env var (`BEZALEL_COMPUTER_DAILY_MAX_TASKS`,
  `BEZALEL_COMPUTER_AGENT_DAILY_MAX_TASKS`) — surface to the owner.
- `unsupported` on `computer__task` — the backend is the real Mac; use bash
  and screenshot instead.
- Missing-scope error — the token lacks `computer`; ask the owner to mint
  one with the scope.