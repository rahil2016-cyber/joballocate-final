"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type ResumeDraft = {
  id: number;
  title?: string;
  template_id?: string;
  content?: Record<string, unknown>;
  is_primary?: boolean;
  created_at?: string;
};

const activeResumeTemplates: Array<{
  id: string;
  name: string;
  accent: string;
  bar: string;
  previewImage: string;
  previewFit?: "contain" | "cover";
  previewZoom?: number;
  previewOffsetY?: string;
}> = [
  {
    id: "22",
    name: "Rahil Blue Pro",
    accent: "bg-cyan-100",
    bar: "bg-cyan-700",
    previewImage: "/resume-templates/mohammed-22.png",
  },
  {
    id: "21",
    name: "Executive Clean",
    accent: "bg-slate-100",
    bar: "bg-slate-800",
    previewImage: "/resume-templates/executive-21.png",
  },
];

export default function JobSeekerResumesPage() {
  const router = useRouter();
  const [drafts, setDrafts] = useState<ResumeDraft[]>([]);
  const [creatingTemplateId, setCreatingTemplateId] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .resumeDrafts()
      .then((rows) => {
        if (!mounted) return;
        setDrafts(rows as ResumeDraft[]);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load resumes");
      });
    return () => {
      mounted = false;
    };
  }, []);

  async function startWithTemplate(templateId: string, templateName: string) {
    setMessage(null);
    setError(null);
    setCreatingTemplateId(templateId);
    try {
      const title = `${templateName} Resume`;
      const created = (await api.saveResumeDraft({
        title,
        template_id: templateId,
        content: {
          format: "sections_v2",
          sections: [
            { id: "name", title: "Name", body: "Your Name" },
            { id: "role", title: "Role", body: "Your Role" },
            { id: "summary", title: "Summary", body: "Write your professional summary here." },
            { id: "phone", title: "Phone", body: "" },
            { id: "email", title: "Email", body: "" },
            { id: "address", title: "Address", body: "" },
            { id: "education", title: "Education", body: "" },
            { id: "skills", title: "Skills", body: "" },
            { id: "languages", title: "Languages", body: "" },
            { id: "experience", title: "Experience", body: "" },
            { id: "references", title: "References", body: "" },
          ],
        },
      })) as Record<string, unknown>;

      const createdId = Number(created.id ?? 0);
      if (createdId > 0) {
        router.push(`/job-seeker/resumes/${createdId}`);
        return;
      }

      const rows = await api.resumeDrafts();
      const nextRows = rows as ResumeDraft[];
      setDrafts(nextRows);
      const candidate = nextRows[0];
      if (candidate?.id) {
        router.push(`/job-seeker/resumes/${candidate.id}`);
      } else {
        setMessage("Draft created. Open it from Saved Drafts.");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to create resume from template");
    } finally {
      setCreatingTemplateId(null);
    }
  }

  async function setPrimary(draftId: number) {
    setMessage(null);
    setError(null);
    try {
      await api.setPrimaryResume({ resume_draft_id: draftId });
      setDrafts((prev) => prev.map((item) => ({ ...item, is_primary: item.id === draftId })));
      setMessage("Primary resume updated.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to set primary resume");
    }
  }

  async function unlockPdf(template: number, label: string) {
    setMessage(null);
    setError(null);
    try {
      await api.resumePdfPurchase({ resume_template_id: template, resume_template_title: label });
      setMessage("PDF export purchase recorded successfully.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to unlock PDF export");
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
            <h1 className="text-2xl font-black">Choose Resume Template</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Click a template to open editor, customize, and download.</p>
          </div>
          {message ? (
            <p role="status" aria-live="polite" className="text-sm font-bold text-[var(--primary)]">
              {message}
            </p>
          ) : null}
          {error ? (
            <p role="alert" aria-live="assertive" className="text-sm font-bold text-[var(--error)]">
              {error}
            </p>
          ) : null}

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            {activeResumeTemplates.length ? (
              <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                {activeResumeTemplates.map((template) => (
                  <article key={template.id} className="rounded-2xl border border-slate-200 p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                    <div className={`rounded-xl border border-slate-200 ${template.accent} p-2`}>
                      <div className="rounded-lg bg-white p-3">
                        <div className="mx-auto aspect-[1/1.414] w-full max-w-[360px] overflow-hidden rounded-md border border-slate-100 bg-slate-50">
                          {template.previewImage ? (
                            <img
                              src={template.previewImage}
                              alt={`${template.name} HD preview`}
                              className={`h-full w-full origin-top ${template.previewFit === "cover" ? "object-cover object-top" : "object-contain"}`}
                              style={{
                                transform: template.previewZoom ? `scale(${template.previewZoom})` : undefined,
                                transformOrigin: "top center",
                                objectPosition: template.previewOffsetY ? `center ${template.previewOffsetY}` : undefined,
                              }}
                            />
                          ) : (
                            <>
                              <div className={`m-3 h-3 w-24 rounded ${template.bar}`} />
                              <div className="mx-3 mt-2 grid h-[calc(100%-2.5rem)] grid-cols-[1fr_2fr] gap-2">
                                <div className="space-y-1">
                                  <div className="h-12 rounded bg-slate-200" />
                                  <div className="h-2 rounded bg-slate-300" />
                                  <div className="h-2 rounded bg-slate-300" />
                                  <div className="h-2 rounded bg-slate-300" />
                                </div>
                                <div className="space-y-1">
                                  <div className="h-2 rounded bg-slate-300" />
                                  <div className="h-2 rounded bg-slate-300" />
                                  <div className="h-2 rounded bg-slate-300" />
                                  <div className="h-2 rounded bg-slate-300" />
                                  <div className="h-2 rounded bg-slate-300" />
                                </div>
                              </div>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                    <p className="mt-3 text-sm font-extrabold">{template.name}</p>
                    <p className="mt-1 text-xs font-semibold text-[var(--text-hint)]">
                      {template.previewImage ? "HD preview loaded • Click Use Template to edit" : "Template preview • Click to edit"}
                    </p>
                    <div className="mt-3 flex gap-2">
                      {template.previewImage ? (
                        <a
                          href={template.previewImage}
                          target="_blank"
                          rel="noreferrer"
                          className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold"
                        >
                          Open Full Image
                        </a>
                      ) : null}
                      <button
                        onClick={() => startWithTemplate(template.id, template.name)}
                        className="rounded-lg bg-[var(--primary)] px-3 py-2 text-xs font-extrabold text-white"
                      >
                        {creatingTemplateId === template.id ? "Opening..." : "Use Template"}
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            ) : (
              <div className="rounded-xl border border-dashed border-slate-300 p-6 text-center text-sm font-semibold text-[var(--text-hint)]">
                No templates configured. Upload new resume templates and I will wire them here.
              </div>
            )}
          </div>
 
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Saved Drafts</h2>
            <div className="mt-4 space-y-3">
              {drafts.map((draft) => (
                <article key={draft.id} className="rounded-xl border border-slate-200 p-4">
                  <p className="font-extrabold">{draft.title ?? "Untitled draft"}</p>
                  <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">
                    Template: {draft.template_id ?? "N/A"} • {draft.created_at ? new Date(draft.created_at).toLocaleDateString() : ""}
                  </p>
                  <div className="mt-3 flex flex-wrap gap-3">
                    <button onClick={() => setPrimary(draft.id)} className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                      {draft.is_primary ? "Primary Resume" : "Set as Primary"}
                    </button>
                    <button onClick={() => unlockPdf(1, draft.title ?? "Resume")} className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                      Unlock PDF Export
                    </button>
                    <Link href={`/job-seeker/resumes/${draft.id}`} className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                      Open Draft
                    </Link>
                    <Link href={`/job-seeker/resumes/${draft.id}/preview`} className="rounded-lg border border-slate-200 px-3 py-1 text-xs font-extrabold">
                      Preview / PDF
                    </Link>
                  </div>
                </article>
              ))}
              {!drafts.length ? <p className="text-sm font-semibold text-[var(--text-hint)]">No drafts saved yet.</p> : null}
            </div>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
