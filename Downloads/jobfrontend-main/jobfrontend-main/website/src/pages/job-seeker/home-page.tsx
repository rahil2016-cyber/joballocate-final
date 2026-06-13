"use client";

import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { RoleBanners } from "@/components/common/role-banners";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type Job = {
  id: string;
  title: string;
  company_name?: string;
  location?: string;
  job_type?: string;
};

function JobSeekerHomePage() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [savedJobs, setSavedJobs] = useState<Job[]>([]);
  const [recommendedJobs, setRecommendedJobs] = useState<Job[]>([]);
  const [relatedJobs, setRelatedJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    Promise.all([api.listJobs({ per_page: 12 }), api.listSavedJobs(), api.listRecommendedJobs(), api.listRelatedJobs()])
      .then(([jobList, saved, recommended, related]) => {
        if (!alive) return;
        setJobs(jobList as Job[]);
        setSavedJobs(saved as Job[]);
        setRecommendedJobs(recommended as Job[]);
        setRelatedJobs(related as Job[]);
      })
      .catch((err) => {
        if (!alive) return;
        setError(err instanceof Error ? err.message : "Unable to load jobs");
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
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
        <section className="space-y-6">
          <RoleBanners audience="job_seeker" />
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Job Seeker Home</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
              What&apos;s new, recommended jobs, and saved items in one responsive feed.
            </p>
          </div>
          {loading ? <p className="text-sm font-bold">Loading jobs...</p> : null}
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {jobs.map((job) => (
              <article key={job.id} className="rounded-2xl bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                <h2 className="text-lg font-extrabold">{job.title}</h2>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                  {job.company_name ?? "Company"} • {job.location ?? "Location"}
                </p>
                <p className="mt-4 inline-flex rounded-full bg-[var(--accent-light)] px-3 py-1 text-xs font-extrabold text-[var(--primary)]">
                  {job.job_type ?? "Job"}
                </p>
              </article>
            ))}
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Recommended Jobs</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{recommendedJobs.length} recommendation(s) available.</p>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Related Jobs</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{relatedJobs.length} related opportunity(s) available.</p>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Saved Jobs</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
              {savedJobs.length} job(s) saved from your mobile/web account.
            </p>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}

export { JobSeekerHomePage };
export default JobSeekerHomePage;
