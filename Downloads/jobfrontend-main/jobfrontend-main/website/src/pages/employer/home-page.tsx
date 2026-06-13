"use client";

import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { RoleBanners } from "@/components/common/role-banners";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type Company = {
  id: string;
  name: string;
  open_jobs_count?: number;
};

type SubscriptionOffer = {
  verified?: boolean;
  package_title?: string;
  monthly_price_inr?: number;
  first_month?: {
    already_purchased?: boolean;
    is_free_eligible?: boolean;
    eligible_coupon_codes?: string[];
    suggested_coupon_code?: string | null;
    message?: string;
  };
  renewal?: {
    message?: string;
  };
};

function EmployerHomePage() {
  const [companies, setCompanies] = useState<Company[]>([]);
  const [offer, setOffer] = useState<SubscriptionOffer | null>(null);
  const [couponCode, setCouponCode] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [lastPurchaseAmount, setLastPurchaseAmount] = useState<number | null>(null);

  useEffect(() => {
    Promise.all([api.listTopCompanies(), api.companySubscriptionOffer()])
      .then(([topCompanies, offerData]) => {
        setCompanies(topCompanies as Company[]);
        setOffer(offerData as SubscriptionOffer);
      })
      .catch(() => {
        setCompanies([]);
        setOffer(null);
      });
  }, []);

  async function purchaseSubscription() {
    setMessage(null);
    setError(null);
    try {
      const purchase = await api.companyPurchaseSubscription({
        coupon_code: couponCode.trim() || undefined,
      });
      setMessage("Subscription purchase completed.");
      setLastPurchaseAmount(Number((purchase as { amount_inr?: number }).amount_inr ?? 0));
      const offerData = await api.companySubscriptionOffer();
      setOffer(offerData as SubscriptionOffer);
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
        <div className="space-y-4">
          <RoleBanners audience="employer" />
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Employer Home</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
              Subscription, market visibility, and company stats overview.
            </p>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Current Subscription Offer</h2>
            <div className="mt-3 grid gap-3 md:grid-cols-2">
              <div className="rounded-xl border border-slate-200 p-4">
                <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">Offer status</p>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                  {offer ? (offer.first_month?.already_purchased ? "Already purchased" : "Not purchased yet") : "No offer data"}
                </p>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                  Package: {offer?.package_title ?? "Company Subscription"} • Monthly: INR {offer?.monthly_price_inr ?? 0}
                </p>
                {offer?.first_month?.suggested_coupon_code ? (
                  <p className="mt-2 text-xs font-extrabold text-[var(--primary)]">
                    Suggested coupon: {String(offer.first_month.suggested_coupon_code)}
                  </p>
                ) : null}
                {offer?.first_month?.eligible_coupon_codes?.length ? (
                  <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">
                    Eligible coupons: {offer.first_month.eligible_coupon_codes.join(", ")}
                  </p>
                ) : null}
                <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">
                  {offer?.first_month?.message ?? "No first month message"}
                </p>
                <p className="mt-1 text-xs font-semibold text-[var(--text-hint)]">{offer?.renewal?.message ?? "No renewal message"}</p>
              </div>
              <div className="rounded-xl border border-slate-200 p-4">
                <label className="mb-1 block text-sm font-bold">Coupon code (optional)</label>
                <input
                  value={couponCode}
                  onChange={(e) => setCouponCode(e.target.value)}
                  className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  placeholder="Enter coupon code"
                />
                <button onClick={purchaseSubscription} className="mt-3 rounded-lg bg-[var(--primary)] px-4 py-2 text-sm font-extrabold text-white">
                  Buy Subscription
                </button>
                <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">
                  Payable now: INR{" "}
                  {offer?.first_month?.is_free_eligible && couponCode.trim()
                    ? 0
                    : offer?.monthly_price_inr ?? 0}
                </p>
              </div>
            </div>
            {message ? (
              <p role="status" aria-live="polite" className="mt-3 text-sm font-bold text-[var(--primary)]">
                {message}
              </p>
            ) : null}
            {error ? (
              <p role="alert" aria-live="assertive" className="mt-3 text-sm font-bold text-[var(--error)]">
                {error}
              </p>
            ) : null}
            {lastPurchaseAmount !== null ? (
              <p className="mt-1 text-xs font-semibold text-[var(--text-hint)]">Last charged amount: INR {lastPurchaseAmount}</p>
            ) : null}
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Top Companies Snapshot</h2>
            <div className="mt-4 grid gap-3 md:grid-cols-2">
              {companies.slice(0, 6).map((company) => (
                <div key={company.id} className="rounded-xl border border-slate-200 p-4">
                  <p className="font-extrabold">{company.name}</p>
                  <p className="text-sm font-semibold text-[var(--text-hint)]">
                    Open jobs: {company.open_jobs_count ?? 0}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </SiteShell>
    </Protected>
  );
}

export { EmployerHomePage };
export default EmployerHomePage;
