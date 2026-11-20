// A `codex app-server` in miniature for the same-turn tools test (3.9.8). As the real one, a
// thread's dynamic tools are those of `thread/start` (`thread/resume` and `turn/start` take none),
// and a call to a tool the thread does not have never reaches the client. Its "model": switch the
// machines on, then list them if ssh_list is there, else ask for it again (what God did on Coder
// on 2026-11-20), then answer.
import { createInterface } from "node:readline";

const send = (m) => process.stdout.write(`${JSON.stringify(m)}\n`);
const threads = new Map();
let nextThread = 0;
let nextRequest = 9000;
const waiting = new Map();

const usage = (threadId) => ({
  method: "thread/tokenUsage/updated",
  params: {
    threadId,
    turnId: "tu",
    tokenUsage: {
      modelContextWindow: 400000,
      total: {},
      last: { totalTokens: 2, inputTokens: 1, cachedInputTokens: 0, outputTokens: 1 },
    },
  },
});

function call(threadId, tool, args) {
  const th = threads.get(threadId);
  const id = nextRequest++;
  const callId = `call_${id}`;
  th.calls.push(tool);
  if (!th.tools.includes(tool)) {
    // Codex: a tool the thread was not given is not a tool.
    return Promise.resolve(`unsupported call: ${tool}`);
  }
  return new Promise((ok) => {
    waiting.set(id, ok);
    send({
      id,
      method: "item/tool/call",
      params: { threadId, turnId: "tu", callId, tool, arguments: args },
    });
    send(usage(threadId));
  });
}

async function runTurn(threadId) {
  const th = threads.get(threadId);
  for (;;) {
    const n = th.calls.length;
    if (n === 0) await call(threadId, "request_tool", { tool: "machines", why: "to look at them" });
    else if (n === 1 && th.tools.includes("ssh_list")) await call(threadId, "ssh_list", {});
    else if (n === 1)
      await call(threadId, "request_tool", { tool: "ssh_list", why: "it is not callable" });
    else break;
  }
  send({
    method: "item/completed",
    params: {
      threadId,
      turnId: "tu",
      completedAtMs: 0,
      item: { type: "agentMessage", id: "msg", text: `done: ${th.calls.join(", ")}` },
    },
  });
  send(usage(threadId));
  send({ method: "turn/completed", params: { threadId, turn: { id: "tu", status: "completed" } } });
}

createInterface({ input: process.stdin }).on("line", (line) => {
  const m = JSON.parse(line);
  if (m.id !== undefined && !m.method) {
    const ok = waiting.get(m.id);
    waiting.delete(m.id);
    ok?.(m.result?.contentItems?.[0]?.text ?? "");
    return;
  }
  switch (m.method) {
    case "initialize":
      return send({ id: m.id, result: { userAgent: "fake" } });
    case "thread/start": {
      const id = `th-${++nextThread}`;
      threads.set(id, { tools: (m.params.dynamicTools ?? []).map((t) => t.name), calls: [] });
      return send({ id: m.id, result: { thread: { id } } });
    }
    case "thread/resume":
      return send({ id: m.id, result: { thread: { id: m.params.threadId } } });
    case "turn/start":
      send({ id: m.id, result: { turn: { id: "tu", status: "inProgress", items: [] } } });
      void runTurn(m.params.threadId);
      return;
    case "turn/interrupt":
      return send({ id: m.id, result: {} });
    default:
      if (m.id !== undefined) send({ id: m.id, result: {} });
  }
});
