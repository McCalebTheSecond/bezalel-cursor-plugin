---
name: bezalel-connectors
description: Work Bezalel's connectors domain - the owner's connected third-party apps (GitHub, Gmail, Slack, Notion, and hundreds more) through one gateway. Use to discover and execute app actions the plane's native domains do not cover.
---

# Bezalel Connectors

The owner's connected third-party apps behind your token's `connectors`
scope: one gateway (Composio) fronting a catalog of thousands of tools
across hundreds of apps. Executes run under the OWNER'S linked accounts —
treat every execute like acting as them, because you are.

Prefer a native Bezalel domain when one exists (email, cards, finance,
imessage, memory, computer, sandbox) — those carry richer plane invariants.
Connectors cover everything else: GitHub, Slack, Notion, Linear, Calendar,
Drive, and the long tail.

## The flow

1. `connectors__list_connections` — which apps are linked and ACTIVE. Only
   ACTIVE connections can execute tools that need auth.
2. Linking a new app: `connectors__connect { toolkit }` returns the
   gateway's OAuth hand-off. Give `redirectUrl` to the OWNER to open in
   their browser — never open or fetch it yourself; the authorization is
   theirs to grant. Once they finish, the connection shows ACTIVE in
   `connectors__list_connections`. (The dashboard's Connectors page does
   the same thing by hand.) A missing `redirectUrl` means the app needs no
   browser step. Do NOT call this in a loop: asking again while a hand-off
   is pending returns the same link (`reused: true`), every mint is a
   ledger row attributed to you, and mints are capped per rolling 24h
   (`BEZALEL_CONNECTORS_DAILY_MAX_CONNECTS`,
   `BEZALEL_CONNECTORS_AGENT_DAILY_MAX_CONNECTS`).
3. `connectors__list_tools { toolkit?, query?, limit?, cursor? }` — search
   the catalog. Filter by toolkit slug (e.g. `github`) and/or free text.
   Results are summaries; paginate with `nextCursor`.
4. `connectors__get_tool { slug }` — the tool's `inputSchema` (JSON
   Schema). ALWAYS read this before executing an unfamiliar tool so your
   arguments match.
5. `connectors__execute { slug, arguments }` — run it. Returns
   `{ successful, data, error? }`.

## Reading execute results

- `successful: false` means the APP rejected the call (bad arguments,
  missing permission, rate limit at the app) — read `error`, fix, or
  report. It is not a plane failure.
- Oversized results come back as truncated JSON text (`truncated: true`).
  Narrow the request (filters, smaller page sizes) rather than re-running.

## Plane invariants (why a call may be refused)

- Rolling daily execute limits, total and per-agent
  (`BEZALEL_CONNECTORS_DAILY_MAX_EXECUTES`,
  `BEZALEL_CONNECTORS_AGENT_DAILY_MAX_EXECUTES`) — blocked calls name the
  limit; report it, do not retry in a loop.
- The owner's toolkit allowlist (`BEZALEL_CONNECTORS_ALLOWED_TOOLKITS`):
  when set, executes outside it are refused with `not_allowed`. Ask the
  owner to allow the toolkit; never try to work around it.
- The owner's per-app action permissions: from their dashboard's
  Connectors page the owner picks exactly which of an app's actions
  agents may execute (set when connecting, editable any time after). A
  disabled action is refused with `not_allowed` and hidden from
  `connectors__list_tools`. Ask the owner to enable the action — the
  change applies immediately, no re-linking needed.
- Discovery (list/get) is uncapped and read-only.

## Troubleshooting

- "not configured" — no Composio key on this plane. Tell the owner to set
  `COMPOSIO_API_KEY`.
- A tool needing auth fails — check `connectors__list_connections`: the
  toolkit's connection is probably missing or not ACTIVE. Mint a fresh
  hand-off with `connectors__connect` and have the owner re-authorize.
  An INACTIVE connection means the owner paused it — ask them, do not try
  to re-link around it.
- A tool is refused as a "disabled action" — the owner turned that action
  off in the app's agent permissions. Name the action and ask them to
  enable it under Connectors -> Permissions; it applies immediately.
- The APP rejects a call for missing permissions — the connection's OAuth
  grant lacks a scope. The owner can edit the toolkit's requested scopes
  from their dashboard's Connectors page (Permissions) and then re-link
  the app to re-consent. Point them there and say which scope the app
  asked for.
- Missing-scope error from the PLANE — the token lacks `connectors`; ask
  the owner to mint one with the scope.

Disconnecting, pausing/resuming, action permissions, and scope management
are owner dashboard flows by design — there is no agent tool for them,
matching how linking consent works.
