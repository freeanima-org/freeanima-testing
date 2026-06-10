import { describe, expect, it } from "bun:test";

const base = process.env.ANIMA_BASE_URL ?? "http://127.0.0.1:2658";

describe("GET /api/health", () => {
  it("返回 200", async () => {
    const res = await fetch(`${base}/api/health`);
    expect(res.ok).toBe(true);
    const body = await res.json();
    expect(body).toBeDefined();
  });
});

describe("GET /api/sessions/", () => {
  it("返回会话列表 JSON", async () => {
    const res = await fetch(`${base}/api/sessions/`);
    expect(res.ok).toBe(true);
    const body = (await res.json()) as { sessions?: unknown };
    expect(Array.isArray(body.sessions)).toBe(true);
  });
});
