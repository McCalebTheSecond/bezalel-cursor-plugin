# Bezalel Cursor plugin

Cursor plugin that ships the **Bezalel skill playbooks** (and a standing prefer-Bezalel rule) to every Cloud Agent, the Agent Window, the IDE, and the CLI.

This is **not** a project-skills pack. Putting `SKILL.md` files in one repo's `.cursor/skills` or `.agents/skills` only covers Cloud Agents that clone that repo. Cursor does **not** copy `~/.cursor/skills` onto Cloud Agent VMs. The cloud-wide vehicle is a **team marketplace plugin** set to **Required** or **Default On**.

MCP tools are separate. Register the HTTP server once (you already did this for MCP):

- Personal Cloud Agents: [cursor.com/agents](https://cursor.com/agents) → **MCP** dropdown → custom HTTP server
- Team Cloud Agents: Dashboard sidebar → **Integrations** → Team MCP Servers

Do **not** put Bezalel on a Cloud Agent environment snapshot. Do **not** use Dashboard → Settings for this.

Plane: `https://mcp.bezalel.sh`  
Skills index: `GET https://mcp.bezalel.sh/skills`  
Each playbook: `GET https://mcp.bezalel.sh/skills/<name>`

## What this plugin contains

| Path | What it is |
| --- | --- |
| `plugins/bezalel/skills/*/SKILL.md` | Live playbooks from the plane |
| `plugins/bezalel/rules/bezalel.mdc` | Always-on rule: prefer Bezalel tools |
| `.cursor-plugin/marketplace.json` | Team marketplace manifest for **Import from Repo** |

No `mcp.json` and no token. Cloud Agent HTTP MCP stays on the MCP dropdown / Integrations. Putting MCP in the plugin would duplicate that path and is the wrong Cloud Agent vehicle.

## Skill names (all of these must be included)

- `bezalel-cards`
- `bezalel-computer`
- `bezalel-connectors`
- `bezalel-email`
- `bezalel-finance`
- `bezalel-imessage`
- `bezalel-memory`
- `bezalel-plane`
- `bezalel-sandbox`

## Attach it team-wide (you click this; agents cannot)

Use the **Plugins** item in the dashboard sidebar (same row as Cloud Agents, Integrations, Members). Not Settings. Not Integrations (that page is MCP).

### If a Team Marketplace already exists (including **Default**)

Teams plans allow **one** team marketplace. If Cursor already created **Default** when you added Team MCP, add this plugin to that marketplace — do not try to create a second one.

1. Open the Cursor dashboard.
2. Sidebar → **Plugins**.
3. Open your existing Team Marketplace (**Default**, or whatever it is named).
4. **Add to Marketplace** / import this GitHub repository:
   - `https://github.com/McCalebTheSecond/bezalel-cursor-plugin`
5. Confirm the plugin named **`bezalel`** is listed (9 skills + 1 rule).
6. Set its installation mode to **Required** (always installed, cannot be uninstalled). Use **Default On** only if you want opt-out.
7. Marketplace Settings → Marketplace Access = the whole team. Turn on **Enable Auto Refresh** if the Cursor GitHub App can read this repo. Save.

### If there is no Team Marketplace yet

1. Open the Cursor dashboard.
2. Sidebar → **Plugins**.
3. Under **Team Marketplaces**, click **Add Marketplace**.
4. **Import from Repo** and paste `https://github.com/McCalebTheSecond/bezalel-cursor-plugin`.
5. **Add to Marketplace** and review the **`bezalel`** plugin.
6. Set installation mode to **Required** (or **Default On**).
7. Marketplace Settings → Marketplace Access = the whole team. Optionally **Enable Auto Refresh**. Save.

New Cloud Agent runs should then load plugin skills the same way they already load official Cursor Marketplace plugins (those land under `~/.cursor/plugins/cache` on the VM). Existing in-flight runs will not pick it up until a new run.

If import cannot see a private repo, grant the **Cursor** GitHub App access to `bezalel-cursor-plugin`, or keep the repo public (this copy has no secrets).

## What this does *not* do

- It does not replace the Cloud Agents **MCP** dropdown or Dashboard → **Integrations**.
- It does not install `~/.cursor/skills` on anyone's laptop into Cloud Agent VMs.
- It does not magically sync from some other working tree. Cursor indexes **this** GitHub repo when you import it under **Plugins**.
