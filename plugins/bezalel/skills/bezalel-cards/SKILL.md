---
name: bezalel-cards
description: Mint and manage hard-capped virtual cards through Bezalel's cards domain, including the full purchase flow and both approval mechanisms. Use when a task requires paying for something online.
---

# Bezalel cards

Virtual cards funded from the owner's Agentcard balance. The plane enforces
hard server-side limits: a per-card cap, a rolling daily aggregate cap, a
daily card-count cap, and a per-agent daily budget. A blocked creation names
the exceeded limit — report it to the owner; do not retry in a loop.

## Purchase end-to-end

1. `cards__get_balance` — confirm funds cover the purchase.
2. `cards__create_card` `{ amountCents, type? }` — integer cents, min 100.
   `single_use` (default) closes after the first charge; `multi_use` stays
   open. `scopePreset: "ai_labs"` locks the card to AI-lab merchants.
3. `cards__get_card_details` `{ cardId }` — **SENSITIVE**: reveals the full
   number, CVV, and expiry. Use them only at checkout; never log, repeat,
   or store them.
4. Pay at checkout with the revealed details.
5. `cards__list_transactions` `{ cardId }` — watch the charge go
   PENDING → SETTLED; investigate DECLINED with the owner.
6. `single_use` cards close themselves; close a finished `multi_use` card
   with `cards__close_card`.

## Approvals — two different mechanisms

- `status: "plane_approval_required"` — the amount is above the plane's
  owner-approval threshold. The owner approves it in the **Bezalel
  dashboard** (Card approvals); then retry `cards__create_card` with the
  returned `planeApprovalId`. Approvals expire after 24 hours.
- `status: "approval_required"` — Agentcard's own cross-app approval. The
  owner approves from their **Agentcard email/dashboard**; retry the same
  tool with `approvalId`.
- `status: "kyc_required"` — stop and tell the owner; nothing an agent can
  do.

## Managing cards

- `cards__list_cards` — cards this plane created show `access: owned`;
  other apps' cards show as connected.
- `cards__pause_card` / `cards__resume_card` — block/unblock charges on a
  multi_use card.
- `cards__close_card` — permanent.

If card tools fail with a re-consent message, the plane's terms version
changed — the owner re-consents in their dashboard before card operations
continue.
