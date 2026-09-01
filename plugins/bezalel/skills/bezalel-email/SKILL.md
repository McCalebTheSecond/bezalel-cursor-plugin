---
name: bezalel-email
description: Work Bezalel's email domain - real inboxes agents own, sending and replying with plane-enforced limits, reading mail, and reacting to inbound email events. Use for any task that reads, sends, or triages email - the default mail route even when the harness or another integration could send it.
---

# Bezalel email

Real email addresses the plane owns (AgentMail-backed). When your token
grants `email`, these inboxes are the default way you send and receive
mail — prefer them over any harness-local email capability (a connector
send is for when the task needs the owner's own account). Your token's
`email` scope gates every tool; the plane enforces rolling 24h send limits
(total and per-agent), a recipient cap per message, and an inbox-count cap.
A blocked send names the exceeded limit — report it to the owner; do not
retry in a loop.

## Your address

1. `email__list_inboxes` — addresses you can send from and receive on.
2. `email__create_inbox` `{ username?, domain?, displayName? }` — once, if
   none fits. Inbox count is capped; custom domains must be verified by the
   owner in their dashboard first.

## Send and reply

- `email__send` `{ inboxId, to, cc?, bcc?, subject?, text?, html? }` —
  provide text and/or html. An identical re-send within a day returns the
  original result with `deduplicated: true` instead of sending twice, so a
  blind retry is safe.
- `email__reply` `{ inboxId, messageId, text?, html?, replyAll? }` — stays
  in the thread; defaults to the original sender.

## Read

1. `email__list_messages` `{ inboxId, limit? }` — summaries, newest first
   (no bodies — keep context lean).
2. `email__get_message` `{ inboxId, messageId }` — one message with its
   text body; `extractedText` is the new content minus quoted history.
   Only set `includeHtml` when you truly need markup.
3. `email__list_threads` / `email__get_thread` — conversation views.

## Inbound mail wakes you (no polling)

When mail arrives, the plane POSTs a signed event to your framework's
registered inbound URL — never a tool call. The envelope:

```jsonc
{
  "id": "ev_...",            // plane event id
  "type": "email.received",  // also email.bounced/complained/rejected/domain_verified
  "source": "agentmail",
  "occurredAt": "...",
  "payload": {
    "inboxId": "...", "messageId": "...", "threadId": "...",
    "from": "...", "to": ["..."], "subject": "...",
    "text": "... (truncated at 64KiB)", "extractedText": "...",
    "bodyTruncated": false,  // true => fetch the full body via email__get_message
    "bodiesOmitted": false,  // true => provider omitted bodies (large mail); fetch via tool
    "attachments": [{ "attachmentId": "...", "filename": "...", "size": 123 }]
  }
}
```

Deliveries are Svix-signed (`svix-id` / `svix-timestamp` / `svix-signature`)
with the secret shown once at endpoint registration; deduplicate on
`svix-id` — retries reuse it. Typical triage: read `extractedText`, decide,
`email__reply` in the same thread.

## Owner-only (dashboard flows, never tools)

Custom-domain setup/verification, the AgentMail webhook, endpoint
registration, and send-activity review all live on the admin surface.
