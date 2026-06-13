import type { Metadata } from "next";
import JobSeekerRelatedPage from "@/pages/job-seeker/related-page";

export const metadata: Metadata = {
  title: "Related Jobs | JobAllocate",
  description: "Discover jobs related to your previous applications and profile.",
};

export default function JobSeekerRelatedRoute() {
  return <JobSeekerRelatedPage />;
}
