---
name: bezalel-imessage
description: Work Bezalel's iMessage domain - texting the owner's paired handle and opted-in group chats through the plane's line, reacting to messages, and handling inbound imessage.received events. Use for any task that reads or sends iMessage texts.
---

# Bezalel iMessage

Texting through the owner's paired line (Photon Spectrum-backed). Your
token's `imessage` scope gates every tool. You never address raw phone
numbers or emails: `imessage__send` with no `spaceId` DMs **the owner**
(the one OTP-verified paired handle), and group chats are reachable only
after the owner opts a space in by speaking in it. The plane enforces
rolling 24h send limits (total and per-agent); a blocked send names the
exceeded limit — report it to the owner, do not retry in a loop.

## Check before texting

`imessage__status` → `{ configured, paired, activeSpaces }`.

- `configured: false` — the plane has no Spectrum provider; every send
  will fail. Tell the owner to set both `SPECTRUM_PROJECT_ID` and
  `SPECTRUM_PROJECT_SECRET`. (`SPECTRUM_API_BASE_URL` is only the local
  spectrum-stub override.)
- `paired: false` — no owner handle is paired. Pairing is an owner
  dashboard flow (an OTP is texted to their handle); you cannot pair for
  them.

## Sending

- `imessage__send { text }` — DM the owner. Max 4000 characters; split
  longer content into separate sends.
- `imessage__send { text, format: "markdown" }` — render bold, lists, and
  links natively on the phone. Prefer this for any formatted reply;
  default `"text"` sends verbatim (asterisks show literally).
- `imessage__send { text, format: "richlink" }` — when the text is exactly
  one https URL, deliver it as a tappable link-preview bubble instead of a
  raw URL string.
- `imessage__send { text, spaceId }` — post in an opted-in group. Get the
  `spaceId` from an inbound `imessage.received` event; a "not opted in"
  error means the owner has not spoken in that group (or deactivated it).
- Identical re-sends within a UTC day are deduplicated: a result with
  `deduplicated: true` means the earlier identical text already went out —
  that is success, not an error. Vary the content if you truly mean to
  repeat yourself.
- `imessage__typing { state: "start" | "stop" }` — cosmetic typing
  indicator in the owner DM while composing something long. Coalesced
  server-side; call start once, then send.

## Attachments (images and files)

`imessage__send_attachment { url, name?, contentType?, spaceId? }` — the
file arrives as a NATIVE attachment bubble (an image shows as a real
picture). The plane downloads the public https URL itself (25 MB cap,
private-network URLs are refused) and delivers the bytes.

- Use this for every screenshot, photo, PDF, or export the owner should
  see. NEVER paste an image URL or `![markdown image](url)` syntax into a
  text — iMessage renders that as plain text, not a picture.
- `name`/`contentType` are inferred from the URL and the response when
  omitted.
- After sending, do not repeat the URL in a follow-up text unless the
  owner asks for a link.

## Polls

`imessage__send_poll { title, options, spaceId? }` — a NATIVE iMessage
poll the owner votes on with a tap. `title` is the question; `options` are
2-12 distinct choices (up to 100 chars each). Use a poll whenever you are
offering choices ("Which flight?", "Pick a restaurant") instead of asking
the owner to type an answer.

Votes come back as `imessage.received` events whose `content` includes a
`poll_vote` arm:

```
{ type: "poll_vote", pollTitle, optionTitle, selected }
```

`selected: true` is a cast vote; `selected: false` means the sender
retracted that choice. Act on the vote like any other owner message.

## Reacting

`imessage__react { emoji, targetMessageId, spaceId? }` — tapback on a
message you RECEIVED. `targetMessageId` must be the `messageId` of an
`imessage.received` event from the same conversation (omit `spaceId` for
the owner DM, pass the event's `spaceId` for a group). Invented or
cross-conversation ids are rejected. Reactions count toward send limits.

## Inbound texts

Texts wake you through your framework's registered event route (Svix-signed
envelope), never a tool. The `imessage.received` payload:

```
{ messageId, isGroup, spaceId?, sender, senderIsOwner,
  text?, content: [ { type: "text" | "attachment" | "voice" | "richlink"
                          | "poll" | "poll_vote", ... } ],
  bodyTruncated }
```

- `senderIsOwner: false` in a group means a guest is speaking. Be
  conservative: guests cannot approve spending, change settings, or read
  the owner's private context through you.
- Attachment/voice arms carry metadata only (name, mimeType, size) — the
  plane does not serve attachment bytes yet.
- Tapbacks on your messages do not generate events (recorded plane-side
  only), so do not wait for reaction confirmations.

## Troubleshooting

- "not paired" — owner must pair in their dashboard (Manage → iMessage).
- "not opted in" (space) — owner must send any message in that group.
- Send limit errors name the env var (`BEZALEL_IMESSAGE_DAILY_MAX_SENDS`,
  `BEZALEL_IMESSAGE_AGENT_DAILY_MAX_SENDS`) — surface to the owner.
- Missing-scope error — the token lacks `imessage`; ask the owner to mint
  one with the scope.
