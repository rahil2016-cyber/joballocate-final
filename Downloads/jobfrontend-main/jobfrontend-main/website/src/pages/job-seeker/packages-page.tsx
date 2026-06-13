"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type SeekerPackage = {
  id?: string;
  package_key?: string;
  name?: string;
  title?: string;
  price?: number | string;
  description?: string;
};

type Purchase = {
  id: string;
  package_name?: string;
  amount?: string | number;
  status?: string;
  created_at?: string;
  expires_at?: string;
  applications_granted?: number;
  resume_builds_granted?: number;
};

export default function JobSeekerPackagesPage() {
  const [catalog, setCatalog] = useState<SeekerPackage[]>([]);
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    Promise.all([api.seekerPackageCatalog(), api.seekerPackagePurchases()])
      .then(([catalogRows, purchaseRows]) => {
        if (!mounted) return;
        setCatalog(catalogRows as SeekerPackage[]);
        setPurchases(purchaseRows as Purchase[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load packages");
        setCatalog([]);
        setPurchases([]);
      });
    return () => {
      mounted = false;
    };
  }, []);

  async function selectPackage(packageKey: string) {
    setMessage(null);
    setError(null);
    try {
      await api.seekerSelectPackage({ package_key: packageKey });
      setMessage("Package selected successfully.");
      const [catalogRows, purchaseRows] = await Promise.all([api.seekerPackageCatalog(), api.seekerPackagePurchases()]);
      setCatalog(catalogRows as SeekerPackage[]);
      setPurchases(purchaseRows as Purchase[]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to select package");
    }
  }

  return (
    <Protected role="job_seeker">
      <SiteShell
        navItems={[
          { label: "Home", href: "/job-seeker/home" },
          { label: "Dashboard", href: "/job-seeker/dashboard" },
          { label: "Applications", href: "/job-seeker/applications" },
          { label: "Saved", href: "/job-seeker/saved" },
          { label: "Recommended", href: "/job-seeker/recommended" },
          { label: "Related", href: "/job-seeker/related" },
          { label: "Packages", href: "/job-seeker/packages" },
          { label: "Resumes", href: "/job-seeker/resumes" },
          { label: "Career", href: "/job-seeker/career" },
          { label: "Feedback", href: "/job-seeker/feedback" },
          { label: "Settings", href: "/job-seeker/settings" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Job Seeker Packages</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Select packages and review purchase history.</p>
            <Link href="/job-seeker/packages/history" className="mt-4 inline-flex rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold">
              Open full purchase history
            </Link>
          </div>
          {message ? <p className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          <div className="grid gap-4 md:grid-cols-2">
            {catalog.map((pkg) => (
              <article key={pkg.id ?? pkg.package_key ?? pkg.name} className="rounded-2xl bg-white p-5 shadow-sm">
                <h2 className="text-lg font-extrabold">{pkg.title ?? pkg.name ?? "Package"}</h2>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">{pkg.description ?? "No description provided."}</p>
                <p className="mt-2 text-sm font-extrabold text-[var(--primary)]">Price: {String(pkg.price ?? "-")}</p>
                {pkg.package_key ? (
                  <button onClick={() => selectPackage(pkg.package_key!)} className="mt-4 rounded-xl bg-[var(--primary)] px-4 py-2 text-sm font-extrabold text-white">
                    Choose Package
                  </button>
                ) : null}
              </article>
            ))}
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Purchase History</h2>
            <div className="mt-4 space-y-3">
              {purchases.map((item) => (
                <div key={item.id} className="rounded-xl border border-slate-200 p-3">
                  <p className="font-extrabold">{item.package_name ?? "Package Purchase"}</p>
                  <p className="text-sm font-semibold text-[var(--text-hint)]">
                    {String(item.amount ?? "-")} • {item.status ?? "unknown"}
                  </p>
                  <p className="text-xs font-semibold text-[var(--text-hint)]">
                    {item.applications_granted ?? 0} applications • {item.resume_builds_granted ?? 0} resume builds
                  </p>
                  <p className="text-xs font-semibold text-[var(--text-hint)]">
                    {item.created_at ? new Date(item.created_at).toLocaleDateString() : "N/A"}
                    {item.expires_at ? ` • Expires ${new Date(item.expires_at).toLocaleDateString()}` : ""}
                  </p>
                </div>
              ))}
              {!purchases.length ? <p className="text-sm font-semibold text-[var(--text-hint)]">No purchases yet.</p> : null}
            </div>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
