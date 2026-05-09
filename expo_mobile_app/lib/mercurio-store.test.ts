import { describe, expect, it, vi } from "vitest";

vi.mock("@react-native-async-storage/async-storage", () => ({
  default: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
  },
}));

describe("Mercurio helper functions", async () => {
  const { initials, formatRelativeTime } = await import("./mercurio-store");

  it("creates compact two-letter initials for contact avatars", () => {
    expect(initials("Alice Rivera")).toBe("AR");
    expect(initials("Bob")).toBe("B");
    expect(initials("   ")).toBe("M");
  });

  it("formats missing and recent timestamps for conversation previews", () => {
    expect(formatRelativeTime()).toBe("Now");
    expect(formatRelativeTime(new Date(Date.now() - 2 * 60 * 1000).toISOString())).toMatch(/^\d+m$/);
  });

  it("formats older timestamps using hour and day buckets", () => {
    expect(formatRelativeTime(new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString())).toBe("3h");
    expect(formatRelativeTime(new Date(Date.now() - 49 * 60 * 60 * 1000).toISOString())).toBe("2d");
  });
});
