import type { Metadata } from "next";
import ResumePreviewPage from "@/pages/job-seeker/resume-preview-page";

export const metadata: Metadata = {
  title: "Resume Preview | JobAllocate",
  description: "Preview resume content and save as PDF.",
};

export default async function ResumePreviewRoute({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ResumePreviewPage draftId={id} />;
}
