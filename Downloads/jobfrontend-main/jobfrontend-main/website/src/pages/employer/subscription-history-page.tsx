"use client";

import { FormEvent, useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { EmptyState, ErrorState } from "@/components/common/states";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type SubscriptionRecord = {
  id: string;
  amount?: string | number;
  status?: string;
  started_at?: string;
  ends_at?: string;
  package_name?: string;
};

export default function EmployerSubscriptionHistoryPage() {
  const [history, setHistory] = useState<SubscriptionRecord[]>([]);
  const [couponCode, setCouponCode] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .companySubscriptionHistory()
      .then((rows) => {
        if (!mounted) return;
        setHistory(rows as SubscriptionRecord[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load subscription history");
        setHistory([]);
      });
    return () => {
      mounted = false;
    };
  }, []);

  async function purchase(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    setError(null);
    try {
      await api.companyPurchaseSubscription({ coupon_code: couponCode.trim() || undefined });
      setMessage("Subscription purchase initiated successfully.");
      setCouponCode("");
      const rows = await api.companySubscriptionHistory();
      setHistory(rows as SubscriptionRecord[]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to purchase subscription");
    }
  }

  return (
    <Protected role="company">
      <SiteShell
        navItems={[
          { label: "Dashboard", href: "/employer/dashboard" },
          { label: "Home", href: "/employer/home" },
          { label: "Applications", href: "/employer/applications" },
          { label: "Subscriptions", href: "/employer/subscription/history" },
          { label: "Profile", href: "/employer/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Company Subscription</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Purchase and review your subscription cycles.</p>
          </div>
          <form onSubmit={purchase} className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Purchase Subscription</h2>
            <label className="mt-4 block">
              <span className="mb-1 block text-sm font-bold">Coupon code (optional)</span>
              <input
                value={couponCode}
                onChange={(e) => setCouponCode(e.target.value)}
                className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                placeholder="Enter coupon code"
              />
            </label>
            <div className="mt-4 max-w-60">
              <PrimaryButton type="submit">Purchase Now</PrimaryButton>
            </div>
          </form>
          {message ? <p role="status" className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {error ? <ErrorState title={error} /> : null}
          <div className="space-y-3">
            {history.map((item) => (
              <article key={item.id} className="rounded-2xl bg-white p-5 shadow-sm">
                <h2 className="text-lg font-extrabold">{item.package_name ?? "Subscription package"}</h2>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">Status: {item.status ?? "unknown"}</p>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">Amount: {String(item.amount ?? "-")}</p>
                <p className="mt-1 text-xs font-bold text-[var(--text-hint)]">
                  {item.started_at ? new Date(item.started_at).toLocaleDateString() : "N/A"} -{" "}
                  {item.ends_at ? new Date(item.ends_at).toLocaleDateString() : "N/A"}
                </p>
              </article>
            ))}
            {!history.length ? <EmptyState title="No subscription records yet." /> : null}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
