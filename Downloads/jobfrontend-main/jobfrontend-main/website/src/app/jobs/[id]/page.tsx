import { SiteShell } from "@/components/layout/site-shell";
import { Protected } from "@/components/common/protected";
import JobDetailPage from "@/pages/jobs/job-detail-page";

export default async function JobDetailsRoute({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return (
    <Protected role="job_seeker">
      <SiteShell
        navItems={[
          { label: "Home", href: "/job-seeker/home" },
          { label: "Dashboard", href: "/job-seeker/dashboard" },
          { label: "Applications", href: "/job-seeker/applications" },
          { label: "Saved", href: "/job-seeker/saved" },
          { label: "Packages", href: "/job-seeker/packages" },
          { label: "Resumes", href: "/job-seeker/resumes" },
          { label: "Career", href: "/job-seeker/career" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <JobDetailPage jobId={id} />
      </SiteShell>
    </Protected>
  );
}
