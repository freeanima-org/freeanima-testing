import { expect, type Page } from "@playwright/test";

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

export async function seedWebHubPrefs(page: Page): Promise<void> {
  const hubUrl = hubApiBaseUrl();
  const token = remoteAuthToken();
  await page.addInitScript(
    ({ hubUrlKey, tokenKey, url, authToken }) => {
      localStorage.setItem(hubUrlKey, url);
      localStorage.setItem(tokenKey, authToken);
    },
    { hubUrlKey: HUB_URL_KEY, tokenKey: REMOTE_AUTH_TOKEN_KEY, url: hubUrl, authToken: token },
  );
}

export async function waitForShellHubReady(page: Page): Promise<void> {
  await page.waitForFunction(
    () => Boolean((window as { satelliteShell?: { remoteAuth?: { token?: string } } }).satelliteShell?.remoteAuth?.token?.trim()),
    undefined,
    { timeout: 60_000 },
  );
}

export async function completeHubSetupIfNeeded(page: Page): Promise<void> {
  const setupHeading = page.getByRole("heading", { name: "连接 FreeAnima Hub" });
  if (!(await setupHeading.isVisible({ timeout: 3_000 }).catch(() => false))) return;
  await page.getByPlaceholder("http://127.0.0.1:2658").fill(hubApiBaseUrl());
  await page.locator('input[type="password"]').fill(remoteAuthToken());
  await page.getByRole("button", { name: "保存并进入" }).click();
  await expect(setupHeading).not.toBeVisible({ timeout: 60_000 });
}
