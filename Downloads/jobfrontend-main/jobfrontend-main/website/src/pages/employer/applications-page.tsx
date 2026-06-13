"use client";

import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { EmptyState } from "@/components/common/states";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type JobPost = { id: string; title?: string };
type Application = {
  id: string;
  status?: string;
  employer_note?: string;
  user?: { name?: string; email?: string };
};

export default function EmployerApplicationsPage() {
  const [jobs, setJobs] = useState<JobPost[]>([]);
  const [selectedJobId, setSelectedJobId] = useState<string>("");
  const [applications, setApplications] = useState<Application[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [noteByApplication, setNoteByApplication] = useState<Record<string, string>>({});

  useEffect(() => {
    let mounted = true;
    api
      .companyJobPosts()
      .then((rows) => {
        if (!mounted) return;
        const parsed = rows as JobPost[];
        setJobs(parsed);
        if (parsed.length) setSelectedJobId(parsed[0].id);
      })
      .catch(() => {
        if (!mounted) return;
        setJobs([]);
      });
    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (!selectedJobId) return;
    let mounted = true;
    api
      .companyApplications(selectedJobId)
      .then((rows) => {
        if (!mounted) return;
        const parsed = rows as Application[];
        setApplications(parsed);
        const notes: Record<string, string> = {};
        for (const item of parsed) {
          notes[item.id] = item.employer_note ?? "";
        }
        setNoteByApplication(notes);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load applications");
        setApplications([]);
      });
    return () => {
      mounted = false;
    };
  }, [selectedJobId]);

  async function updateStatus(applicationId: string, status: string) {
    if (!selectedJobId) return;
    setMessage(null);
    try {
      const employerNote = noteByApplication[applicationId]?.trim();
      await api.companyUpdateApplicationStatus(selectedJobId, applicationId, {
        status,
        employer_note: employerNote ? employerNote : undefined,
      });
      setApplications((prev) =>
        prev.map((item) =>
          item.id === applicationId
            ? {
                ...item,
                status,
                employer_note: employerNote ? employerNote : item.employer_note,
              }
            : item,
        ),
      );
      setMessage("Application status updated.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to update status");
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
            <h1 className="text-2xl font-black">Manage Applications</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Review and update applicant statuses for each job post.</p>
          </div>
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <label className="mb-2 block text-sm font-bold">Select job post</label>
            <select
              value={selectedJobId}
              onChange={(e) => setSelectedJobId(e.target.value)}
              className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
            >
              <option value="">Choose job</option>
              {jobs.map((job) => (
                <option key={job.id} value={job.id}>
                  {job.title ?? "Untitled job"}
                </option>
              ))}
            </select>
          </div>
          {error ? (
            <p role="alert" aria-live="assertive" className="text-sm font-bold text-[var(--error)]">
              {error}
            </p>
          ) : null}
          {message ? (
            <p role="status" aria-live="polite" className="text-sm font-bold text-[var(--primary)]">
              {message}
            </p>
          ) : null}
          <div className="space-y-3">
            {applications.map((application) => (
              <article key={application.id} className="rounded-2xl bg-white p-5 shadow-sm">
                <h2 className="text-lg font-extrabold">{application.user?.name ?? "Applicant"}</h2>
                <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">{application.user?.email ?? "No email"}</p>
                <p className="mt-2 text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">
                  Current status: {application.status ?? "pending"}
                </p>
                <div className="mt-4 flex flex-wrap gap-2">
                  {["shortlisted", "rejected", "hired"].map((status) => (
                    <button
                      key={status}
                      onClick={() => updateStatus(application.id, status)}
                      className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold"
                    >
                      Mark {status}
                    </button>
                  ))}
                </div>
                <label className="mt-3 block">
                  <span className="mb-1 block text-xs font-extrabold uppercase tracking-wide text-[var(--text-hint)]">Employer Note</span>
                  <textarea
                    aria-label={`Employer note for ${application.user?.name ?? "applicant"}`}
                    value={noteByApplication[application.id] ?? ""}
                    onChange={(e) =>
                      setNoteByApplication((prev) => ({
                        ...prev,
                        [application.id]: e.target.value,
                      }))
                    }
                    className="min-h-20 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    placeholder="Add a note for the candidate"
                  />
                </label>
                {application.employer_note ? (
                  <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">Current note: {application.employer_note}</p>
                ) : null}
              </article>
            ))}
            {!applications.length ? <EmptyState title="No applications found for selected job." /> : null}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
