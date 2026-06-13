"use client";

import { FormEvent, useMemo, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type CoachKind = "career_path" | "interview_prep";

export default function AiCoachPage() {
  const [kind, setKind] = useState<CoachKind>("career_path");
  const [focus, setFocus] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [resultText, setResultText] = useState("");

  const title = useMemo(() => (kind === "career_path" ? "AI Career Path" : "AI Interview Prep"), [kind]);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const data = await api.careerCoach({ kind, focus: focus.trim() || undefined });
      const text = String(data.text ?? "").trim();
      setResultText(text);
      if (!text) setError("No response received.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to generate coach response");
    } finally {
      setLoading(false);
    }
  }

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
          { label: "AI Coach", href: "/job-seeker/ai-coach" },
          { label: "Feedback", href: "/job-seeker/feedback" },
          { label: "Settings", href: "/job-seeker/settings" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">{title}</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Uses the same backend endpoint as Flutter: `/job-seeker/career/ai-coach`.</p>
          </div>

          <form onSubmit={submit} className="rounded-2xl bg-white p-6 shadow-sm">
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => setKind("career_path")}
                className={`rounded-lg px-3 py-1 text-xs font-extrabold ${kind === "career_path" ? "bg-[var(--primary)] text-white" : "border border-slate-200"}`}
              >
                Career Path
              </button>
              <button
                type="button"
                onClick={() => setKind("interview_prep")}
                className={`rounded-lg px-3 py-1 text-xs font-extrabold ${kind === "interview_prep" ? "bg-[var(--primary)] text-white" : "border border-slate-200"}`}
              >
                Interview Prep
              </button>
            </div>
            <label className="mt-4 block">
              <span className="mb-1 block text-sm font-bold">Focus (optional)</span>
              <textarea
                value={focus}
                onChange={(e) => setFocus(e.target.value)}
                rows={4}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                placeholder="e.g. Software engineer at product companies"
              />
            </label>
            <button type="submit" disabled={loading} className="mt-4 rounded-xl bg-[var(--primary)] px-4 py-2 text-sm font-extrabold text-white disabled:opacity-60">
              {loading ? "Generating..." : resultText ? "Regenerate" : "Generate"}
            </button>
          </form>

          {error ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--error)] shadow-sm">{error}</div> : null}
          {resultText ? (
            <div className="rounded-2xl bg-white p-6 shadow-sm">
              <h2 className="text-lg font-extrabold">Your Plan</h2>
              <pre className="mt-3 whitespace-pre-wrap text-sm font-semibold text-[var(--text-hint)]">{resultText}</pre>
            </div>
          ) : null}
        </section>
      </SiteShell>
    </Protected>
  );
}
