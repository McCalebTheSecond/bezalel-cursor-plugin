---
name: bezalel-finance
description: Work Bezalel's finance domain - log, correct, and delete receipts, summarize monthly spend, and read Plaid-linked bank accounts and transactions. Use for any "track my spending / what did I spend" task or bank reconciliation.
---

# Bezalel finance

## Conventions

- All amounts are **integer minor units (cents)**; negative amounts are
  refunds. Never send floats.
- Months are `YYYY-MM`, interpreted in UTC.
- Bank amounts follow Plaid's sign convention: **positive = money out**.

## Log a purchase

1. `finance__log_receipt` `{ merchant, amountCents, category?, note?, occurredAt? }`
   — `occurredAt` defaults to now; `currency` defaults to USD.

## Correct or remove an entry

1. `finance__list_receipts` `{ month?, category? }` — find the receipt id.
2. `finance__update_receipt` `{ id, ...changed fields }` — omitted fields
   stay unchanged; fields cannot be cleared to null.
3. `finance__delete_receipt` `{ id }` — permanent. Confirm with the owner
   before deleting.

## Month summary

- `finance__spend_summary` `{ month }` — totals and per-category breakdown,
  grouped per currency (never summed across currencies). Drill into a
  category with `finance__list_receipts`.

## Bank data workflow

1. `finance__list_accounts` — linked accounts with live balances. A bank
   that needs re-auth shows up under `itemStatuses` (e.g.
   `ITEM_LOGIN_REQUIRED`) without hiding the healthy accounts — surface
   that status to the owner.
2. `finance__sync_transactions` — pull new/changed/removed transactions.
   If `completed` is false, call it again to continue; progress persists.
3. `finance__list_transactions` `{ month?, accountId? }` — read what synced.

Bank linking, unlinking, and cursor resets are owner dashboard/admin flows —
never agent tools. If bank verbs fail with "not configured" or no items
exist, ask the owner to link a bank in their dashboard.
