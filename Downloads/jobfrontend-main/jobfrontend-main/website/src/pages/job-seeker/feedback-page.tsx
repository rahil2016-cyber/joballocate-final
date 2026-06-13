"use client";

import { FormEvent, useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { EmptyState, ErrorState } from "@/components/common/states";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type FeedbackItem = {
  id: string;
  rating?: number;
  message?: string;
  admin_reply?: string;
  created_at?: string;
};

export default function JobSeekerFeedbackPage() {
  const [history, setHistory] = useState<FeedbackItem[]>([]);
  const [rating, setRating] = useState(5);
  const [messageInput, setMessageInput] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .seekerFeedbackHistory()
      .then((rows) => {
        if (!mounted) return;
        setHistory(rows as FeedbackItem[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load feedback history");
        setHistory([]);
      });
    return () => {
      mounted = false;
    };
  }, []);

  async function submitFeedback(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    setError(null);
    try {
      await api.submitSeekerFeedback({
        rating,
        message: messageInput.trim() || undefined,
      });
      setMessage("Feedback submitted successfully.");
      setMessageInput("");
      const rows = await api.seekerFeedbackHistory();
      setHistory(rows as FeedbackItem[]);
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
            <h1 className="text-2xl font-black">Rate & Feedback</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Share your experience and track admin replies.</p>
          </div>
          <form onSubmit={submitFeedback} className="rounded-2xl bg-white p-6 shadow-sm">
            <label className="mb-1 block text-sm font-bold">Rating</label>
            <select
              value={rating}
              onChange={(e) => setRating(Number(e.target.value))}
              className="h-11 w-full max-w-xs rounded-lg border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
            >
              {[5, 4, 3, 2, 1].map((n) => (
                <option key={n} value={n}>
                  {n} Star{n > 1 ? "s" : ""}
                </option>
              ))}
            </select>
            <label className="mt-4 block">
              <span className="mb-1 block text-sm font-bold">Message (optional)</span>
              <textarea
                value={messageInput}
                onChange={(e) => setMessageInput(e.target.value)}
                className="min-h-24 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                placeholder="Share what we can improve"
              />
            </label>
            <div className="mt-4 max-w-52">
              <PrimaryButton type="submit">Submit Feedback</PrimaryButton>
            </div>
          </form>
          {message ? <p role="status" className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {error ? <ErrorState title={error} /> : null}
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Your Feedback History</h2>
            <div className="mt-4 space-y-3">
              {history.map((item) => (
                <article key={item.id} className="rounded-xl border border-slate-200 p-4">
                  <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">Rating: {item.rating ?? "-"}</p>
                  <p className="mt-1 text-sm font-semibold text-slate-700">{item.message ?? "No message provided."}</p>
                  {item.admin_reply ? <p className="mt-2 text-sm font-semibold text-[var(--primary)]">Admin reply: {item.admin_reply}</p> : null}
                  <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">
                    {item.created_at ? new Date(item.created_at).toLocaleDateString() : "N/A"}
                  </p>
                </article>
              ))}
              {!history.length ? <EmptyState title="No submissions yet." /> : null}
            </div>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
