import { expect, test } from "@playwright/test";

import { completeHubSetupIfNeeded, seedWebHubPrefs } from "./shell-prefs";

test.beforeEach(async ({ page }) => {
  await seedWebHubPrefs(page);
});

test("设置页可打开", async ({ page }) => {
  await page.goto("settings");
  await completeHubSetupIfNeeded(page);
  if (page.url().includes("/setup")) {
    await page.goto("settings");
  }
  await expect(page.getByRole("heading", { level: 2, name: "通用" })).toBeVisible({
    timeout: 60_000,
  });
  await expect(page.getByRole("button", { name: "测试连接" })).toBeVisible();
});
