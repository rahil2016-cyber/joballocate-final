"use client";

import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { RoleBanners } from "@/components/common/role-banners";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

function JobSeekerDashboardPage() {
  const [applicationsCount, setApplicationsCount] = useState(0);
  const [recommendedCount, setRecommendedCount] = useState(0);

  useEffect(() => {
    let active = true;
    Promise.all([api.listMyApplications(), api.listJobs({ per_page: 8 })])
      .then(([applications, jobs]) => {
        if (!active) return;
        setApplicationsCount((applications as unknown[]).length);
        setRecommendedCount((jobs as unknown[]).length);
      })
      .catch(() => {
        if (!active) return;
        setApplicationsCount(0);
        setRecommendedCount(0);
      });
    return () => {
      active = false;
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
        <div className="space-y-4">
          <RoleBanners audience="job_seeker" />
          <div className="grid gap-4 md:grid-cols-2">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-bold text-[var(--text-hint)]">My Applications</p>
            <h1 className="mt-2 text-4xl font-black">{applicationsCount}</h1>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-bold text-[var(--text-hint)]">Recommended Jobs</p>
            <h2 className="mt-2 text-4xl font-black">{recommendedCount}</h2>
          </div>
          </div>
        </div>
      </SiteShell>
    </Protected>
  );
}

export { JobSeekerDashboardPage };
export default JobSeekerDashboardPage;
