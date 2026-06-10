import { expect, test } from "@playwright/test";

test("卧室 dashboard 可打开", async ({ page }) => {
  await page.goto("/webui/chamber/dashboard");
  await expect(page.getByTestId("chamber-layout")).toBeVisible({ timeout: 30_000 });
});
