"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type CareerContent = {
  id: string;
  title?: string;
  excerpt?: string;
  type?: string;
  created_at?: string;
};

export default function JobSeekerCareerPage() {
  const [contents, setContents] = useState<CareerContent[]>([]);
  const [typeFilter, setTypeFilter] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .careerContents(typeFilter || undefined)
      .then((rows) => {
        if (!mounted) return;
        setContents(rows as CareerContent[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load career resources");
      });
    return () => {
      mounted = false;
    };
  }, [typeFilter]);

  async function markHelpful(id: string, isHelpful: boolean) {
    setMessage(null);
    setError(null);
    try {
      await api.markCareerContentHelpful(id, { is_helpful: isHelpful });
      setMessage("Thanks for your feedback.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to submit feedback");
    }
  }

  return (
    <Protected role="job_seeker">
      <SiteShell
        navItems={[
          { label: "Home", href: "/job-seeker/home" },
          { label: "Dashboard", href: "/job-seeker/dashboard" },
          { label: "Applications", href: "/job-seeker/applications" },
          { label: "Saved", href: "/job-seeker/saved" },
          { label: "Recommended", href: "/job-seeker/recommended" },
          { label: "Related", href: "/job-seeker/related" },
          { label: "Packages", href: "/job-seeker/packages" },
          { label: "Resumes", href: "/job-seeker/resumes" },
          { label: "Career", href: "/job-seeker/career" },
          { label: "Feedback", href: "/job-seeker/feedback" },
          { label: "Settings", href: "/job-seeker/settings" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Career Preparation</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Learning resources and guidance from your existing backend feed.</p>
            <div className="mt-4 flex flex-wrap gap-2">
              <Link href="/job-seeker/interview-qa" className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                Interview Q&amp;A
              </Link>
              <Link href="/job-seeker/interview-experiences" className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                Interview Experiences
              </Link>
              <Link href="/job-seeker/ai-coach" className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                AI Coach
              </Link>
            </div>
            <div className="mt-4 flex flex-wrap gap-2">
              {[
                { id: "", label: "All" },
                { id: "interview", label: "Interview" },
                { id: "article", label: "Articles" },
                { id: "guide", label: "Guides" },
              ].map((option) => (
                <button
                  key={option.id || "all"}
                  onClick={() => setTypeFilter(option.id)}
                  className={`rounded-lg px-3 py-1 text-xs font-extrabold ${
                    typeFilter === option.id ? "bg-[var(--primary)] text-white" : "border border-slate-200"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>
          {message ? <p className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          <div className="space-y-3">
            {contents.map((content) => (
              <article key={content.id} className="rounded-2xl bg-white p-5 shadow-sm">
                <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">{content.type ?? "career"}</p>
                <h2 className="mt-1 text-lg font-extrabold">{content.title ?? "Career content"}</h2>
                <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{content.excerpt ?? "Open this module from mobile for full content details."}</p>
                <p className="mt-3 text-xs font-bold text-[var(--text-hint)]">
                  {content.created_at ? new Date(content.created_at).toLocaleDateString() : ""}
                </p>
                <div className="mt-3 flex gap-2">
                  <button onClick={() => markHelpful(content.id, true)} className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                    Helpful
                  </button>
                  <button onClick={() => markHelpful(content.id, false)} className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                    Not Helpful
                  </button>
                </div>
              </article>
            ))}
            {!contents.length ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">No career resources yet.</div> : null}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
