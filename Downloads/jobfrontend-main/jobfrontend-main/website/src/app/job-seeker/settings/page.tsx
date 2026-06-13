import type { Metadata } from "next";
import JobSeekerSettingsPage from "@/pages/job-seeker/settings-page";

export const metadata: Metadata = {
  title: "Settings | JobAllocate",
  description: "Manage account settings and useful app links.",
};

export default function JobSeekerSettingsRoute() {
  return <JobSeekerSettingsPage />;
}
