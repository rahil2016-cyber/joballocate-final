"use client";

import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type ExperienceItem = {
  id?: string | number;
  title?: string;
  excerpt?: string;
  body?: string;
  source?: string;
  created_at?: string;
};

export default function InterviewExperiencesPage() {
  const [items, setItems] = useState<ExperienceItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .careerContents("interview_experience")
      .then((rows) => {
        if (!mounted) return;
        setItems((rows as ExperienceItem[]) || []);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load interview experiences");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });
    return () => {
      mounted = false;
    };
  }, []);

  return (
    <Protected role="job_seeker">
      <SiteShell
        navItems={[
          { label: "Home", href: "/job-seeker/home" },
          { label: "Dashboard", href: "/job-seeker/dashboard" },
          { label: "Applications", href: "/job-seeker/applications" },
          { label: "Saved Jobs", href: "/job-seeker/saved" },
          { label: "Recommended", href: "/job-seeker/recommended" },
          { label: "Related", href: "/job-seeker/related" },
          { label: "Packages", href: "/job-seeker/packages" },
          { label: "Resumes", href: "/job-seeker/resumes" },
          { label: "Career", href: "/job-seeker/career" },
          { label: "Interview Experiences", href: "/job-seeker/interview-experiences" },
          { label: "Feedback", href: "/job-seeker/feedback" },
          { label: "Settings", href: "/job-seeker/settings" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Interview Experiences</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Real interview stories from backend career content.</p>
          </div>
          {loading ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold shadow-sm">Loading experiences...</div> : null}
          {error ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--error)] shadow-sm">{error}</div> : null}
          {!loading && !error && !items.length ? (
            <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">No interview experiences available yet.</div>
          ) : null}
          <div className="space-y-3">
            {items.map((item, index) => (
              <article key={String(item.id ?? index)} className="rounded-2xl bg-white p-5 shadow-sm">
                <h2 className="text-lg font-extrabold">{item.title || "Interview Story"}</h2>
                <p className="mt-1 text-xs font-semibold text-[var(--text-hint)]">
                  {item.source || "Career content"} {item.created_at ? `• ${new Date(item.created_at).toLocaleDateString()}` : ""}
                </p>
                <p className="mt-3 whitespace-pre-wrap text-sm font-semibold text-[var(--text-hint)]">{item.body || item.excerpt || "No details available."}</p>
              </article>
            ))}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
