const TOKEN_KEY = "joballocate_token";
const USER_KEY = "joballocate_user";

export type AppUser = {
  id?: string;
  name?: string;
  role?: "job_seeker" | "company" | "super_admin" | string;
  email?: string;
  profile_photo_url?: string;
};

type SessionSnapshot = {
  token: string | null;
  user: AppUser | null;
};

type Listener = () => void;
const listeners = new Set<Listener>();
let cachedToken: string | null = null;
let cachedUserJson: string | null = null;
let cachedSnapshot: SessionSnapshot = { token: null, user: null };

function readSnapshot(): SessionSnapshot {
  if (typeof window === "undefined") return cachedSnapshot;
  const token = localStorage.getItem(TOKEN_KEY);
  const userJson = localStorage.getItem(USER_KEY);
  if (token === cachedToken && userJson === cachedUserJson) {
    return cachedSnapshot;
  }

  let parsedUser: AppUser | null = null;
  if (userJson) {
    try {
      parsedUser = JSON.parse(userJson) as AppUser;
    } catch {
      parsedUser = null;
    }
  }

  cachedToken = token;
  cachedUserJson = userJson;
  cachedSnapshot = {
    token,
    user: parsedUser,
  };

  return {
    token: cachedSnapshot.token,
    user: cachedSnapshot.user,
  };
}

function notifyListeners() {
  cachedSnapshot = readSnapshot();
  for (const listener of listeners) listener();
}

export function saveSession(token: string, user: AppUser) {
  if (typeof window === "undefined") return;
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
  notifyListeners();
}

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function getUser(): AppUser | null {
  if (typeof window === "undefined") return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AppUser;
  } catch {
    return null;
  }
}

export function clearSession() {
  if (typeof window === "undefined") return;
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
  notifyListeners();
}

export function subscribeSession(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getSessionSnapshot(): SessionSnapshot {
  return readSnapshot();
}
