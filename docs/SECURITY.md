# Security in Rasgeth

> Draft for the alpha (2026-11-26). Every statement here is checked against the code; where a detail lives is
> named so it can be checked again. Before publishing: confirm the reporting address at the end.

Rasgeth runs agents that read and write files, run commands, browse, send messages and spend money on models.
Its security is built on one idea: **the person stays in charge of what matters, and the agents never hold what
they do not need.**

## Who decides

- **Every agent works inside a scope.** God, Demi-God, orchestrators, agents and sub-agents each see and change
  only what their place allows. The rules are one pure function (`can` in `packages/hierarchy/src/scopes.ts`),
  tested as a table.
- **Approvals never turn into a yes by accident.** A request that fails or times out is a no. The only «yes» not
  given by the person is the person's own classifier, when they choose «don't ask me anything»: it is an explicit
  decision with its reason in the log, and a classifier that fails is a no.
- **Event Horizon: the truly dangerous requests always reach the person**, whatever the rules, the mode or the
  classifier, on the page and on every linked chat at once; if the time runs out, the answer is no
  (`criticalOf` in `packages/hierarchy/src/critical.ts`, tested as a table). They are:
  - writing or deleting in the system's and programs' folders, the Windows registry, drivers, services, users;
  - deletions nothing brings back (recursive deletes outside the project, a disk, a database, a repository, a
    forced push over a shared branch);
  - a password, key, token or keychain value leaving (committed, posted, sent to a host that is not its own);
  - payments with real money;
  - switching off Rasgeth's own protections.

  An ordinary `git push`, a deploy or a message follows the person's normal choices.
- **Archived projects only read.** Archiving stops a project's turns, pauses its automations and sandboxes, and
  every gate refuses changes until it is restored. Nothing is deleted.

## Keys and credentials

- **The keychain** keeps every key Rasgeth holds: model providers, chats, mailboxes, MCP sign-ins, GitHub and
  Gitea (`packages/server/src/vault.ts`).
  - At rest it is one file, encrypted with **AES-256-GCM**, under Rasgeth's data folder and never inside a
    project or a git repository: the keychain refuses to open there.
  - The master key is protected by the system where it can be (DPAPI on Windows, the Keychain on a Mac), or kept
    in a file readable only by its owner (Linux and Docker).
- **Agents never see a value.** They name a credential and Rasgeth puts the value on the request on its way out,
  only towards the hosts the person allowed; an answer that repeats it comes back hidden.
- **Every use is recorded** (who, when, where to), and the person chooses for each credential who may use it and
  whether to be asked every time, once per conversation, or never.
- **Secrets never reach a log in clear**: values are added to the event log's redactor.
- **Sandboxes get no secrets.** Credentials for GitHub, Gitea and tools live in the egress proxy as routes; the
  sandbox's environment never carries them.
- **Sign-in passwords** are stored with scrypt.

## Agents' work

- **Commands run in containers**, not on the person's computer directly; file tools work in the project's folder.
  Programs are started without a shell whenever an argument may come from a model or a person.
- **Network access goes through the egress proxy**, which holds the credential routes and the policy.
- **Extensions never install themselves.** An agent's proposal is tested in a throwaway sandbox and waits for the
  person. Only the person's own extensions install directly once their tests pass; by the person's choice an agent's
  _skill_ (instructions only) can install once tested, never a tool that runs code.
- **Webhook bodies are data, never instructions**: an automation started by a webhook reads the body as content.
- **Platform changes** (Rasgeth changing itself) keep what was there before and can be undone; code changes go
  through a separate copy, tests and a trial run with a clean environment, without secrets.

## Updates, backups, imports

- **Every release carries a signed `release.json`.** Whether an update is mandatory or breaking counts only with a
  valid signature of Rasgeth's update key; the Windows launcher checks the same key.
- **Backups carry no keys and no sign-ins**: they belong to the computer. The one exception is the person's
  choice to include the keychain, sealed with a passphrase of theirs, never in clear.
- **Imports never copy secrets**: `.env` files, private keys and certificates found in a project stay out, and the
  preview says so. A token used to clone a repository goes to git through its environment, never in its arguments
  or in a message.

## Reporting a vulnerability

Please report security problems privately: open a private security advisory on the project's GitHub repository
(_Security › Report a vulnerability_). Do not open a public issue for a vulnerability.

<!-- TO CONFIRM before publishing: private vulnerability reporting enabled on GitHub, or another address. -->
