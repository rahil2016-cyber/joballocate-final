import type { Metadata } from "next";
import JobSeekerFeedbackPage from "@/pages/job-seeker/feedback-page";

export const metadata: Metadata = {
  title: "Feedback | JobAllocate",
  description: "Submit app feedback and view admin responses.",
};

export default function JobSeekerFeedbackRoute() {
  return <JobSeekerFeedbackPage />;
}
