"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { EmptyState, ErrorState, LoadingState } from "@/components/common/states";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type Job = {
  id: string;
  title?: string;
  company_name?: string;
  location?: string;
};

export default function JobSeekerRelatedPage() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .listRelatedJobs()
      .then((rows) => {
        if (!mounted) return;
        setJobs(rows as Job[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load related jobs");
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
            <h1 className="text-2xl font-black">Related Jobs</h1>
          </div>
          {loading ? <LoadingState title="Loading related jobs..." /> : null}
          {error ? <ErrorState title={error} /> : null}
          <div className="grid gap-4 md:grid-cols-2">
            {jobs.map((job) => (
              <article key={job.id} className="rounded-2xl bg-white p-5 shadow-sm">
                <h2 className="text-lg font-extrabold">{job.title ?? "Job"}</h2>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                  {job.company_name ?? "Company"} • {job.location ?? "Location"}
                </p>
                <Link href={`/jobs/${job.id}`} className="mt-3 inline-block text-sm font-extrabold text-[var(--primary)] underline">
                  View details
                </Link>
              </article>
            ))}
          </div>
          {!loading && !error && !jobs.length ? <EmptyState title="No related jobs yet." /> : null}
        </section>
      </SiteShell>
    </Protected>
  );
}
