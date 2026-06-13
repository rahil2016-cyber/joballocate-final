"use client";

import Image from "next/image";
import Link from "next/link";
import { FormEvent, useEffect, useMemo, useState } from "react";
import { BrandLogo } from "@/components/common/brand-logo";
import { api } from "@/services/api";

type BannerItem = {
  id: string | number;
  title: string;
  subtitle?: string;
  content?: string;
  below_line?: string;
  image_url?: string;
  background_color?: string;
  text_color?: string;
  button_text?: string;
  button_link?: string;
  target_url?: string;
};

type CompanyItem = {
  id: string | number;
  name: string;
  logo_url?: string;
  company_logo_url?: string;
  open_jobs_count?: number;
};

type JobItem = {
  id: string | number;
  title: string;
  location?: string;
  employment_type?: string;
  created_at?: string;
  company?: { name?: string; logo_url?: string; company_logo_url?: string };
};

function isHttpUrl(value?: string) {
  if (!value) return false;
  return /^https?:\/\//i.test(value.trim());
}

function formatEmploymentType(value?: string) {
  if (!value) return "Full Time/Permanent";
  return value
    .replaceAll("_", " ")
    .replaceAll("-", " ")
    .replace(/\b\w/g, (m) => m.toUpperCase());
}

function formatJobDate(value?: string) {
  if (!value) return "Recent";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Recent";
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
  });
}

