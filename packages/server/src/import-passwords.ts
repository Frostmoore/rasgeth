// import_passwords (3.9.8): an agent that finds a password manager's export in its workspace
// proposes to put it in the person's keychain. It never reads the values out: the tool only counts
// the rows, and the page (or the app) shows the person a button; on their yes, in our Modal, the
// server reads the file, imports it and shreds it (`RedGiantCore.importProposedPasswords`).
import type { Tool } from "@redgiant/agent";
import { passwordExportRows } from "@redgiant/protocol";
import type { Workspace } from "@redgiant/tools";
import { z } from "zod";

const Input = z.object({ path: z.string().min(1).max(1000), why: z.string().max(500).optional() });

export function importPasswordsTool(ws: Workspace): Tool {
  return {
    def: {
      name: "import_passwords",
      description:
        "Propose to put a password manager's export (Bitwarden, Avira, Chrome, Edge, Firefox, 1Password, KeePass, or a CSV of sites, users and passwords) that is a file in your workspace into the person's keychain. You never see the values: the person confirms, then the file is imported and destroyed. Never read, print or copy such a file yourself.",
      inputSchema: {
        type: "object",
        properties: {
          path: { type: "string", description: "the export's path in your workspace" },
          why: { type: "string" },
        },
        required: ["path"],
      },
    },
    schema: Input,
    async run(i: z.infer<typeof Input>) {
      if (!(await ws.isFile(i.path).catch(() => false)))
        return { content: `${i.path} is not a file in your workspace.`, isError: true };
      const rows = passwordExportRows(await ws.readText(i.path));
      if (rows === 0)
        return {
          content: `${i.path} is not a password manager's export (no rows with a password).`,
          isError: true,
        };
      return `Proposed to the person: ${rows} ${rows === 1 ? "password" : "passwords"} from ${i.path} into their keychain. They see a button in the conversation; once they confirm, the file is imported and destroyed. Do not read or copy it meanwhile; tell them in their language that the button is there.`;
    },
  } as Tool;
}
