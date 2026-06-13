"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type SavedJob = {
  id: string;
  title?: string;
  company_name?: string;
  location?: string;
  job_type?: string;
};

export default function SavedJobsPage() {
  const [savedJobs, setSavedJobs] = useState<SavedJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .listSavedJobs()
      .then((rows) => {
        if (!mounted) return;
        setSavedJobs(rows as SavedJob[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load saved jobs");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });

    return () => {
      mounted = false;
    };
  }, []);

  async function unsave(jobId: string) {
    try {
      await api.unsaveJob(jobId);
      setSavedJobs((prev) => prev.filter((item) => item.id !== jobId));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to remove saved job");
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
            <h1 className="text-2xl font-black">Saved Jobs</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
              Your shortlist synced from mobile and web.
            </p>
          </div>
          {loading ? <p className="text-sm font-bold">Loading saved jobs...</p> : null}
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          <div className="grid gap-4 md:grid-cols-2">
            {savedJobs.map((job) => (
              <article key={job.id} className="rounded-2xl bg-white p-5 shadow-sm">
                <h2 className="text-lg font-extrabold">{job.title ?? "Untitled job"}</h2>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                  {job.company_name ?? "Company"} • {job.location ?? "Location"}
                </p>
                <p className="mt-2 inline-flex rounded-full bg-[var(--accent-light)] px-3 py-1 text-xs font-extrabold text-[var(--primary)]">
                  {job.job_type ?? "Job"}
                </p>
                <div className="mt-4 flex items-center gap-4">
                  <Link href={`/jobs/${job.id}`} className="text-sm font-extrabold text-[var(--primary)] underline">
                    View details
                  </Link>
                  <button onClick={() => unsave(job.id)} className="text-sm font-extrabold text-[var(--error)] underline">
                    Remove
                  </button>
                </div>
              </article>
            ))}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
