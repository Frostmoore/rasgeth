// 3.8.7: God's work conversation after a restart. Real Postgres hands jsonb back decoded, so a
// stored string («sess_…») arrived as plain text and was decoded a second time, which threw.
import { describe, expect, it } from "vitest";
import { settingValue } from "../src/setting-value.js";

describe("settingValue", () => {
  it.each([
    ["a decoded string, as Postgres gives jsonb", "sess_c2e3c35a-7e7", "sess_c2e3c35a-7e7"],
    ["JSON text of a string", '"sess_1"', "sess_1"],
    ["JSON text of an object", '{"a":1}', { a: 1 }],
    ["an object", { a: 1 }, { a: 1 }],
    ["an array", [1, 2], [1, 2]],
    ["null", null, null],
    ["a number", 3, 3],
  ])("%s", (_name, input, out) => {
    expect(settingValue(input)).toEqual(out);
  });
});
