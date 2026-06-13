import ApplicationsPage from "@/pages/job-seeker/applications-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "My Applications | JobAllocate",
  description: "Track your job applications and status updates.",
};

export default function JobSeekerApplicationsRoute() {
  return <ApplicationsPage />;
}
