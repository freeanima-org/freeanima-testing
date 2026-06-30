import { expect } from "@playwright/test";

import type { Page } from "@playwright/test";

/** 与 @freeanima/shell-sdk/settings prefs-keys 保持一致 */
export const HUB_URL_KEY = "freeanima.hubUrl";
export const REMOTE_AUTH_TOKEN_KEY = "freeanima.remoteAuthToken";

export function hubApiBaseUrl(): string {
  const fromAnima = process.env.ANIMA_BASE_URL?.trim();
  if (fromAnima) return fromAnima.replace(/\/$/, "");
  const webBase = process.env.ANIMA_WEB_BASE_URL?.trim();
  if (webBase) {
    try {
      const u = new URL(webBase);
      return `${u.protocol}//${u.host}`;
    } catch {
      /* ignore */
    }
  }
  return "http://127.0.0.1:2658";
}

export function remoteAuthToken(): string {
  return process.env.REMOTE_AUTH_TOKEN?.trim() || "changeme-remote-auth-token";
}

/** 在首屏脚本运行前写入 Web 壳层 Hub 偏好，避免落到 /setup 引导页 */
export async function seedWebHubPrefs(page: Page): Promise<void> {
  const hubUrl = hubApiBaseUrl();
  const token = remoteAuthToken();
  await page.addInitScript(
    ({ hubUrlKey, tokenKey, url, authToken }) => {
      localStorage.setItem(hubUrlKey, url);
      localStorage.setItem(tokenKey, authToken);
    },
    {
      hubUrlKey: HUB_URL_KEY,
      tokenKey: REMOTE_AUTH_TOKEN_KEY,
      url: hubUrl,
      authToken: token,
    },
  );
}

/** shell-bridge 异步完成前，路由可能仍判定需要 Hub 引导 */
export async function waitForShellHubReady(page: Page): Promise<void> {
  await page.waitForFunction(
    () => Boolean(window.satelliteShell?.remoteAuth?.token?.trim()),
    undefined,
    { timeout: 60_000 },
  );
}

/** 若仍落在引导页，通过表单完成 Hub 连接后进入主界面 */
export async function completeHubSetupIfNeeded(page: Page): Promise<void> {
  const setupHeading = page.getByRole("heading", { name: "连接 FreeAnima Hub" });
  if (!(await setupHeading.isVisible({ timeout: 3_000 }).catch(() => false))) {
    return;
  }
  await page.getByLabel("Hub 地址").fill(hubApiBaseUrl());
  await page.getByLabel("Hub API Token").fill(remoteAuthToken());
  await page.getByRole("button", { name: "保存并进入" }).click();
  await expect(setupHeading).not.toBeVisible({ timeout: 60_000 });
}