function LandingPage() {
  const [banners, setBanners] = useState<BannerItem[]>([]);
  const [companies, setCompanies] = useState<CompanyItem[]>([]);
  const [jobs, setJobs] = useState<JobItem[]>([]);
  const [search, setSearch] = useState("");
  const [location, setLocation] = useState("");
  const [loading, setLoading] = useState(true);
  const [bannerError, setBannerError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    Promise.allSettled([api.listBanners(), api.listTopCompanies(), api.listJobs({ per_page: 12 })])
      .then(([bannerResult, companyResult, jobResult]) => {
        if (!active) return;

        if (bannerResult.status === "fulfilled") {
          setBanners((bannerResult.value as BannerItem[]) ?? []);
          setBannerError(null);
        } else {
          const raw = bannerResult.reason instanceof Error ? bannerResult.reason.message : "Unable to load banners";
          const msg = raw.includes("SQLSTATE")
            ? "Backend database is not connected. Start MySQL and refresh."
            : raw.includes("Failed to fetch")
              ? "Backend API is unreachable. Start Laravel server and refresh."
              : raw;
          setBannerError(msg);
        }

        if (companyResult.status === "fulfilled") {
          setCompanies((companyResult.value as CompanyItem[]) ?? []);
        }
        if (jobResult.status === "fulfilled") {
          setJobs((jobResult.value as JobItem[]) ?? []);
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);

  const filteredJobs = useMemo(() => {
    return jobs.filter((job) => {
      const title = (job.title ?? "").toLowerCase();
      const company = (job.company?.name ?? "").toLowerCase();
      const jobLocation = (job.location ?? "").toLowerCase();
      const matchSearch = search.trim()
        ? title.includes(search.toLowerCase()) || company.includes(search.toLowerCase())
        : true;
      const matchLocation = location.trim() ? jobLocation.includes(location.toLowerCase()) : true;
      return matchSearch && matchLocation;
    });
  }, [jobs, location, search]);

  function onSearchSubmit(e: FormEvent) {
    e.preventDefault();
  }

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-8 px-4 py-8">
        <header className="flex flex-col gap-4 rounded-2xl bg-white p-4 shadow-sm md:flex-row md:items-center md:justify-between">
          <BrandLogo />
          <nav className="flex flex-wrap gap-2">
            <Link
              href="/auth/login/job-seeker"
              className="rounded-xl bg-[var(--primary)] px-4 py-2 text-sm font-extrabold text-white transition hover:bg-[var(--primary-dark)]"
            >
              Job Seeker Login
            </Link>
            <Link
              href="/auth/login/employer"
              className="rounded-xl border border-[var(--primary)] px-4 py-2 text-sm font-extrabold text-[var(--primary)] transition hover:bg-[var(--accent-light)]"
            >
              Employer Login
            </Link>
            <Link
              href="/auth/register"
              className="rounded-xl border border-slate-200 px-4 py-2 text-sm font-extrabold transition hover:bg-slate-100"
            >
              Register
            </Link>
          </nav>
        </header>

        <section className="rounded-3xl bg-white p-8 shadow-sm md:p-12">
          <div className="grid gap-8 lg:grid-cols-[1.15fr_0.85fr]">
            <div className="space-y-5">
              <p className="inline-flex rounded-full bg-[var(--accent-light)] px-3 py-1 text-xs font-extrabold text-[var(--primary)]">
                A1 JOB ALLOCATE
              </p>
              <h1 className="text-4xl font-black leading-tight">Take the next step towards your dream job!</h1>
              <p className="text-sm font-semibold leading-6 text-[var(--text-hint)]">
                Advance your career and find roles aligned with your skills while employers discover the right
                candidates faster.
              </p>
            </div>
            <form onSubmit={onSearchSubmit} className="space-y-3 rounded-2xl border border-slate-200 bg-slate-50 p-4">
              <p className="text-sm font-black text-[var(--primary)]">Search Jobs</p>
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Designation, skill, company"
                className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
              />
              <input
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="Search your job in your area"
                className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
              />
              <button
                type="submit"
                className="h-11 w-full rounded-xl bg-[var(--primary)] text-sm font-extrabold text-white transition hover:bg-[var(--primary-dark)]"
              >
                Explore Jobs
              </button>
            </form>
          </div>
        </section>

        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-black">Featured Highlights</h2>
            {loading ? <p className="text-xs font-bold text-[var(--text-hint)]">Loading...</p> : null}
          </div>
          {bannerError ? <p className="text-sm font-bold text-[var(--error)]">{bannerError}</p> : null}
          <div className="grid gap-4">
            {(banners.length ? banners : [{ id: "default", title: "Welcome to A1 Job Allocate", subtitle: "Find jobs and the right candidates." }]).map((banner) => {
              const href =
                banner.button_link ||
                banner.target_url ||
                (isHttpUrl(banner.content) ? banner.content : undefined);
              return (
                <article
                  key={String(banner.id)}
                  className="overflow-hidden rounded-2xl p-5 text-white shadow-sm"
                  style={{
                    background: banner.background_color
                      ? banner.background_color
                      : "linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)",
                    color: banner.text_color || "#ffffff",
                  }}
                >
                  <h3 className="text-xl font-black">{banner.title}</h3>
                  <p className="mt-2 text-sm font-semibold opacity-95">
                    {banner.subtitle ?? (!isHttpUrl(banner.content) ? banner.content : undefined) ?? "Latest opportunities and hiring updates."}
                  </p>
                  {banner.image_url ? (
                    href ? (
                      <a
                        href={href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-4 block overflow-hidden rounded-xl border border-white/20 bg-white/10 transition hover:opacity-90"
                      >
                        <Image
                          src={banner.image_url}
                          alt={banner.title}
                          width={1200}
                          height={560}
                          className="h-[220px] w-full rounded-lg object-cover md:h-[360px] lg:h-[420px]"
                        />
                      </a>
                    ) : (
                      <div className="mt-4 overflow-hidden rounded-xl border border-white/20 bg-white/10">
                        <Image
                          src={banner.image_url}
                          alt={banner.title}
                          width={1200}
                          height={560}
                          className="h-[220px] w-full rounded-lg object-cover md:h-[360px] lg:h-[420px]"
                        />
                      </div>
                    )
                  ) : null}
                  {banner.below_line ? (
                    <p className="mt-3 text-sm font-bold opacity-95">{banner.below_line}</p>
                  ) : null}
                </article>
              );
            })}
          </div>
        </section>

        <section className="grid gap-4 lg:grid-cols-2">
          <article className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-2xl font-extrabold leading-tight md:text-3xl">Career Path Roadmaps</h2>
            <div className="mt-4 rounded-2xl border border-slate-200 p-5">
              <div className="flex items-start justify-between gap-4">
                <div className="flex gap-4">
                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-slate-200 text-2xl">🗺️</div>
                  <div>
                    <p className="text-2xl font-extrabold leading-tight md:text-[2rem]">Where can I get a roadmap?</p>
                      <p className="mt-2 text-base font-semibold leading-snug text-[var(--text-hint)] md:text-lg">Expert-curated paths for success.</p>
                  </div>
                </div>
                <p className="text-2xl font-bold text-[var(--primary)] md:text-[2rem]">›</p>
              </div>
              <button className="mt-5 h-11 w-full rounded-full bg-indigo-100 text-sm font-bold text-[var(--primary)] md:text-base">
                ✨ AI career plan for my profile
              </button>
            </div>
          </article>

          <article className="rounded-2xl bg-white p-6 shadow-sm">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-2xl font-extrabold leading-tight md:text-3xl">Interview Prep</h2>
              <span className="rounded-full bg-indigo-100 px-3 py-1 text-xs font-bold text-indigo-500 md:text-sm">AI-powered</span>
            </div>
            <div className="rounded-2xl border border-slate-100 p-6">
              <p className="text-2xl font-extrabold leading-snug md:text-[2rem]">Decode commonly asked interview questions.</p>
              <div className="mt-6 grid grid-cols-4 gap-4 text-center">
                <div>
                  <p className="text-2xl">💡</p>
                  <p className="mt-1 text-sm font-bold text-[var(--primary)] md:text-base">AI coach</p>
                </div>
                <div>
                  <p className="text-2xl">📘</p>
                  <p className="mt-1 text-sm font-bold text-[var(--primary)] md:text-base">Prepare</p>
                </div>
                <div>
                  <p className="text-2xl">👥</p>
                  <p className="mt-1 text-sm font-bold text-[var(--primary)] md:text-base">Participate</p>
                </div>
                <div>
                  <p className="text-2xl">💼</p>
                  <p className="mt-1 text-sm font-bold text-[var(--primary)] md:text-base">Opportunities</p>
                </div>
              </div>
            </div>
          </article>
        </section>

        <section className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-2xl font-black">Top Companies are Hiring</h2>
            <Link href="/employer/home" className="text-sm font-extrabold text-[var(--primary)]">
              View all
            </Link>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {(companies.length ? companies : []).slice(0, 9).map((company) => (
              <article key={String(company.id)} className="rounded-xl border border-slate-200 p-4 transition hover:border-[var(--primary)]">
                <p className="text-sm font-black">{company.name}</p>
                <p className="mt-1 text-xs font-semibold text-[var(--text-hint)]">{company.open_jobs_count ?? 0} Open Jobs</p>
              </article>
            ))}
          </div>
        </section>

        <section className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-2xl font-black">Featured Jobs</h2>
            <Link href="/" className="text-sm font-extrabold text-[var(--primary)]">
              View all
            </Link>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {filteredJobs.slice(0, 8).map((job) => {
              const companyName = job.company?.name ?? "Company";
              const logoUrl = job.company?.company_logo_url ?? job.company?.logo_url;
              return (
                <article
                  key={String(job.id)}
                  className="rounded-2xl border border-slate-200 p-3 transition hover:border-[var(--primary)] hover:shadow-sm"
                >
                  <p className="inline-flex items-center gap-1 text-xs font-semibold text-slate-500">
                    <span className="text-[10px]">💼</span> {formatEmploymentType(job.employment_type)}
                  </p>
                  <p className="mt-2 line-clamp-2 min-h-[48px] text-xl font-black leading-tight">{job.title}</p>
                  <p className="mt-2 inline-flex items-center gap-1 text-sm font-bold text-[var(--primary)]">
                    <span>📍</span> {job.location ?? "India"}
                  </p>

                  <div className="mt-3 flex items-center justify-between rounded-xl bg-slate-100 px-3 py-2">
                    <div>
                      <p className="text-xs font-medium text-slate-500">{formatJobDate(job.created_at)}</p>
                      <p className="text-base font-extrabold">{companyName}</p>
                    </div>
                    <div className="flex h-12 w-12 items-center justify-center overflow-hidden rounded-full border border-slate-200 bg-white">
                      {logoUrl ? (
                        <Image src={logoUrl} alt={companyName} width={48} height={48} className="h-full w-full object-cover" />
                      ) : (
                        <span className="text-base font-black text-[var(--primary)]">{companyName.charAt(0).toUpperCase()}</span>
                      )}
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
          {!filteredJobs.length ? (
            <p className="mt-4 text-sm font-bold text-[var(--text-hint)]">No jobs matched your search.</p>
          ) : null}
        </section>

        <section>
          <article className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-2xl font-extrabold leading-tight md:text-3xl">Your resume is ready! Choose a template &amp; download now.</h2>
            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              <div className="rounded-2xl border border-slate-200 p-3">
                <p className="text-xl font-bold md:text-2xl">Professional Grand</p>
                <div className="mt-3 overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
                  <Image
                    src="/api/logo"
                    alt="Resume template preview"
                    width={500}
                    height={380}
                    className="h-60 w-full object-contain"
                  />
                </div>
                <div className="mt-4 flex gap-2">
                  <button className="h-11 flex-1 rounded-xl border-2 border-[var(--primary)] text-xl font-bold text-[var(--primary)]">Download</button>
                  <button className="h-11 flex-1 rounded-xl border border-slate-300 text-xl font-bold text-[var(--primary)]">Edit</button>
                </div>
              </div>
              <div className="rounded-2xl border border-slate-200 p-3">
                <p className="text-xl font-bold md:text-2xl">Summit Stream</p>
                <div className="mt-3 overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
                  <Image
                    src="/api/logo"
                    alt="Resume template preview"
                    width={500}
                    height={380}
                    className="h-60 w-full object-contain"
                  />
                </div>
                <div className="mt-4">
                  <button className="h-11 w-full rounded-xl border-2 border-[var(--primary)] text-xl font-bold text-[var(--primary)]">Download</button>
                </div>
              </div>
            </div>
          </article>
        </section>
      </div>
    </div>
  );
}

export { LandingPage };
export default LandingPage;
