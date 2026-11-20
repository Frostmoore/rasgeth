// A Claude Code stand-in for the demo (3.9.8, DEMO_CLAUDE_ENGINE=1): the Agent SDK's surface that
// Rasgeth's real Claude adapter drives, in the process, no network and no model. Like Claude Code
// it lists the MCP tools once per run, refuses one it does not list, runs the PostToolUse hooks
// after each call (and ends the run when one says `continue: false`), reports the plan's limits
// as the SDK does (one window per `rate_limit_event`; the full reading only while it runs).
// Its "model": asked about the machines, it switches them on and lists them in the same turn.

let calls = [];
export function demoClaudeSdk() {
  return {
    tool: (name, _description, _shape, handler) => ({ name, handler }),
    createSdkMcpServer: (o) => o,
    query({ prompt, options }) {
      const listed = options.mcpServers.redgiant.tools;
      const allowed = options.allowedTools ?? [];
      const visible = listed
        .map((t) => t.name)
        .filter((n) => allowed.includes(`mcp__redgiant__${n}`));
      const hooks = (options.hooks?.PostToolUse ?? []).flatMap((h) => h.hooks);
      const session = options.resume ?? `demo-claude-${Date.now()}`;
      let closing = false;
      const usage = { input_tokens: 1200, cache_read_input_tokens: 9000, output_tokens: 80 };
      const say = (content) => ({
        type: "assistant",
        parent_tool_use_id: null,
        session_id: session,
        message: { model: options.model, usage, content },
      });
      async function* run() {
        let text = "";
        for await (const m of prompt) {
          text = m.message.content.find((c) => c.type === "text")?.text ?? "";
          break;
        }
        yield { type: "system", subtype: "init", session_id: session };
        if (!/macchin|machine/i.test(text) && !text.includes("ready now")) calls = [];
        yield {
          type: "rate_limit_event",
          rate_limit_info: {
            status: "allowed",
            rateLimitType: "five_hour",
            utilization: 0.07,
            resetsAt: Math.floor(Date.now() / 1000) + 3 * 3600,
          },
        };
        for (let i = 0; i < 6; i++) {
          let step;
          if (calls.length === 0 && /macchin|machine/i.test(text))
            step = {
              tool: "request_tool",
              input: { tool: "machines", why: "per vedere le macchine" },
            };
          else if (calls.at(-1) === "request_tool" && visible.includes("ssh_list"))
            step = { tool: "ssh_list", input: {} };
          else if (calls.at(-1) === "request_tool")
            step = {
              tool: "request_tool",
              input: { tool: "ssh_list", why: "non riesco a chiamarlo" },
            };
          if (!step) {
            const done = calls.includes("ssh_list")
              ? "Ho acceso le macchine e le ho elencate nello stesso turno."
              : "Fatto.";
            yield say([{ type: "text", text: done }]);
            closing = true;
            yield { type: "result", subtype: "success", session_id: session, result: done };
            return;
          }
          const id = `toolu_demo_${Date.now()}_${i}`;
          calls.push(step.tool);
          yield say([
            { type: "tool_use", id, name: `mcp__redgiant__${step.tool}`, input: step.input },
          ]);
          const tool = listed.find((t) => t.name === step.tool);
          if (!tool || !visible.includes(step.tool)) continue;
          await tool.handler(step.input, { _meta: { "claudecode/toolUseId": id } });
          let go = true;
          for (const h of hooks) if ((await h()).continue === false) go = false;
          if (!go) {
            closing = true;
            yield { type: "result", subtype: "success", session_id: session, result: "" };
            return;
          }
        }
      }
      const it = run();
      it.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET = async () =>
        closing
          ? new Promise(() => {})
          : {
              rate_limits: {
                five_hour: { utilization: 7, resets_at: null },
                seven_day: { utilization: 12, resets_at: null },
              },
            };
      return it;
    },
  };
}
