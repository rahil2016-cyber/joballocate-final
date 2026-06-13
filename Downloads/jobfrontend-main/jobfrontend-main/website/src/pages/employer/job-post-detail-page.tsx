"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type JobPost = {
  id: string;
  title?: string;
  location?: string;
  description?: string;
  status?: string;
};

export default function EmployerJobPostDetailPage({ jobId }: { jobId: string }) {
  const [jobs, setJobs] = useState<JobPost[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [location, setLocation] = useState("");
  const [description, setDescription] = useState("");
  const [status, setStatus] = useState("published");

  useEffect(() => {
    let mounted = true;
    api
      .companyJobPosts()
      .then((rows) => {
        if (!mounted) return;
        const parsed = rows as JobPost[];
        setJobs(parsed);
        const current = parsed.find((item) => String(item.id) === jobId);
        if (current) {
          setTitle(current.title ?? "");
          setLocation(current.location ?? "");
          setDescription(current.description ?? "");
          setStatus(current.status ?? "published");
        } else {
          setError("Job post not found.");
        }
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load job post");
      });
    return () => {
      mounted = false;
    };
  }, [jobId]);

  const currentJob = useMemo(() => jobs.find((item) => String(item.id) === jobId) ?? null, [jobs, jobId]);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setMessage(null);
    try {
      await api.updateJobPost(jobId, {
        title: title.trim(),
        location: location.trim(),
        description: description.trim(),
        status,
      });
      setMessage("Job post updated.");
      setJobs((prev) =>
        prev.map((item) =>
          String(item.id) === jobId ? { ...item, title: title.trim(), location: location.trim(), description: description.trim(), status } : item,
        ),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to update job post");
    }
  }

  return (
    <Protected role="company">
      <SiteShell
        navItems={[
          { label: "Dashboard", href: "/employer/dashboard" },
          { label: "Home", href: "/employer/home" },
          { label: "Applications", href: "/employer/applications" },
          { label: "Subscriptions", href: "/employer/subscription/history" },
          { label: "Profile", href: "/employer/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Edit Job Post</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Update title, description, location and job status.</p>
          </div>
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          {message ? <p className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {currentJob ? (
            <form onSubmit={submit} className="rounded-2xl bg-white p-6 shadow-sm">
              <div className="grid gap-4 md:grid-cols-2">
                <label>
                  <span className="mb-1 block text-sm font-bold">Title</span>
                  <input
                    required
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  />
                </label>
                <label>
                  <span className="mb-1 block text-sm font-bold">Location</span>
                  <input
                    required
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  />
                </label>
                <label className="md:col-span-2">
                  <span className="mb-1 block text-sm font-bold">Description</span>
                  <textarea
                    required
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="min-h-24 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  />
                </label>
                <label>
                  <span className="mb-1 block text-sm font-bold">Status</span>
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  >
                    <option value="published">Published</option>
                    <option value="pending_review">Pending Review</option>
                    <option value="closed">Closed</option>
                  </select>
                </label>
              </div>
              <div className="mt-5 max-w-56">
                <PrimaryButton type="submit">Save Job Post</PrimaryButton>
              </div>
            </form>
          ) : null}
        </section>
      </SiteShell>
    </Protected>
  );
}
