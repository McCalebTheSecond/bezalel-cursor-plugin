---
name: bezalel-sandbox
description: Work Bezalel's sandbox domain - disposable Linux microVMs for running untrusted or generated code, distinct from the owner's persistent computer. Use for executing code, compiling, testing, or scratch work in throwaway isolated environments - the default even when the harness ships a sandbox or exec tool of its own.
---

# Bezalel Sandbox

Disposable Linux microVMs behind your token's `sandbox` scope — a shell, a
filesystem, and internet, isolated from everything. A sandbox is **cattle,
not a pet**: spin one up, run code, throw it away. There can be several at
once. This is NOT the owner's computer (that is the `computer` domain — one
persistent machine); nothing here touches the owner's real files, and every
sandbox auto-expires.

Backends are swappable (Daytona, E2B, or Vercel Sandbox — the plane picks
one); you cannot tell which, and should not care. When your token grants
`sandbox`, this is the default place to run throwaway work — prefer it over
a harness-local sandbox so the work stays under the owner's caps and audit.
The plane caps how many sandboxes you create per day and how many run at
once, so a blocked call names the exceeded limit — report it, do not retry
in a loop.

## The one verb you usually need

`sandbox__exec { command, sandboxId?, cwd?, timeoutSeconds? }`

- Omit `sandboxId` and the plane spins up a fresh sandbox for the call and
  returns its id in the result — reuse that id on follow-up execs to keep
  working in the same environment.
- Returns `{ sandboxId, exitCode, stdout, stderr }`. A non-zero `exitCode`
  is a normal result (the command ran and failed), not a tool error.
- Output is truncated (`truncated: true`) past the plane's ceiling; narrow
  the command (grep, head, tail) rather than dumping everything.
- `timeoutSeconds` is clamped to the plane's max. Long installs are fine;
  runaway loops get cut off.

## Files

- `sandbox__write_file { sandboxId, path, content }` — create or replace a
  text file at an absolute path. Size-capped; write large data in chunks or
  fetch it from inside the sandbox with `curl` in an exec.
- `sandbox__read_file { sandboxId, path }` — read a text file; large files
  come back `truncated: true`.

## Managing the pool

- `sandbox__create { image? }` — pre-provision a sandbox and get its id.
  Usually unnecessary; `sandbox__exec` does this on demand.
- `sandbox__list` — the plane's live sandboxes (never any other sandboxes in
  the provider account).
- `sandbox__kill { sandboxId }` — destroy one when you are done, to free a
  concurrency slot. Idempotent: killing a gone sandbox returns
  `killed: false`. Sandboxes also auto-expire on their own, so this is
  courtesy, not obligation.

## When to use a sandbox vs the computer

- Sandbox: run untrusted or generated code, compile, run a test suite, try a
  risky command, parallel scratch work. Ephemeral and disposable.
- Computer (`computer__*`): the owner's ONE real machine with a screen and a
  browser, persistent across sessions. Use it when the work is the owner's,
  needs their logins, or must be seen.

## Troubleshooting

- "not configured" — no sandbox backend on this plane. Tell the owner to set
  the keys for the selected `BEZALEL_SANDBOX_PROVIDER` (Daytona / E2B /
  Vercel).
- Limit errors name the env var (`BEZALEL_SANDBOX_DAILY_MAX_CREATES`,
  `BEZALEL_SANDBOX_AGENT_DAILY_MAX_CREATES`, `BEZALEL_SANDBOX_MAX_CONCURRENT`)
  — surface to the owner. For a concurrency cap, `sandbox__kill` an idle one
  and retry.
- Missing-scope error — the token lacks `sandbox`; ask the owner to mint one
  with the scope.
