import EmployerJobPostDetailPage from "@/pages/employer/job-post-detail-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Edit Job Post | JobAllocate",
  description: "Update company job post details and status.",
};

export default async function EmployerJobPostDetailRoute({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <EmployerJobPostDetailPage jobId={id} />;
}
