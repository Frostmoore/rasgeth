// A `codex app-server` in miniature for the tests: JSON-RPC lines on stdio, one scripted turn
// that calls a dynamic tool, then answers with what the tool returned. Like the real one, each
// model request's usage (`thread/tokenUsage/updated`) comes after that request's items and tool
// calls, while the tool still runs; its context window is the engine's own (475000).
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createInterface } from "node:readline";

const send = (m) => process.stdout.write(`${JSON.stringify(m)}\n`);
const log = [];
const usage = (input, cached, output) => ({
  method: "thread/tokenUsage/updated",
  params: {
    threadId: "th-1",
    turnId: "tu-1",
    tokenUsage: {
      modelContextWindow: 475000,
      total: {},
      last: {
        totalTokens: input + output,
        inputTokens: input,
        cachedInputTokens: cached,
        cacheWriteInputTokens: 0,
        outputTokens: output,
        reasoningOutputTokens: 10,
      },
    },
  },
});
let toolCall;
let threads = 0;
createInterface({ input: process.stdin }).on("line", (line) => {
  const m = JSON.parse(line);
  if (m.method) log.push(m.method);
  if (m.id !== undefined && !m.method) {
    // Our answer to the dynamic tool call.
    const text = m.result.contentItems[0].text;
    send({
      method: "item/completed",
      params: {
        threadId: "th-1",
        turnId: "tu-1",
        completedAtMs: 0,
        item: { type: "agentMessage", id: "i2", text: `Tool said ${text} (${m.result.success})` },
      },
    });
    send(usage(1400, 1000, 100));
    send({
      method: "account/rateLimits/updated",
      params: {
        rateLimits: {
          primary: { usedPercent: 21, windowDurationMins: 300, resetsAt: 1793600000 },
          secondary: { usedPercent: 48, windowDurationMins: 10080, resetsAt: null },
        },
      },
    });
    send({
      method: "turn/completed",
      params: { threadId: "th-1", turn: { id: "tu-1", status: "completed", items: [] } },
    });
    return;
  }
  switch (m.method) {
    case "initialize":
      return send({ id: m.id, result: { userAgent: "fake" } });
    case "thread/start":
      threads++;
      process.stderr.write(JSON.stringify(m.params));
      return send({
        id: m.id,
        result: { thread: { id: "th-1" }, model: m.params.model, echo: m.params },
      });
    case "thread/resume":
      return send({ id: m.id, result: { thread: { id: m.params.threadId } } });
    case "turn/start":
      send({ id: m.id, result: { turn: { id: "tu-1", status: "inProgress", items: [] } } });
      send({
        method: "item/completed",
        params: {
          threadId: m.params.threadId,
          turnId: "tu-1",
          completedAtMs: 0,
          item: { type: "reasoning", id: "i0", summary: ["Need the tool."], content: [] },
        },
      });
      if (m.params.input[0].text === "draw") {
        // Codex's own image tool (2026-11-19): it says it starts, saves the picture under its
        // CODEX_HOME's generated_images/ and says it is done with the file's path.
        const at = { threadId: m.params.threadId, turnId: "tu-1" };
        const item = { type: "imageGeneration", id: "ig_1", revisedPrompt: "A crowned star" };
        send({
          method: "item/started",
          params: { ...at, item: { ...item, status: "inProgress" } },
        });
        const dir = join(process.env.CODEX_HOME, "generated_images", "th-1");
        mkdirSync(dir, { recursive: true });
        const file = join(dir, "ig_1.png");
        // A 1x1 PNG.
        writeFileSync(
          file,
          Buffer.from(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
            "base64",
          ),
        );
        setTimeout(() => {
          send({
            method: "item/completed",
            params: {
              ...at,
              completedAtMs: 0,
              item: { ...item, status: "completed", savedPath: file, result: "" },
            },
          });
          send({
            method: "item/completed",
            params: {
              ...at,
              completedAtMs: 0,
              item: { type: "agentMessage", id: "i3", text: "Here it is." },
            },
          });
          send(usage(1300, 0, 50));
          send({
            method: "turn/completed",
            params: { threadId: m.params.threadId, turn: { id: "tu-1", status: "completed" } },
          });
        }, 30);
        return;
      }
      if (m.params.input[0].text === "fail") {
        send({
          method: "turn/completed",
          params: {
            threadId: m.params.threadId,
            turn: {
              id: "tu-1",
              status: "failed",
              error: { message: "401 Unauthorized: log in again" },
              items: [],
            },
          },
        });
        return;
      }
      toolCall = {
        id: 900,
        method: "item/tool/call",
        params: {
          threadId: m.params.threadId,
          turnId: "tu-1",
          callId: "call_1",
          namespace: null,
          tool: "read_file",
          arguments: { path: "a.txt" },
        },
      };
      send(toolCall);
      // The first request's usage, once its stream has ended (the tool is still running).
      send(usage(1200, 0, 40));
      return;
    case "model/list":
      return send({
        id: m.id,
        result: {
          data: [
            { id: "gpt-6", model: "gpt-6", hidden: false },
            { id: "old", model: "old", hidden: true },
          ],
          nextCursor: null,
        },
      });
    case "account/rateLimits/read":
      return send({
        id: m.id,
        result: {
          rateLimits: {
            primary: { usedPercent: 5, windowDurationMins: 300, resetsAt: null },
            secondary: null,
          },
        },
      });
    case "account/login/start":
      setTimeout(
        () =>
          send({
            method: "account/login/completed",
            params: { loginId: "L1", success: true, error: null },
          }),
        20,
      );
      return send({
        id: m.id,
        result: {
          type: "chatgptDeviceCode",
          loginId: "L1",
          verificationUrl: "https://auth.openai.com/codex/device",
          userCode: "ABCD-1234",
        },
      });
    case "debug/log":
      return send({ id: m.id, result: { log, threads } });
  }
});
