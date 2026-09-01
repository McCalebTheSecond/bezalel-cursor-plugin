#!/bin/sh
# Re-fetch Bezalel SKILL.md playbooks from the live plane into this plugin.
# Run from the repository root. Does not touch tokens or MCP config.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/plugins/bezalel/skills"
PLANE="${BEZALEL_PLANE:-https://mcp.bezalel.sh}"
mkdir -p "$DEST"
names="$(curl -fsSL "$PLANE/skills")"
if [ -z "$names" ]; then
  echo "no skill names from $PLANE/skills" >&2
  exit 1
fi
for s in $names; do
  mkdir -p "$DEST/$s"
  curl -fsSL "$PLANE/skills/$s" -o "$DEST/$s/SKILL.md"
  echo "updated $s"
done
