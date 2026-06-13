"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { BrandLogo } from "@/components/common/brand-logo";
import { useAuth } from "@/hooks/use-auth";

type NavItem = { label: string; href: string };

export function SiteShell({
  children,
  navItems,
}: {
  children: React.ReactNode;
  navItems: NavItem[];
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();
  const userName = (user?.name || "Welcome").trim();
  const userInitial = userName.charAt(0).toUpperCase() || "U";
  const userPhotoUrl = (user?.profile_photo_url || "").trim();
  const [desktopMoreOpen, setDesktopMoreOpen] = useState(false);
  const [mobileMoreOpen, setMobileMoreOpen] = useState(false);
  const desktopMoreRef = useRef<HTMLDivElement>(null);
  const mobileMoreRef = useRef<HTMLDivElement>(null);

  const { primaryItems, secondaryItems } = useMemo(() => {
    const wantedPatterns = [/^home$/i, /^dashboard$/i, /^saved( jobs?)?$/i, /^profile$/i];
    const selected = new Set<string>();
    const primary: NavItem[] = [];

    wantedPatterns.forEach((pattern) => {
      const match = navItems.find((item) => !selected.has(item.href) && pattern.test(item.label.trim()));
      if (match) {
        selected.add(match.href);
        primary.push(match);
      }
    });

    if (primary.length < 4) {
      navItems.forEach((item) => {
        const isApplicationItem = /^my applications?$/i.test(item.label.trim()) || /^applications?$/i.test(item.label.trim());
        if (!selected.has(item.href) && !isApplicationItem && primary.length < 4) {
          selected.add(item.href);
          primary.push(item);
        }
      });
    }

    const secondary = navItems.filter((item) => !selected.has(item.href));
    return { primaryItems: primary, secondaryItems: secondary };
  }, [navItems]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node;
      if (desktopMoreRef.current && !desktopMoreRef.current.contains(target)) {
        setDesktopMoreOpen(false);
      }
      if (mobileMoreRef.current && !mobileMoreRef.current.contains(target)) {
        setMobileMoreOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-4 py-3">
          <BrandLogo withTagline={false} />
          <nav className="hidden gap-3 lg:flex">
            {primaryItems.map((item) => {
              const active = (pathname ?? "").startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`rounded-lg px-3 py-2 text-sm font-bold transition ${
                    active ? "bg-[var(--accent-light)] text-[var(--primary)]" : "hover:bg-slate-100"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
            {secondaryItems.length > 0 && (
              <div className="relative" ref={desktopMoreRef}>
                <button
                  type="button"
                  onClick={() => setDesktopMoreOpen((open) => !open)}
                  className="rounded-lg px-3 py-2 text-sm font-bold transition hover:bg-slate-100"
                  aria-expanded={desktopMoreOpen}
                  aria-label="More navigation options"
                >
                  ⋯
                </button>
                {desktopMoreOpen && (
                  <div className="absolute right-0 top-12 z-30 min-w-48 rounded-lg border border-slate-200 bg-white p-2 shadow-lg">
                    {secondaryItems.map((item) => {
                      const active = (pathname ?? "").startsWith(item.href);
                      return (
                        <Link
                          key={item.href}
                          href={item.href}
                          className={`block rounded-md px-3 py-2 text-sm font-bold ${
                            active ? "bg-[var(--accent-light)] text-[var(--primary)]" : "hover:bg-slate-100"
                          }`}
                        >
                          {item.label}
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            )}
          </nav>
          <div className="flex items-center gap-3">
            {userPhotoUrl ? (
              <img src={userPhotoUrl} alt={userName} className="h-9 w-9 rounded-full border border-slate-200 object-cover" />
            ) : (
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--accent-light)] text-sm font-extrabold text-[var(--primary)]">
                {userInitial}
              </div>
            )}
            <span className="hidden text-sm font-bold text-[var(--text-hint)] sm:block">{user?.name ?? "Welcome"}</span>
            <button
              onClick={() => {
                logout();
                router.push("/");
              }}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-bold hover:bg-slate-100"
            >
              Logout
            </button>
          </div>
        </div>
        <nav className="mx-auto flex w-full max-w-6xl gap-2 overflow-x-auto px-4 pb-3 lg:hidden">
          {primaryItems.map((item) => {
            const active = (pathname ?? "").startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`shrink-0 rounded-lg px-3 py-2 text-xs font-extrabold transition ${
                  active ? "bg-[var(--accent-light)] text-[var(--primary)]" : "border border-slate-200 bg-white"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
          {secondaryItems.length > 0 && (
            <div className="relative shrink-0" ref={mobileMoreRef}>
              <button
                type="button"
                onClick={() => setMobileMoreOpen((open) => !open)}
                className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-extrabold"
                aria-expanded={mobileMoreOpen}
                aria-label="More navigation options"
              >
                ⋯
              </button>
              {mobileMoreOpen && (
                <div className="absolute right-0 top-12 z-30 min-w-48 rounded-lg border border-slate-200 bg-white p-2 shadow-lg">
                  {secondaryItems.map((item) => {
                    const active = (pathname ?? "").startsWith(item.href);
                    return (
                      <Link
                        key={item.href}
                        href={item.href}
                        className={`block rounded-md px-3 py-2 text-xs font-extrabold ${
                          active ? "bg-[var(--accent-light)] text-[var(--primary)]" : "hover:bg-slate-100"
                        }`}
                      >
                        {item.label}
                      </Link>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </nav>
      </header>
      <main className="mx-auto w-full max-w-6xl px-4 py-6">{children}</main>
    </div>
  );
}
