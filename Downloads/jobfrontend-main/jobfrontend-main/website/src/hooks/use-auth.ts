"use client";

import { useMemo, useSyncExternalStore } from "react";
import {
  clearSession,
  getSessionSnapshot,
  saveSession,
  subscribeSession,
  type AppUser,
} from "@/services/auth-storage";

const EMPTY_SESSION = {
  token: null,
  user: null,
};

export function useAuth() {
  const session = useSyncExternalStore(subscribeSession, getSessionSnapshot, () => EMPTY_SESSION);

  const isAuthenticated = useMemo(() => Boolean(session.token), [session.token]);

  function login(nextToken: string, nextUser: AppUser) {
    saveSession(nextToken, nextUser);
  }

  function logout() {
    clearSession();
  }

  return { token: session.token, user: session.user, isAuthenticated, login, logout };
}
