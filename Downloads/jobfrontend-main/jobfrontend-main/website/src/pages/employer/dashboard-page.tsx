"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { RoleBanners } from "@/components/common/role-banners";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type JobPost = {
  id: string;
  title: string;
  status?: string;
};

function EmployerDashboardPage() {
  const [jobs, setJobs] = useState<JobPost[]>([]);
  const [title, setTitle] = useState("");
  const [location, setLocation] = useState("");
  const [description, setDescription] = useState("");
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    api
      .companyJobPosts()
      .then((posts) => {
        if (!active) return;
        setJobs(posts as JobPost[]);
      })
      .catch(() => {
        if (!active) return;
        setJobs([]);
      });
    return () => {
      active = false;
    };
  }, []);

  async function postJob(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    try {
      await api.createJobPost({
        title,
        location,
        description,
      });
      setTitle("");
      setLocation("");
      setDescription("");
      setMessage("Job post created.");
      const posts = await api.companyJobPosts();
      setJobs(posts as JobPost[]);
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Unable to create job");
    }
  }

  const published = jobs.filter((j) => j.status === "published").length;
  const pending = jobs.filter((j) => j.status === "pending_review").length;

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
        <div className="space-y-4">
          <RoleBanners audience="employer" />
          <div className="grid gap-4 md:grid-cols-2">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-bold text-[var(--text-hint)]">Published Jobs</p>
            <h1 className="mt-2 text-4xl font-black">{published}</h1>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <p className="text-sm font-bold text-[var(--text-hint)]">Pending Review</p>
            <h2 className="mt-2 text-4xl font-black">{pending}</h2>
          </div>
          </div>

        <form onSubmit={postJob} className="rounded-2xl bg-white p-6 shadow-sm">
          <h3 className="text-xl font-black">Post New Job</h3>
          <div className="mt-4 grid gap-4 md:grid-cols-2">
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
          </div>
          {message ? <p className="mt-3 text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          <div className="mt-4 max-w-56">
            <PrimaryButton type="submit">Publish Job</PrimaryButton>
          </div>
        </form>
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h3 className="text-xl font-black">Your Job Posts</h3>
          <div className="mt-4 space-y-3">
            {jobs.map((job) => (
              <article key={job.id} className="rounded-xl border border-slate-200 p-4">
                <p className="font-extrabold">{job.title}</p>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">Status: {job.status ?? "unknown"}</p>
                <Link href={`/employer/jobs/${job.id}`} className="mt-2 inline-block text-sm font-extrabold text-[var(--primary)] underline">
                  Open and edit
                </Link>
              </article>
            ))}
          </div>
        </div>
        </div>
      </SiteShell>
    </Protected>
  );
}

export { EmployerDashboardPage };
export default EmployerDashboardPage;
