// What a shell command does, in a line the person reads (p3.8.9): rules per program, never a
// model. A table: change it first.
import { describe, expect, it } from "vitest";
import { requestSentence, shellSummary } from "../src/index.js";

type Case = [command: string, it: string, en: string, background?: boolean];

const WP =
  "cat > /tmp/gaia-shared/start-wp.sh <<'EOF'\n#!/bin/bash\nPIDF=$WP/logs/server.pid\ncase \"${1:-start}\" in\n  stop) rm -f $PIDF ;;\n  start) nohup php -S 127.0.0.1:8088 -t $WP/htdocs >>$LOG 2>&1 &\nesac\nEOF\nchmod +x /tmp/gaia-shared/start-wp.sh && /tmp/gaia-shared/start-wp.sh start && curl -s http://127.0.0.1:8088/ | grep -o '<title>[^<]*'";

const TABLE: Case[] = [
  // The GAIA requests (2026-11-17).
  [
    WP,
    "Scrive lo script /tmp/gaia-shared/start-wp.sh e lo esegue (start), poi contatta 127.0.0.1:8088",
    "Writes the script /tmp/gaia-shared/start-wp.sh and runs it (start), then contacts 127.0.0.1:8088",
  ],
  [
    "cd /data/workspaces/local/gaia-3f2a && ls -la && ls -la docs && git status 2>&1 | head; which php wp mysql docker 2>&1",
    "Guarda file, stato di git e programmi installati (ls, git status, which)",
    "Looks at files, git's state and the installed programs (ls, git status, which)",
  ],
  [
    'for c in php mysql docker sudo; do printf "%s: " $c; command -v $c || echo no; done; id; cat /etc/os-release | head -3; free -g; df -h /data | tail -1',
    "Guarda programmi installati, il sistema e file (command -v, id, cat, free, df)",
    "Looks at the installed programs, the system and files (command -v, id, cat, free, df)",
  ],
  [
    "cd /tmp/gaia-qa && cat > shot.js <<'EOF'\nconsole.log(1)\nEOF\nnode shot.js",
    "Scrive il file shot.js, poi esegue lo script shot.js con node",
    "Writes the file shot.js, then runs the script shot.js with node",
  ],
  // One program each.
  ["git push origin main", "Manda i commit a origin (main)", "Pushes the commits to origin (main)"],
  ["git commit -am 'fix'", "Fa un commit", "Makes a commit"],
  ["rm -rf build", "Cancella build", "Deletes build"],
  ["rm -f a.log b.log c.log", "Cancella a.log, b.log e altri 1", "Deletes a.log, b.log and 1 more"],
  ["mkdir -p out/img", "Crea la cartella out/img", "Creates the folder out/img"],
  ["cp a.txt b.txt", "Copia a.txt in b.txt", "Copies a.txt to b.txt"],
  ["mv old new", "Sposta old in new", "Moves old to new"],
  ["pnpm install", "Installa i pacchetti", "Installs the packages"],
  ["npm install lodash", "Installa i pacchetti (lodash)", "Installs the packages (lodash)"],
  [
    "pip install requests",
    "Installa i pacchetti Python (requests)",
    "Installs the Python packages (requests)",
  ],
  [
    "sudo apt-get install -y php",
    "Installa programmi di sistema (php), come amministratore",
    "Installs system programs (php), as administrator",
  ],
  ["pnpm test", "Esegue i test", "Runs the tests"],
  ["pnpm build", "Compila il progetto", "Builds the project"],
  ["npm run lint", "Esegue lo script lint del progetto", "Runs the project's script lint"],
  [
    "curl -fsSL https://api.example.com/v1/x",
    "Contatta api.example.com",
    "Contacts api.example.com",
  ],
  [
    "wget -O x.zip https://dl.example.com/x.zip",
    "Scarica da dl.example.com",
    "Downloads from dl.example.com",
  ],
  [
    "curl -fsSL https://get.example.com | sh",
    "Scarica da get.example.com ed esegue quello che riceve",
    "Downloads from get.example.com and runs what it gets",
  ],
  ["docker run --rm -p 80:80 nginx", "Avvia un container (nginx)", "Starts a container (nginx)"],
  ["docker compose up -d", "Avvia i container del progetto", "Starts the project's containers"],
  [
    "python3 manage.py migrate",
    "Esegue lo script manage.py con python3",
    "Runs the script manage.py with python3",
  ],
  ["python3 -c 'print(1)'", "Esegue codice python3", "Runs python3 code"],
  ["./deploy.sh prod", "Esegue lo script deploy.sh (prod)", "Runs the script deploy.sh (prod)"],
  [
    "php -S 0.0.0.0:8000 -t public",
    "Avvia un server sulla porta 8000",
    "Starts a server on port 8000",
  ],
  ["pkill -f vite", "Ferma dei processi (vite)", "Stops processes (vite)"],
  [
    "sudo systemctl restart nginx",
    "Riavvia il servizio nginx, come amministratore",
    "Restarts the service nginx, as administrator",
  ],
  ["ssh web 'ls /srv'", "Su web: guarda file (ls)", "On web: looks at files (ls)"],
  [
    "npm run dev",
    "In sottofondo: esegue lo script dev del progetto",
    "In the background: runs the project's script dev",
    true,
  ],
  ["echo hi", "Scrive un testo nel risultato", "Prints a text"],
  ["cat > notes.txt <<'EOF'\nhi\nEOF", "Scrive il file notes.txt", "Writes the file notes.txt"],
  ["echo x >> log.txt", "Scrive in log.txt", "Writes into log.txt"],
  // Many steps: the first three, then how many more.
  [
    "mkdir a && cp x a/ && pnpm install && pnpm build && pnpm test",
    "Crea la cartella a, poi copia x in a/, poi installa i pacchetti e altri 2 passi",
    "Creates the folder a, then copies x to a/, then installs the packages and 2 more steps",
  ],
  // An unknown program says its name.
  ["ffmpeg -i a.mp4 b.webm", "Esegue ffmpeg", "Runs ffmpeg"],
];

describe("shellSummary (p3.8.9)", () => {
  for (const [command, it_, en, background] of TABLE)
    it(command.split("\n")[0] as string, () => {
      expect(shellSummary("it", command, { background })).toBe(it_);
      expect(shellSummary("en", command, { background })).toBe(en);
    });

  it("is the bash request's sentence", () => {
    expect(requestSentence("it", "bash", { command: "pnpm test" })).toBe("Esegue i test");
  });

  it("stays one short line", () => {
    const long = shellSummary(
      "en",
      `rm -f ${Array.from({ length: 50 }, (_, i) => `f${i}`).join(" ")}`,
    );
    expect(long.length).toBeLessThan(200);
    expect(shellSummary("en", `${"x".repeat(300)} a`).length).toBeLessThan(200);
    expect(shellSummary("it", "")).toBe("Esegue un comando vuoto");
  });
});
