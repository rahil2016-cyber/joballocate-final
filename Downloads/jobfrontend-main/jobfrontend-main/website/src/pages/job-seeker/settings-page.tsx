"use client";

import Link from "next/link";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";

export default function JobSeekerSettingsPage() {
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
            <h1 className="text-2xl font-black">Settings</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Account and product information settings.</p>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <div className="space-y-3">
              <Link href="/about" className="block rounded-xl border border-slate-200 p-4 text-sm font-extrabold">
                About JobAllocate
              </Link>
              <Link href="/job-seeker/feedback" className="block rounded-xl border border-slate-200 p-4 text-sm font-extrabold">
                Rate and Feedback
              </Link>
              <Link href="/job-seeker/profile" className="block rounded-xl border border-slate-200 p-4 text-sm font-extrabold">
                Edit Profile
              </Link>
            </div>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
