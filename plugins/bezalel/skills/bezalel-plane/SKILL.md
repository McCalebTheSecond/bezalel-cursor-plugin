---
name: bezalel-plane
description: Connect an agent to the Bezalel capability plane over MCP and debug auth or scope issues. Use when wiring a new consumer (eve, OpenClaw, Claude Code, Cursor) or when bezalel tools are missing or failing with scope errors.
---

# Bezalel plane

Bezalel is a personal capability plane: one MCP server that owns capabilities
(finance, cards, and more) and serves them to any agent runtime. Connecting
takes exactly two values: a URL and a bearer token.

## Connect

- **Claude Code / Cursor** — `.mcp.json`:

  ```json
  {
    "mcpServers": {
      "bezalel": {
        "type": "http",
        "url": "http://localhost:3020/mcp",
        "headers": { "Authorization": "Bearer <token>" }
      }
    }
  }
  ```

- **eve** — a connection file:

  ```ts
  export default defineMcpClientConnection({
    name: "bezalel",
    url: `${process.env.BEZALEL_URL ?? "http://localhost:3020"}/mcp`,
    authorization: process.env.BEZALEL_TOKEN!
  })
  ```

- **OpenClaw** — `openclaw mcp add bezalel --transport streamable-http --url http://localhost:3020/mcp --header "Authorization: Bearer <token>"` (see docs/openclaw.md in the repo).

Tokens are minted by the owner: `POST /admin/agents` with the admin token
(or the dashboard's Agents page), body `{"name": "...", "scopes": [...]}`. The
raw token is returned exactly once — store it immediately.

## Verify

Call `health__check`. It returns `status: ok` plus the agent name and scopes
you are authenticated as. If anything else seems broken, start here.

## Token model

- Scopes name capability domains: `health`, `finance`, `cards`.
- `tools/list` shows only the tools your scopes can call; every call is
  ALSO re-checked server-side with a descriptive denial.
- Clients cache tool lists per session — after a scope change, reconnect
  (re-initialize) to see the new tool set.

## Troubleshooting

- **401 Unauthorized** — missing, malformed, unknown, or revoked bearer
  token. Ask the owner to mint a new one; revoked tokens never come back.
- **503 Service unavailable** — the plane's store is unreachable (retry
  shortly), or the admin surface has no BEZALEL_ADMIN_TOKEN configured.
- **"Token is missing the '<scope>' scope"** — report the error verbatim
  and ask the owner for a broader token. Do not retry the call.
