import ApplicationDetailPage from "@/pages/job-seeker/application-detail-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Application Detail | JobAllocate",
  description: "View full application status and manage withdrawal options.",
};

export default async function JobSeekerApplicationDetailRoute({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ApplicationDetailPage applicationId={id} />;
}
