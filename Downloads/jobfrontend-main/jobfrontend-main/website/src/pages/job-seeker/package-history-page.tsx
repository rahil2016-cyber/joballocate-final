"use client";

import { useEffect, useMemo, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type PurchaseItem = {
  id?: string | number;
  kind?: string;
  title?: string;
  package_key?: string;
  price_inr?: number | string;
  activated_at?: string;
  expires_at?: string;
  applications_granted?: number | string;
  resume_builds_granted?: number | string;
  duration_days?: number | string;
};

type KindFilter = "all" | "resume" | "combo" | "job_applications";

export default function PackageHistoryPage() {
  const [items, setItems] = useState<PurchaseItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [kindFilter, setKindFilter] = useState<KindFilter>("all");

  useEffect(() => {
    let mounted = true;
    api
      .seekerPackagePurchasesPaged({ page: 1, per_page: 50 })
      .then((data) => {
        if (!mounted) return;
        const rows = Array.isArray(data.items) ? (data.items as PurchaseItem[]) : [];
        setItems(rows);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load purchase history");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });
    return () => {
      mounted = false;
    };
  }, []);

  const visibleItems = useMemo(() => {
    if (kindFilter === "all") return items;
    return items.filter((row) => String(row.kind || "") === kindFilter);
  }, [items, kindFilter]);

  return (
    <Protected role="job_seeker">
      <SiteShell
        navItems={[
          { label: "Home", href: "/job-seeker/home" },
          { label: "Dashboard", href: "/job-seeker/dashboard" },
          { label: "Applications", href: "/job-seeker/applications" },
          { label: "Saved Jobs", href: "/job-seeker/saved" },
          { label: "Recommended", href: "/job-seeker/recommended" },
          { label: "Related", href: "/job-seeker/related" },
          { label: "Packages", href: "/job-seeker/packages" },
          { label: "Purchase History", href: "/job-seeker/packages/history" },
          { label: "Resumes", href: "/job-seeker/resumes" },
          { label: "Career", href: "/job-seeker/career" },
          { label: "Feedback", href: "/job-seeker/feedback" },
          { label: "Settings", href: "/job-seeker/settings" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Purchase History</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Server-side package activation history for your account.</p>
            <div className="mt-4 flex flex-wrap gap-2">
              {[
                { id: "all", label: "All" },
                { id: "resume", label: "Resume" },
                { id: "combo", label: "Combo" },
                { id: "job_applications", label: "Jobs" },
              ].map((filter) => (
                <button
                  key={filter.id}
                  onClick={() => setKindFilter(filter.id as KindFilter)}
                  className={`rounded-lg px-3 py-1 text-xs font-extrabold ${kindFilter === filter.id ? "bg-[var(--primary)] text-white" : "border border-slate-200"}`}
                >
                  {filter.label}
                </button>
              ))}
            </div>
          </div>
          {loading ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold shadow-sm">Loading history...</div> : null}
          {error ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--error)] shadow-sm">{error}</div> : null}
          {!loading && !error && !visibleItems.length ? (
            <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">No purchases in this category.</div>
          ) : null}
          <div className="space-y-3">
            {visibleItems.map((row, index) => (
              <article key={String(row.id ?? index)} className="rounded-2xl bg-white p-5 shadow-sm">
                <div className="flex items-start justify-between gap-3">
                  <h2 className="text-lg font-extrabold">{row.title || "Package"}</h2>
                  <span className="rounded-md bg-[var(--accent-light)] px-2 py-1 text-xs font-extrabold text-[var(--primary)]">{row.kind || "jobs"}</span>
                </div>
                <p className="mt-2 text-sm font-extrabold text-[var(--primary)]">Price: INR {String(row.price_inr ?? "-")}</p>
                <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
                  Activated: {row.activated_at ? new Date(row.activated_at).toLocaleString() : "—"}
                </p>
                <p className="text-sm font-semibold text-[var(--text-hint)]">Expires: {row.expires_at ? new Date(row.expires_at).toLocaleString() : "—"}</p>
                <p className="text-sm font-semibold text-[var(--text-hint)]">
                  Included: {String(row.applications_granted ?? 0)} job apps • {String(row.resume_builds_granted ?? 0)} resume builds • {String(row.duration_days ?? 0)} days
                </p>
                <p className="mt-1 text-xs font-semibold text-[var(--text-hint)]">Key: {row.package_key || "—"}</p>
              </article>
            ))}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
