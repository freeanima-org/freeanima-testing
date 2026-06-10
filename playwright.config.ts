import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "blackbox/ui",
  timeout: 120_000,
  expect: { timeout: 60_000 },
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
  use: {
    baseURL: process.env.ANIMA_BASE_URL ?? "http://127.0.0.1:2658",
    trace: "retain-on-failure",
  },
});
