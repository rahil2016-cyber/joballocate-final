"use client";

import { useEffect, useState } from "react";
import { api } from "@/services/api";

type JobDetail = {
  id: string;
  title?: string;
  description?: string;
  company_name?: string;
  location?: string;
  job_type?: string;
  salary?: string;
};

export default function JobDetailPage({ jobId }: { jobId: string }) {
  const [job, setJob] = useState<JobDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .getJob(jobId)
      .then((data) => {
        if (!mounted) return;
        setJob(data as JobDetail);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load job details");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });

    return () => {
      mounted = false;
    };
  }, [jobId]);

  async function saveJob() {
    try {
      await api.saveJob(jobId);
      setActionMessage("Job saved successfully.");
    } catch (err) {
      setActionMessage(err instanceof Error ? err.message : "Unable to save job");
    }
  }

  async function applyJob() {
    try {
      await api.applyToJob(jobId);
      setActionMessage("Application submitted successfully.");
    } catch (err) {
      setActionMessage(err instanceof Error ? err.message : "Unable to apply now");
    }
  }

  if (loading) return <p className="text-sm font-bold">Loading job details...</p>;
  if (error) return <p className="text-sm font-bold text-[var(--error)]">{error}</p>;
  if (!job) return <p className="text-sm font-bold">Job not found.</p>;

  return (
    <section className="space-y-4">
      <article className="rounded-2xl bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-black">{job.title ?? "Job Details"}</h1>
        <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
          {job.company_name ?? "Company"} • {job.location ?? "Location"}
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          <span className="rounded-full bg-[var(--accent-light)] px-3 py-1 text-xs font-extrabold text-[var(--primary)]">
            {job.job_type ?? "Job"}
          </span>
          {job.salary ? (
            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-extrabold text-slate-700">{job.salary}</span>
          ) : null}
        </div>
        <p className="mt-5 whitespace-pre-line text-sm font-semibold leading-6 text-slate-700">{job.description ?? "No description available."}</p>
      </article>
      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <div className="flex flex-wrap gap-3">
          <button onClick={applyJob} className="rounded-xl bg-[var(--primary)] px-4 py-2 text-sm font-extrabold text-white">
            Apply now
          </button>
          <button onClick={saveJob} className="rounded-xl border border-slate-200 px-4 py-2 text-sm font-extrabold">
            Save job
          </button>
        </div>
        {actionMessage ? <p className="mt-3 text-sm font-bold text-[var(--primary)]">{actionMessage}</p> : null}
      </div>
    </section>
  );
}
