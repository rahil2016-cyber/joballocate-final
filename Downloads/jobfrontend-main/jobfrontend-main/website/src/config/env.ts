const FALLBACK_BASE_URL = "https://joballocate.tech";
const DEFAULT_API_PREFIX = "/api/v1";

function trimSlash(value: string): string {
  return value.replace(/\/+$/, "");
}

function normalizeBaseUrl(raw: string | undefined): string {
  const candidate = (raw ?? FALLBACK_BASE_URL).trim();
  const cleaned = trimSlash(candidate);
  if (cleaned.endsWith(DEFAULT_API_PREFIX)) {
    return cleaned.slice(0, -DEFAULT_API_PREFIX.length);
  }
  return cleaned;
}

function normalizeAppUrl(raw: string | undefined): string {
  const candidate = (raw ?? "http://localhost:3000").trim();
  return trimSlash(candidate);
}

export const env = {
  appEnv: process.env.NEXT_PUBLIC_ENV ?? "production",
  appUrl: normalizeAppUrl(process.env.NEXT_PUBLIC_APP_URL),
  apiOrigin: normalizeBaseUrl(process.env.NEXT_PUBLIC_API_BASE_URL),
  apiPrefix: DEFAULT_API_PREFIX,
};

export function withApiPrefix(path: string): string {
  return `${env.apiOrigin}${env.apiPrefix}${path}`;
}
