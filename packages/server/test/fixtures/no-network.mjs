// Preloaded with --import: a machine whose network is unplugged (3.9.1). Every name outside this
// computer is looked up forever, as when the DNS server cannot be reached; connections to
// addresses are refused. Only this computer answers.
import dns from "node:dns";
import net from "node:net";

const local = (host) =>
  !host || host === "localhost" || host.startsWith("127.") || host === "::1" || host === "0.0.0.0";

const lookup = dns.lookup;
dns.lookup = function (host, ...rest) {
  if (local(host)) return lookup.call(this, host, ...rest);
  // Never answers: the caller's own timeout is the only way out. Said on stderr, so a test that
  // fails shows what the server waited for.
  process.stderr.write(`no-network: lookup ${host} (never answered)\n`);
};
const promises = dns.promises.lookup;
dns.promises.lookup = (host, ...rest) =>
  local(host) ? promises(host, ...rest) : new Promise(() => {});

const connect = net.Socket.prototype.connect;
net.Socket.prototype.connect = function (...args) {
  const o = typeof args[0] === "object" && args[0] !== null ? args[0] : { host: args[1] };
  const host = o.host;
  if (o.path || local(host) || !net.isIP(host ?? "")) return connect.apply(this, args);
  process.nextTick(() =>
    this.destroy(Object.assign(new Error(`connect ENETUNREACH ${host}`), { code: "ENETUNREACH" })),
  );
  return this;
};
