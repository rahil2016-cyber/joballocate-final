import EmployerApplicationsPage from "@/pages/employer/applications-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Manage Applications | JobAllocate",
  description: "Review applications, add employer notes, and update candidate status.",
};

export default function EmployerApplicationsRoute() {
  return <EmployerApplicationsPage />;
}
