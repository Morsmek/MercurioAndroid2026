import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("OnboardingCard security regression", () => {
  const source = readFileSync(resolve(__dirname, "onboarding-card.tsx"), "utf8");

  it("does not render a TextInput during initial identity creation", () => {
    expect(source).not.toContain("TextInput");
    expect(source).not.toContain("onChangeText");
    expect(source).not.toContain("Display name");
  });

  it("creates identity without passing a user-provided name", () => {
    expect(source).toContain("await createIdentity();");
    expect(source).not.toContain("await createIdentity(name)");
  });
});
