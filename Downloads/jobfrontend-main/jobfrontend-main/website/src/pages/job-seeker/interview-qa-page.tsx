"use client";

import { useEffect, useMemo, useState } from "react";
import { Protected } from "@/components/common/protected";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type QaItem = {
  id?: number | string;
  question?: string;
  answer?: string;
  helpful_count?: number;
  user_marked_helpful?: boolean;
};

type Category = {
  category?: string;
  items?: QaItem[];
};

export default function InterviewQaPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategory, setSelectedCategory] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .careerContentsRaw("interview_qa")
      .then((data) => {
        if (!mounted) return;
        const categoryRows = Array.isArray(data.categories) ? (data.categories as Category[]) : [];
        setCategories(categoryRows);
        if (categoryRows.length) {
          setSelectedCategory(String(categoryRows[0]?.category || ""));
        }
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load interview Q&A");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });
    return () => {
      mounted = false;
    };
  }, []);

  const questions = useMemo(() => {
    const match = categories.find((row) => String(row.category || "") === selectedCategory);
    return Array.isArray(match?.items) ? match.items : [];
  }, [categories, selectedCategory]);

  async function toggleHelpful(item: QaItem) {
    const id = item.id;
    if (id === undefined || id === null) return;
    const nextState = !(item.user_marked_helpful === true);
    try {
      const result = await api.markCareerContentHelpful(String(id), { is_helpful: nextState });
      const nextMarked = result.user_marked_helpful === true;
      const nextCount = Number(result.helpful_count ?? item.helpful_count ?? 0);
      setCategories((prev) =>
        prev.map((cat) => ({
          ...cat,
          items: (cat.items || []).map((row) =>
            String(row.id) === String(id) ? { ...row, user_marked_helpful: nextMarked, helpful_count: nextCount } : row,
          ),
        })),
      );
    } catch {
      setError("Unable to update helpful state.");
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
          { label: "Interview Q&A", href: "/job-seeker/interview-qa" },
          { label: "Feedback", href: "/job-seeker/feedback" },
          { label: "Settings", href: "/job-seeker/settings" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Interview Q&amp;A Pro</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Category-wise interview questions from your backend content feed.</p>
            <div className="mt-4 flex flex-wrap gap-2">
              {categories.map((cat) => {
                const name = String(cat.category || "General");
                const active = name === selectedCategory;
                return (
                  <button
                    key={name}
                    onClick={() => setSelectedCategory(name)}
                    className={`rounded-lg px-3 py-1 text-xs font-extrabold ${active ? "bg-[var(--primary)] text-white" : "border border-slate-200"}`}
                  >
                    {name}
                  </button>
                );
              })}
            </div>
          </div>

          {loading ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold shadow-sm">Loading questions...</div> : null}
          {error ? <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--error)] shadow-sm">{error}</div> : null}
          {!loading && !error && !categories.length ? (
            <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">
              No interview questions yet. Admin will publish Q&amp;A content here.
            </div>
          ) : null}

          <div className="space-y-3">
            {questions.map((item, idx) => (
              <article key={String(item.id ?? idx)} className="rounded-2xl bg-white p-5 shadow-sm">
                <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">Q{idx + 1}</p>
                <h2 className="mt-1 text-lg font-extrabold">{item.question || "Question"}</h2>
                <p className="mt-3 whitespace-pre-wrap text-sm font-semibold text-[var(--text-hint)]">{item.answer || "Answer pending."}</p>
                <button
                  onClick={() => toggleHelpful(item)}
                  className={`mt-3 rounded-lg border px-3 py-1 text-xs font-extrabold ${item.user_marked_helpful ? "border-[var(--primary)] text-[var(--primary)]" : "border-slate-200"}`}
                >
                  Helpful ({Number(item.helpful_count ?? 0)})
                </button>
              </article>
            ))}
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}
