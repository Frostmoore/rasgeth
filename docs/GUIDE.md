# Using Rasgeth

> Draft for the alpha (2026-11-26). Installing: [INSTALL.md](INSTALL.md). Security: [SECURITY.md](SECURITY.md).
> Privacy: [PRIVACY.md](PRIVACY.md).

## The idea

You talk to **God**, one assistant, from the browser, the RGCompanion app or your chats. Behind it there is a
team: every project has its **orchestrator**, which hands work to **agents** and their **sub-agents**. You see
every conversation and every step, and the important decisions come back to you.

## First steps

1. **Connect a model.** Settings › Models and subscriptions: a subscription, an API key, or a **local model**
   that runs on your computer. Keys go into the keychain; agents never see them.
2. **Talk to God.** Ask in plain words: God answers, or opens a project and gives the work to its team.
3. **Open a project** with a folder of yours, or bring the ones you already have (see *Importing*).

## The page

- **Left bar**: conversations and settings.
- **Middle**: the open conversations, as tabs. While an agent works you see what it is doing; a sub-agent's
  work opens in its own tab.
- **Right**: the project's files, open files and terminals.
- **Settings**: everything else (models, tools, requests, keychain, automations, chats, backups).

The app shows the same things and gets every new function in the same version.

## Requests to you

When an agent needs your yes (a push, a deploy, a message, a key), the request reaches the page and every linked
chat at once; the first answer closes the others. In Settings › Event Horizon you can let your classifier
decide for you («Don't ask me anything»). The truly dangerous requests (system files, deletions for good, secrets
leaving, real payments, Rasgeth's protections) always ask you, and a request with no answer is a no.

## Tools

Every agent gets every base tool, except those you switch off in Settings › Tools, for all agents or for one.
Essential tools cannot be switched off. An agent can ask you for a switched-off tool; with your yes it joins the
running conversation.

## Tasks

When an agent hands work to another, it opens a **task**. A task closes only when a check proves it done (a
command that succeeds), or with a written reason why it cannot be checked.

## Importing

Settings › Import brings what you have elsewhere: conversations, instructions, memory and **whole projects from
Claude Code**. For a project you choose to leave its folder where it is, copy it into Rasgeth, or clone it from its
repository (also from an address you paste, for a Rasgeth on another computer). Its `CLAUDE.md` becomes the
orchestrator's instructions, its notes go into the Knowledge, secret files stay out, and the lines tied to the old
computer are marked for the orchestrator to adapt with you. Every import can be undone.

## Local models

Settings › Models and subscriptions, local models: pick a model from the catalog and Rasgeth downloads it and
runs it on your computer. On the model's card:

- **Deep Field**, Rasgeth's SSD streaming, runs models bigger than your memory by reading them from the disk.
- **Improvements** (Prefetch, Big Chunks, Speculative Decoding, No Repack) can make a model faster on your
  hardware. They are never switched on by themselves: measuring takes time and compute, and may gain nothing.
  A gold border marks what we tested on that model; an improvement that needs hardware you do not have stays
  locked, with the reason.

## Automations

An automation runs an agent on a schedule or when something happens (a webhook, a message). A run never overlaps
the previous one, and what arrives from outside is data for the agent, never an order.

## Backups and updates

Settings › Backup saves your data to a file you keep; keys and sign-ins stay out unless you include the keychain
sealed with a passphrase. Rasgeth checks for new versions and tells you what each one brings; updates are signed.
