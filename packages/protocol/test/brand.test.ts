// The product's name in one place (plan 3.9.0, N1); apps/companion/test/brand_test.dart checks
// that the app says the same.
import { describe, expect, it } from "vitest";
import { DESKTOP_APP_NAME, PRODUCT_NAME } from "../src/index.js";

describe("brand", () => {
  it("is Rasgeth, and the app alone on a computer is Rasgeth App", () => {
    expect(PRODUCT_NAME).toBe("Rasgeth");
    expect(DESKTOP_APP_NAME).toBe("Rasgeth App");
  });
});
