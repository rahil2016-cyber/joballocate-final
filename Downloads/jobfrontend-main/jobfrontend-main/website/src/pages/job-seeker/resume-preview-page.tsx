"use client";

import { useEffect, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type ResumeDraft = {
  id: number;
  title?: string;
  template_id?: string;
  content?: Record<string, unknown>;
};

type Section = { id?: string; title?: string; body?: string };

function asList(value: unknown): string[] {
  return Array.isArray(value) ? value.map((item) => String(item)) : [];
}

export default function ResumePreviewPage({ draftId }: { draftId: string }) {
  const [draft, setDraft] = useState<ResumeDraft | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .resumeDraftById(draftId)
      .then((row) => {
        if (!mounted) return;
        setDraft(row as ResumeDraft | null);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load draft preview");
      });
    return () => {
      mounted = false;
    };
  }, [draftId]);

  const summary = String(draft?.content?.summary ?? "");
  const skills = asList(draft?.content?.skills);
  const experience = asList(draft?.content?.experience);
  const education = asList(draft?.content?.education);
  const projects = asList(draft?.content?.projects);
  const certifications = asList(draft?.content?.certifications);
  const languages = asList(draft?.content?.languages);
  const sectionRows = Array.isArray(draft?.content?.sections) ? (draft?.content?.sections as Section[]) : [];
  const isSectionsV2 = String(draft?.content?.format ?? "") === "sections_v2" && sectionRows.length > 0;

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
            <h1 className="text-2xl font-black">Resume Preview</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
              {draft?.title ?? "Draft"} • Template {draft?.template_id ?? "N/A"}
            </p>
            <button onClick={() => window.print()} className="mt-3 rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold">
              Print / Save as PDF
            </button>
          </div>
          {error ? <p role="alert" className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          {!draft ? (
            <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">Draft not found.</div>
          ) : isSectionsV2 ? (
            <article className="rounded-2xl bg-white p-6 shadow-sm">
              {sectionRows.map((section, index) => (
                <section key={`${section.id ?? "section"}-${index}`} className="mb-4 last:mb-0">
                  <h2 className="text-base font-extrabold uppercase tracking-wide text-[var(--primary)]">{section.title ?? "Section"}</h2>
                  <p className="mt-2 whitespace-pre-wrap text-sm font-semibold text-slate-700">{section.body ?? ""}</p>
                </section>
              ))}
            </article>
          ) : (
            <article className="rounded-2xl bg-white p-6 shadow-sm">
              {summary ? (
                <>
                  <h2 className="text-lg font-extrabold">Professional Summary</h2>
                  <p className="mt-2 whitespace-pre-line text-sm font-semibold text-slate-700">{summary}</p>
                </>
              ) : null}
              <div className="mt-4 grid gap-4 md:grid-cols-2">
                {[
                  { label: "Skills", rows: skills },
                  { label: "Experience", rows: experience },
                  { label: "Education", rows: education },
                  { label: "Projects", rows: projects },
                  { label: "Certifications", rows: certifications },
                  { label: "Languages", rows: languages },
                ].map((section) => (
                  <div key={section.label} className="rounded-xl border border-slate-200 p-3">
                    <h3 className="text-sm font-extrabold">{section.label}</h3>
                    {section.rows.length ? (
                      <ul className="mt-2 list-disc space-y-1 pl-5 text-sm font-semibold text-slate-700">
                        {section.rows.map((row, idx) => (
                          <li key={`${section.label}-${idx}`}>{row}</li>
                        ))}
                      </ul>
                    ) : (
                      <p className="mt-2 text-xs font-semibold text-[var(--text-hint)]">No entries</p>
                    )}
                  </div>
                ))}
              </div>
            </article>
          )}
        </section>
      </SiteShell>
    </Protected>
  );
}
