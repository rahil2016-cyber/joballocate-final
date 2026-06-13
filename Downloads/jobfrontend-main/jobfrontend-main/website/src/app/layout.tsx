import type { Metadata } from "next";
import "./globals.css";
import { env } from "@/config/env";

export const metadata: Metadata = {
  title: "JobAllocate",
  description: "Find your dream job today with JobAllocate.",
  metadataBase: new URL(env.appUrl),
  openGraph: {
    title: "JobAllocate",
    description: "Find your dream job today with JobAllocate.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
