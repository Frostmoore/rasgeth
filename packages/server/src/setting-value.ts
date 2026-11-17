/**
 * A value read from `rg_settings` (jsonb). Real Postgres hands back jsonb already decoded, so a
 * stored JSON string arrives as a plain string ("sess_…"), while other drivers and older rows give
 * the JSON text ("\"sess_…\""). Decoding twice threw (3.8.7: God's work conversation after a
 * restart). Text that is not JSON is the value itself.
 */
export function settingValue(value: unknown): unknown {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}
