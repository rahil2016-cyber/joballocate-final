"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type Application = {
  id: string;
  status?: string;
  created_at?: string;
  job?: {
    id?: string;
    title?: string;
    company_name?: string;
    location?: string;
  };
};

function pickJob(application: Application): Application["job"] {
  return application.job ?? ((application as unknown as { jobPost?: Application["job"] }).jobPost ?? undefined);
}

function statusStyle(status: string | undefined): string {
  if (status === "shortlisted") return "bg-emerald-100 text-emerald-700";
  if (status === "rejected" || status === "withdrawn") return "bg-rose-100 text-rose-700";
  if (status === "hired") return "bg-blue-100 text-blue-700";
  return "bg-amber-100 text-amber-700";
}

export default function ApplicationsPage() {
  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .listMyApplications()
      .then((rows) => {
        if (!mounted) return;
        setApplications(rows as Application[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load applications");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });
    return () => {
      mounted = false;
    };
  }, []);

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
            <h1 className="text-2xl font-black">My Applications</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
              Track every application submitted from your account.
            </p>
          </div>
          {loading ? <p className="text-sm font-bold">Loading applications...</p> : null}
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          <div className="space-y-3">
            {applications.map((application) => {
              const job = pickJob(application);
              return (
                <article key={application.id} className="rounded-2xl bg-white p-5 shadow-sm">
                  <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">
                    <span className={`rounded-full px-2 py-1 ${statusStyle(application.status)}`}>Status: {application.status ?? "pending"}</span>
                  </p>
                  <h2 className="mt-1 text-lg font-extrabold">{job?.title ?? "Job Application"}</h2>
                  <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                    {job?.company_name ?? "Company"} • {job?.location ?? "Location"}
                  </p>
                  <p className="mt-3 text-xs font-bold text-[var(--text-hint)]">
                    Applied on {application.created_at ? new Date(application.created_at).toLocaleDateString() : "N/A"}
                  </p>
                  <div className="mt-4 flex items-center gap-4">
                    <Link href={`/job-seeker/applications/${application.id}`} className="text-sm font-extrabold text-[var(--primary)] underline">
                      Open application
                    </Link>
                    {job?.id ? (
                      <Link href={`/jobs/${job.id}`} className="text-sm font-extrabold text-[var(--primary)] underline">
                        View job details
                      </Link>
                    ) : null}
                  </div>
                </article>
              );
            })}
            {!loading && !applications.length ? (
              <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">
                No applications yet.
              </div>
            ) : null}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
