import { expect, test } from "@playwright/test";

test("设置页可打开", async ({ page }) => {
  await page.goto("/settings");
  await expect(page.getByRole("heading", { level: 2, name: "通用" })).toBeVisible({
    timeout: 60_000,
  });
  await expect(page.getByLabel("Hub 地址")).toBeVisible();
});
