import type { Metadata } from "next";
import JobSeekerRecommendedPage from "@/pages/job-seeker/recommended-page";

export const metadata: Metadata = {
  title: "Recommended Jobs | JobAllocate",
  description: "Explore recommended opportunities tailored for your profile.",
};

export default function JobSeekerRecommendedRoute() {
  return <JobSeekerRecommendedPage />;
}
