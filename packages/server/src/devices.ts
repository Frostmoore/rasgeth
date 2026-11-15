// Device tokens (G40.1, 3.8): RGCompanion on a phone or a computer signs in with a token of its
// own, bound to the owner, with a name, a platform, when it was made, last used and from where.
// The token in clear exists only in the answer that makes it: the server keeps its SHA-256 (the
// token is 32 random bytes, so a plain hash is enough), never in a log, an event or an answer.
// It is worth the installation's token for apps and the command line (the same capabilities),
// but each one is revoked on its own, at once: the open WebSocket connections with it close
// (`revoked` event). The same function makes the token wherever the device proved who it is:
// a password session (`POST /api/devices`), the password itself (`POST /api/app/pair`), or the
// setup channel of a first start (G40.3: `core.devices.create`).

import { createHash, randomBytes } from "node:crypto";
import { EventEmitter } from "node:events";
import type { SqlClient } from "@redgiant/events";
import type { DevicePlatform, DeviceView } from "@redgiant/protocol";
import type { Principal } from "./auth.js";

const hash = (token: string) => createHash("sha256").update(token).digest("hex");
/** Device tokens start with this, so a leaked one is recognisable (and never a session's). */
export const DEVICE_TOKEN_PREFIX = "rgd_";

// Not `rg_devices`: that was the QR pairing of G24.6, dropped at every start since G24.7.
export async function migrateDevices(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_app_devices (
      id            text PRIMARY KEY,
      owner_id      text NOT NULL,
      token_hash    text NOT NULL UNIQUE,
      name          text NOT NULL,
      platform      text NOT NULL,
      created_at    timestamptz NOT NULL DEFAULT now(),
      last_used_at  timestamptz,
      last_address  text,
      revoked_at    timestamptz
    )`);
}

type Row = {
  id: string;
  owner_id: string;
  name: string;
  platform: string;
  created_at: Date | string;
  last_used_at: Date | string | null;
  last_address: string | null;
};

const iso = (d: Date | string) => new Date(d).toISOString();
const view = (r: Row): DeviceView => ({
  id: r.id,
  name: r.name,
  platform: r.platform as DevicePlatform,
  createdAt: iso(r.created_at),
  lastUsedAt: r.last_used_at ? iso(r.last_used_at) : null,
  lastAddress: r.last_address,
});
const COLUMNS = "id, owner_id, name, platform, created_at, last_used_at, last_address";

export class DeviceStore extends EventEmitter<{
  /** Devices revoked now: their connections close. */
  revoked: [ownerId: string, deviceIds: string[]];
}> {
  /** When each device's use was last written (once a minute, or when its address changes). */
  private readonly seen = new Map<string, { at: number; address: string | undefined }>();
  /** The current name of each device seen (a rename shows in the next answer's `via`). */
  private readonly names = new Map<string, string>();

  constructor(
    private readonly db: SqlClient,
    private readonly o: { now?: () => number } = {},
  ) {
    super();
  }

  private now() {
    return this.o.now?.() ?? Date.now();
  }

  /**
   * A token for a device of `ownerId`: the only time it exists in clear. The caller has already
   * proved who the person is (a password session, the password, the setup channel of G40.3).
   */
  async create(
    ownerId: string,
    d: { name: string; platform: DevicePlatform },
  ): Promise<{ token: string; device: DeviceView }> {
    const id = `dev_${randomBytes(6).toString("hex")}`;
    const token = `${DEVICE_TOKEN_PREFIX}${randomBytes(32).toString("base64url")}`;
    const name = d.name.trim().slice(0, 60) || "Device";
    const [r] = await this.db.query<Row>(
      `INSERT INTO rg_app_devices (id, owner_id, token_hash, name, platform, created_at)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING ${COLUMNS}`,
      [id, ownerId, hash(token), name, d.platform, new Date(this.now()).toISOString()],
    );
    this.names.set(id, name);
    if (!r) throw new Error("The device was not saved");
    return { token, device: view(r) };
  }

  async list(ownerId: string): Promise<DeviceView[]> {
    const rows = await this.db.query<Row>(
      `SELECT ${COLUMNS} FROM rg_app_devices WHERE owner_id = $1 AND revoked_at IS NULL
       ORDER BY created_at, id`,
      [ownerId],
    );
    return rows.map(view);
  }

  async rename(ownerId: string, id: string, name: string): Promise<DeviceView | null> {
    const [r] = await this.db.query<Row>(
      `UPDATE rg_app_devices SET name = $3 WHERE id = $1 AND owner_id = $2 AND revoked_at IS NULL
       RETURNING ${COLUMNS}`,
      [id, ownerId, name.trim().slice(0, 60)],
    );
    if (!r) return null;
    this.names.set(id, r.name);
    return view(r);
  }

  /** Revokes one device at once; false when it is not the owner's (or already revoked). */
  async revoke(ownerId: string, id: string): Promise<boolean> {
    const rows = await this.db.query<{ id: string }>(
      `UPDATE rg_app_devices SET revoked_at = now() WHERE id = $1 AND owner_id = $2 AND revoked_at IS NULL
       RETURNING id`,
      [id, ownerId],
    );
    this.gone(
      ownerId,
      rows.map((r) => r.id),
    );
    return rows.length > 0;
  }

  /** Revokes every device of the owner but `keep` (signed out everywhere, a new password). */
  async revokeAll(ownerId: string, keep?: string): Promise<number> {
    const rows = await this.db.query<{ id: string }>(
      `UPDATE rg_app_devices SET revoked_at = now()
       WHERE owner_id = $1 AND revoked_at IS NULL AND id <> $2 RETURNING id`,
      [ownerId, keep ?? ""],
    );
    this.gone(
      ownerId,
      rows.map((r) => r.id),
    );
    return rows.length;
  }

  private gone(ownerId: string, ids: string[]) {
    if (!ids.length) return;
    for (const id of ids) {
      this.seen.delete(id);
      this.names.delete(id);
    }
    this.emit("revoked", ownerId, ids);
  }

  /** A device's token → its owner and the device; null for anything else or a revoked one. */
  async authenticate(token: string): Promise<Principal | null> {
    if (!token.startsWith(DEVICE_TOKEN_PREFIX)) return null;
    const [r] = await this.db.query<{ id: string; owner_id: string; name: string }>(
      "SELECT id, owner_id, name FROM rg_app_devices WHERE token_hash = $1 AND revoked_at IS NULL",
      [hash(token)],
    );
    if (!r) return null;
    this.names.set(r.id, r.name);
    return { ownerId: r.owner_id, device: { id: r.id, name: r.name } };
  }

  /** The device's name now (after a rename), or undefined when it is unknown here. */
  nameOf(id: string): string | undefined {
    return this.names.get(id);
  }

  /** Remembers that a device was used, and from where (written at most once a minute). */
  async used(id: string, address: string | undefined): Promise<void> {
    const last = this.seen.get(id);
    if (last && this.now() - last.at < 60_000 && last.address === address) return;
    this.seen.set(id, { at: this.now(), address });
    await this.db
      .query(
        `UPDATE rg_app_devices SET last_used_at = $2::timestamptz,
           last_address = COALESCE($3::text, last_address)
         WHERE id = $1 AND revoked_at IS NULL`,
        [id, new Date(this.now()).toISOString(), address?.slice(0, 80) ?? null],
      )
      .catch(() => {});
  }
}
