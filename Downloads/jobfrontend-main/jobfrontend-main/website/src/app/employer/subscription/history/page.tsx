import EmployerSubscriptionHistoryPage from "@/pages/employer/subscription-history-page";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Subscription History | JobAllocate",
  description: "View company subscription payments and cycle history.",
};

export default function EmployerSubscriptionHistoryRoute() {
  return <EmployerSubscriptionHistoryPage />;
}
