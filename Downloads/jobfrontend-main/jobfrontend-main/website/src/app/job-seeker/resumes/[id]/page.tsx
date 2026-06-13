import ResumeDraftDetailPage from "@/pages/job-seeker/resume-draft-detail-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Resume Draft Detail | JobAllocate",
  description: "Review and edit saved resume draft content.",
};

export default async function ResumeDraftDetailRoute({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ResumeDraftDetailPage draftId={id} />;
}
