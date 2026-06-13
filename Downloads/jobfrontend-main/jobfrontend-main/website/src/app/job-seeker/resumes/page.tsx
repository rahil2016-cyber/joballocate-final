import JobSeekerResumesPage from "@/pages/job-seeker/resumes-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Resume Builder | JobAllocate",
  description: "Create and manage resume drafts, AI improvements, and PDF exports.",
};

export default function JobSeekerResumesRoute() {
  return <JobSeekerResumesPage />;
}
