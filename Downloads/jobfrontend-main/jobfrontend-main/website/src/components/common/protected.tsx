"use client";

import { useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/use-auth";

export function Protected({
  children,
  role,
}: {
  children: React.ReactNode;
  role?: "job_seeker" | "company";
}) {
  const router = useRouter();
  const { isAuthenticated, user } = useAuth();
  const hydrated = true;

  const isAllowed = useMemo(() => {
    if (!isAuthenticated) return false;
    if (role && user?.role !== role) return false;
    return true;
  }, [isAuthenticated, role, user?.role]);

  useEffect(() => {
    if (!hydrated) return;
    if (!isAuthenticated) {
      router.replace("/");
      return;
    }
    if (role && user?.role !== role) {
      router.replace("/");
    }
  }, [hydrated, isAuthenticated, role, router, user?.role]);

  if (!hydrated) return <p className="p-6 text-sm font-bold">Loading session...</p>;
  if (!isAllowed) return <p className="p-6 text-sm font-bold">Redirecting...</p>;
  return <>{children}</>;
}
