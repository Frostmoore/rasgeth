# Privacy in Rasgeth

> Draft for the alpha (2026-11-26), checked against the code.

Rasgeth is **self-hosted**: you install it on your computer or your server, and it keeps your data there. There
is no Rasgeth account and no telemetry: Rasgeth does not send us anything about you or how you use it.

## What stays with you

Everything Rasgeth keeps lives in its data folder (a Docker volume, or the data folder of the desktop app):

- the event log, the source of truth of every conversation and every step an agent takes;
- projects, their files, agents, tasks, automations and the board;
- the Knowledge (your documents and their index), Echo (the search over past conversations), the shared memory
  and the portrait;
- the keychain, encrypted (see [SECURITY.md](SECURITY.md)).

## What leaves, and only when you choose it

Rasgeth talks to other services only for what you set up:

- **Models in the cloud** (subscriptions or API keys) receive what the agent sends them: the conversation, the
  instructions, the files and tool results it reads. Their own privacy terms apply. With a **local model** the
  conversation never leaves your computer.
- **Web search, image, video and voice providers** receive the request they answer.
- **Chats and mailboxes** you connect (Telegram, WhatsApp Business, email) carry the messages through their
  services.
- **GitHub or Gitea** receive the code of the projects you connect to them.
- **Updates**: Rasgeth checks the latest release and the model catalog on GitHub; this reads public files and
  sends nothing about you.

## The portrait and the memory

- **The portrait** is what Rasgeth learns about you from your conversations (preferences, how you like to work),
  so agents do not ask again. You see every trait with where it comes from, you can correct or remove it, and you
  can switch the portrait off. It never keeps secrets.
- **The shared memory** holds only what you tell agents to remember; it refuses things that look like passwords
  or keys.

## Taking things back

- Any message can be erased for good («Delete for good»): it leaves the log, Echo, the portrait and the model
  engine's own transcript.
- Every import can be taken back; a project is archived, not deleted, until you delete it.
- A backup is a file you hold: keys and sign-ins are not in it unless you include the keychain, sealed with a
  passphrase of yours.

## People who write to you

When the message secretary answers your contacts (Telegram, WhatsApp Business), their messages are kept in your
Rasgeth like your own conversations, and reach the model you chose. Tell them, as you would for any assistant.
