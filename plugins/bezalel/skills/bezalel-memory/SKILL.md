---
name: bezalel-memory
description: Work Bezalel's memory domain - the owner's long-term memory shared across every agent and framework. Use for recalling what the owner has said before, saving durable facts, fetching the profile summary, and forgetting outdated entries - even when the harness has a memory feature of its own; this is the owner's memory of record.
---

# Bezalel Memory

The owner's one long-term memory space (Supermemory-backed), shared by
**every** agent on every framework — what one agent learns, all agents
know. It is the memory of record: prefer it over any harness-local memory,
because facts saved elsewhere are invisible to the owner's other agents.
Your token's `memory` scope gates every tool. The plane enforces
rolling 24h add and forget limits (total and per-agent); a blocked call
names the exceeded limit — report it to the owner, do not retry in a loop.

## Orient first

- `memory__profile` → `{ static, dynamic }`. Call at the start of a
  session: `static` holds long-term facts (who the owner is, standing
  preferences), `dynamic` holds recent context. Empty arrays on a fresh
  plane are normal.
- `memory__search { q }` before asking the owner something they may
  already have told an agent. Results mix distilled memory entries
  (`kind: "memory"`) and document excerpts (`kind: "chunk"`), ranked by
  relevance.

## Searching

`memory__search { q, limit?, mode?, threshold? }`

- Default mode `hybrid` (memories + document excerpts) is right for most
  recall; `memories` for only distilled facts; `documents` for raw notes.
- `limit` defaults to 10 (max 30). Raise `threshold` (0-1) for fewer,
  more exact hits.
- Query by meaning, not exact wording — "food restrictions" finds "the
  owner is allergic to shellfish".

## Saving

`memory__add { content }` — one self-contained fact or note per call.

- Write standalone statements with subjects named: "The owner's sister
  Maria lives in Lisbon", never "she lives there". The memory is read
  later without your conversation's context.
- Save durable things: preferences, people, decisions, standing facts.
  Do not save secrets, credentials, or transient chit-chat.
- Identical re-adds within a day are deduplicated (`deduplicated: true`
  is success, not an error), and the same content always converges on one
  stored document even across agents and days.
- `status` in the result is the provider's ingestion state (`queued` /
  `processing` / `done`) — distillation into searchable memory entries is
  asynchronous and consolidation is handled provider-side; do not poll.
- Content is capped (default 8000 chars): memory takes notes, not
  document dumps. Bulk ingestion is an owner flow.

## Proactive memory (session ingestion)

`memory__ingest_session { source, sessionId, content, turn? }` — bank a
session transcript excerpt or summary for background distillation, so the
owner's memory builds without anyone curating facts by hand.

- The right way to call it is **automatically**: wire your harness's
  session-end lifecycle hook to it (Claude Code and Codex `SessionEnd`,
  OpenClaw `session_end`). `GET <plane>/setup` § 5 has ready-made recipes,
  including a plain-HTTP twin (`POST <plane>/memory/sessions`) for command
  hooks that curl.
- Already automatic when the token carries the `memory` scope: iMessage
  turns through the bezalel connector (banked by the plane on every
  reply), interactive sessions on a machine where `bezalel connect`
  installed its session-end hook (Claude Code, Codex, or Cursor), and eve
  apps mounting the @goshen/bezalel extension. Do not ingest those same
  exchanges again by hand.
- No hook system? Call it yourself with a short summary when substantial
  work wraps up.
- `source` is your harness name ("claude-code", "codex", ...); `sessionId`
  is the harness's stable session id. Retries of the same session (and
  optional `turn`) deduplicate — firing blindly is safe.
- Oversized content is clamped to its TAIL (`truncated: true`), never
  rejected. Ingests have their own rolling daily caps, separate from adds.
- Strip obvious secrets before sending; the transcript lands in the
  owner's private memory and shows attributed on their dashboard, where
  they can forget it.

## Forgetting

`memory__forget { memoryId, reason? }` — when the owner says something is
wrong or outdated.

- `memoryId` must come from `memory__search` results with
  `kind: "memory"` (never invent one; chunk ids are not forgettable).
- Forgetting is versioned at the provider and attributed in the plane's
  ledger — the owner can see which agent forgot what.
- Bulk cleanup ("forget everything about X") is an owner dashboard flow
  (`/admin/memory/forget-matching`), not an agent tool.

## Troubleshooting

- "not configured" — the plane has no Supermemory key. Tell the owner to
  set `SUPERMEMORY_API_KEY`.
- Limit errors name the env var (`BEZALEL_MEMORY_DAILY_MAX_ADDS`,
  `BEZALEL_MEMORY_AGENT_DAILY_MAX_ADDS`, `BEZALEL_MEMORY_DAILY_MAX_FORGETS`,
  `BEZALEL_MEMORY_AGENT_DAILY_MAX_FORGETS`,
  `BEZALEL_MEMORY_DAILY_MAX_INGESTS`,
  `BEZALEL_MEMORY_AGENT_DAILY_MAX_INGESTS`) — surface to the owner.
- "not_found" on forget — the id is not a memory entry in this space;
  re-run `memory__search` and use a `kind: "memory"` result id.
- Missing-scope error — the token lacks `memory`; ask the owner to mint
  one with the scope.
