import { defineConfig } from "@playwright/test";

const inComposeTester = (process.env.ANIMA_WEB_BASE_URL ?? "").includes("anima:");

export default defineConfig({
  testDir: "blackbox/ui",
  timeout: 120_000,
  expect: { timeout: 60_000 },
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.GITHUB_ACTIONS
    ? [["github"], ["html", { open: "never" }]]
    : process.env.CI
      ? [["list"], ["html", { open: "never" }]]
      : [["list"]],
  use: {
    baseURL: process.env.ANIMA_WEB_BASE_URL ?? "http://127.0.0.1:2658/web",
    trace: "retain-on-failure",
    launchOptions: inComposeTester
      ? { args: ["--no-sandbox", "--disable-setuid-sandbox"] }
      : undefined,
  },
});
