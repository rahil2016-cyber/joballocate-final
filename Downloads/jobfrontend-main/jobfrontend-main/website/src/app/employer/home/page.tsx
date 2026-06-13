import { EmployerHomePage } from "@/pages/employer/home-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Employer Home | JobAllocate",
  description: "Review subscription offers, coupon eligibility, and company highlights.",
};

export default function EmployerHomeRoute() {
  return <EmployerHomePage />;
}
