"use client";

import { FormEvent, useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type TeamMember = { name?: string; role?: string; email?: string };
type CompanyProfile = {
  name?: string;
  industry_type?: string;
  industry?: string;
  city?: string;
  state?: string;
  district?: string;
  website?: string;
  gst_number?: string;
  location?: string;
  established_year?: string | number;
  verification_status?: string;
  what_we_do?: string;
  description?: string;
  about_company?: string;
  company_bio?: string;
  benefits?: string;
  salary_insights?: string;
  team_members?: TeamMember[];
  profile_completion_percent?: number | string;
};

function EmployerProfilePage() {
  const [profile, setProfile] = useState<CompanyProfile | null>(null);
  const [form, setForm] = useState<Record<string, string>>({
    name: "",
    industry: "",
    city: "",
    state: "",
    district: "",
    website: "",
  });
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    api
      .getCompanyProfile()
      .then((profile) => {
        const data = profile as CompanyProfile;
        setProfile(data);
        setForm({
          name: String(data.name ?? ""),
          industry: String(data.industry_type ?? ""),
          city: String(data.city ?? ""),
          state: String(data.state ?? ""),
          district: String(data.district ?? ""),
          website: String(data.website ?? ""),
        });
      })
      .catch(() => setMessage("Unable to load company profile"))
      .finally(() => setLoading(false));
  }, []);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    try {
      await api.updateCompanyProfile(form);
      setProfile((prev) => ({ ...(prev ?? {}), ...form, industry_type: form.industry }));
      setMessage("Company profile updated.");
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Update failed");
    }
  }

  const completion = Number(profile?.profile_completion_percent || 0);
  const team = Array.isArray(profile?.team_members) ? profile?.team_members : [];
  const verification = profile?.verification_status || "unverified";
  const location = profile?.location || [profile?.city, profile?.state, profile?.district].filter(Boolean).join(", ");

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
          <div className="rounded-2xl bg-gradient-to-r from-[var(--primary)] to-[var(--primary-dark)] p-6 text-white shadow-sm">
            <h1 className="text-2xl font-black">{form.name || "Company"}</h1>
            <p className="mt-1 text-sm font-semibold text-white/85">Verification: {verification}</p>
            <div className="mt-4">
              <div className="mb-1 flex items-center justify-between text-xs font-bold">
                <span>Profile strength</span>
                <span>{Number.isFinite(completion) ? completion : 0}%</span>
              </div>
              <div className="h-2 rounded-full bg-white/30">
                <div className="h-2 rounded-full bg-white" style={{ width: `${Math.max(0, Math.min(100, Number.isFinite(completion) ? completion : 0))}%` }} />
              </div>
            </div>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Company</h2>
            {loading ? <p className="mt-3 text-sm font-semibold text-[var(--text-hint)]">Loading profile...</p> : null}
            <div className="mt-4 grid gap-2 text-sm font-semibold md:grid-cols-2">
              <p>Industry / sector: {profile?.industry_type || "—"}</p>
              <p>Industry notes: {profile?.industry || "—"}</p>
              <p>Website: {profile?.website || "—"}</p>
              <p>GST: {profile?.gst_number || "—"}</p>
              <p>Location: {location || "—"}</p>
              <p>Established: {String(profile?.established_year ?? "—")}</p>
            </div>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">What We Do</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{profile?.what_we_do || "Describe your services and domain."}</p>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">About Company</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{profile?.about_company || profile?.company_bio || "Tell your company story."}</p>
            <p className="mt-3 text-sm font-semibold text-[var(--text-hint)]">{profile?.description || "Add short description in profile."}</p>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Benefits & Perks</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{profile?.benefits || "No benefits added yet."}</p>
            {profile?.salary_insights ? <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{profile.salary_insights}</p> : null}
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Team</h2>
            <div className="mt-3 space-y-3">
              {team.length ? (
                team.map((member, idx) => (
                  <div key={`${member.email || member.name || "team"}-${idx}`} className="rounded-xl border border-slate-200 p-3">
                    <p className="font-extrabold">{member.name || "Member"}</p>
                    <p className="text-sm font-semibold text-[var(--text-hint)]">{member.role || "Role not set"}</p>
                    <p className="text-xs font-semibold text-[var(--primary)]">{member.email || "No email"}</p>
                  </div>
                ))
              ) : (
                <p className="text-sm font-semibold text-[var(--text-hint)]">No team members added yet.</p>
              )}
            </div>
          </div>

          <form onSubmit={submit} className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-xl font-black">Edit Company Profile</h2>
            <div className="mt-5 grid gap-4 md:grid-cols-2">
              {Object.entries(form).map(([key, value]) => (
                <label key={key}>
                  <span className="mb-1 block text-sm font-bold capitalize">{key}</span>
                  <input
                    value={value}
                    onChange={(e) => setForm((prev) => ({ ...prev, [key]: e.target.value }))}
                    className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  />
                </label>
              ))}
            </div>
            {message ? <p className="mt-4 text-sm font-bold text-[var(--primary)]">{message}</p> : null}
            <div className="mt-5 max-w-56">
              <PrimaryButton type="submit">Save Company Profile</PrimaryButton>
            </div>
          </form>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <PrimaryButton
              type="button"
              onClick={() => {
                window.location.href = "/";
              }}
            >
              Logout
            </PrimaryButton>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}

export { EmployerProfilePage };
export default EmployerProfilePage;
