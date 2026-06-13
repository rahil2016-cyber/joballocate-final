"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type Application = {
  id: string;
  status?: string;
  employer_note?: string;
  cover_letter?: string;
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

function canWithdraw(status: string | undefined): boolean {
  return status === "applied" || status === "shortlisted";
}

export default function ApplicationDetailPage({ applicationId }: { applicationId: string }) {
  const [application, setApplication] = useState<Application | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .getApplication(applicationId)
      .then((row) => {
        if (!mounted) return;
        setApplication(row as Application | null);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load application");
      });
    return () => {
      mounted = false;
    };
  }, [applicationId]);

  async function withdraw() {
    setMessage(null);
    setError(null);
    try {
      await api.withdrawApplication(applicationId);
      setMessage("Application withdrawn successfully.");
      setApplication((prev) => (prev ? { ...prev, status: "withdrawn" } : prev));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to withdraw application");
    }
  }

  const job = application ? pickJob(application) : null;

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
            <h1 className="text-2xl font-black">Application Detail</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Track status and manage this application.</p>
          </div>
          {error ? <p role="alert" className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          {message ? <p role="status" className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {application ? (
            <article className="rounded-2xl bg-white p-6 shadow-sm">
              <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">
                Status: {application.status ?? "pending"}
              </p>
              <h2 className="mt-1 text-xl font-extrabold">{job?.title ?? "Job application"}</h2>
              <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                {job?.company_name ?? "Company"} • {job?.location ?? "Location"}
              </p>
              <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">
                Applied on {application.created_at ? new Date(application.created_at).toLocaleString() : "N/A"}
              </p>
              {application.cover_letter ? (
                <div className="mt-3 rounded-xl bg-slate-50 p-3">
                  <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">Cover Letter</p>
                  <p className="mt-1 text-sm font-semibold text-slate-700 whitespace-pre-line">{application.cover_letter}</p>
                </div>
              ) : null}
              <p className="mt-3 text-sm font-semibold text-slate-700">{application.employer_note ?? "No employer note available yet."}</p>
              <div className="mt-4 flex items-center gap-4">
                {canWithdraw(application.status) ? (
                  <button onClick={withdraw} className="rounded-xl border border-[var(--error)] px-4 py-2 text-sm font-extrabold text-[var(--error)]">
                    Withdraw Application
                  </button>
                ) : (
                  <p className="text-sm font-semibold text-[var(--text-hint)]">This application can no longer be withdrawn.</p>
                )}
                {job?.id ? (
                  <Link href={`/jobs/${job.id}`} className="text-sm font-extrabold text-[var(--primary)] underline">
                    View job
                  </Link>
                ) : null}
              </div>
            </article>
          ) : (
            <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">Application not found.</div>
          )}
        </section>
      </SiteShell>
    </Protected>
  );
}
