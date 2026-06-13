"use client";

import Link from "next/link";
import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { SiteShell } from "@/components/layout/site-shell";
import { useAuth } from "@/hooks/use-auth";
import { api } from "@/services/api";
import { getToken, saveSession } from "@/services/auth-storage";

type JobSeekerProfile = {
  name?: string;
  email?: string;
  phone?: string;
  headline?: string;
  city?: string;
  state?: string;
  district?: string;
  country?: string;
  bio?: string;
  profile_photo_url?: string;
  skills?: string[];
  experience_years?: number | string;
  expected_salary_min?: number | string;
  expected_salary_max?: number | string;
  education?: Array<{
    title?: string;
    institution?: string;
    board_or_stream?: string;
    marks_or_grade?: string;
    year_completed?: string;
  }>;
  profile_completion_percent?: number | string;
};

function profileCompletion(profile: JobSeekerProfile | null) {
  if (!profile) return 0;
  const backend = Number(profile.profile_completion_percent);
  if (Number.isFinite(backend) && backend > 0) return Math.max(0, Math.min(100, backend));

  let score = 0;
  if ((profile.headline || "").trim()) score += 14;
  if ((profile.bio || "").trim()) score += 14;
  if (Array.isArray(profile.skills) && profile.skills.length) score += 20;
  if ((profile.city || "").trim()) score += 14;
  if ((profile.country || "").trim()) score += 14;
  if (String(profile.experience_years ?? "").trim()) score += 12;
  if (String(profile.expected_salary_min ?? "").trim() || String(profile.expected_salary_max ?? "").trim()) score += 12;
  if ((profile.profile_photo_url || "").trim()) score += 10;
  return Math.max(0, Math.min(100, score));
}

function JobSeekerProfilePage() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<JobSeekerProfile | null>(null);
  const [form, setForm] = useState<Record<string, string>>({
    name: "",
    headline: "",
    city: "",
    state: "",
    district: "",
    bio: "",
  });
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState<string | null>(null);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);
  const photoInputRef = useRef<HTMLInputElement>(null);

  const displayName = useMemo(() => {
    const profileName = String(profile?.name ?? "").trim();
    if (profileName) return profileName;
    const formName = String(form.name ?? "").trim();
    if (formName) return formName;
    const sessionName = String(user?.name ?? "").trim();
    if (sessionName) return sessionName;
    return "Job Seeker";
  }, [form.name, profile?.name, user?.name]);

  useEffect(() => {
    api
      .getJobSeekerProfile()
      .then((profile) => {
        const data = profile as JobSeekerProfile;
        setProfile(data);
        setForm({
          name: String(data.name ?? ""),
          headline: String(data.headline ?? ""),
          city: String(data.city ?? ""),
          state: String(data.state ?? ""),
          district: String(data.district ?? ""),
          bio: String(data.bio ?? ""),
        });
      })
      .catch(() => setMessage("Unable to load profile"))
      .finally(() => setLoading(false));
  }, []);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    try {
      const updated = (await api.updateJobSeekerProfile(form)) as JobSeekerProfile;
      setProfile((prev) => ({ ...(prev ?? {}), ...updated, ...form }));
      setMessage("Profile updated successfully.");
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Update failed");
    }
  }

  async function onPhotoPicked(event: React.ChangeEvent<HTMLInputElement>) {
    const picked = event.target.files?.[0];
    event.currentTarget.value = "";
    if (!picked) return;
    if (!picked.type.startsWith("image/")) {
      setMessage("Please choose an image file.");
      return;
    }

    const maxBytes = 2 * 1024 * 1024;
    if (picked.size > maxBytes) {
      setMessage("Photo too large. Please select an image up to 2MB.");
      return;
    }

    try {
      setUploadingPhoto(true);
      setMessage(null);
      const buffer = await picked.arrayBuffer();
      const bytes = new Uint8Array(buffer);
      let binary = "";
      const chunk = 0x8000;
      for (let i = 0; i < bytes.length; i += chunk) {
        binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
      }
      const base64 = btoa(binary);

      const updated = (await api.updateJobSeekerProfile({ profile_photo: base64 })) as JobSeekerProfile;
      const nextPhoto = String(updated?.profile_photo_url ?? "").trim();
      setProfile((prev) => ({ ...(prev ?? {}), ...updated }));

      // Keep header user card in sync immediately after photo update.
      const token = getToken();
      if (token && user) {
        saveSession(token, { ...user, profile_photo_url: nextPhoto || user.profile_photo_url });
      }
      setMessage("Profile photo updated successfully.");
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Unable to upload profile photo");
    } finally {
      setUploadingPhoto(false);
    }
  }

  const complete = profileCompletion(profile);
  const location = [profile?.city, profile?.state, profile?.district].filter(Boolean).join(", ");
  const skills = Array.isArray(profile?.skills) ? profile?.skills : [];
  const education = Array.isArray(profile?.education) ? profile?.education : [];
  const profilePhotoUrl = (profile?.profile_photo_url || user?.profile_photo_url || "").trim();
  const initials = useMemo(() => {
    const text = displayName.trim();
    const parts = text.split(/\s+/).filter(Boolean);
    if (parts.length >= 2) return `${parts[0][0] || ""}${parts[1][0] || ""}`.toUpperCase();
    return (text.charAt(0) || "J").toUpperCase();
  }, [displayName]);

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
          <div className="rounded-2xl bg-gradient-to-r from-[var(--primary)] to-[var(--primary-dark)] p-6 text-white shadow-sm">
            <div className="mb-4 flex justify-center">
              <button
                type="button"
                onClick={() => photoInputRef.current?.click()}
                disabled={uploadingPhoto}
                className="group relative rounded-full focus:outline-none focus:ring-2 focus:ring-white/70"
                aria-label="Upload profile photo"
              >
                {profilePhotoUrl ? (
                  <img src={profilePhotoUrl} alt={displayName} className="h-24 w-24 rounded-full border-4 border-white/80 object-cover" />
                ) : (
                  <div className="flex h-24 w-24 items-center justify-center rounded-full border-4 border-white/80 bg-white/20 text-3xl font-black">
                    {initials}
                  </div>
                )}
                <span className="absolute bottom-0 right-0 rounded-full bg-white px-2 py-1 text-xs font-black text-[var(--primary)] shadow">
                  {uploadingPhoto ? "..." : "Edit"}
                </span>
              </button>
              <input ref={photoInputRef} type="file" accept="image/*" className="hidden" onChange={onPhotoPicked} />
            </div>
            <h1 className="text-2xl font-black">{displayName}</h1>
            <p className="mt-1 text-sm font-semibold text-white/85">{location || "Add your location in profile details"}</p>
            <div className="mt-4">
              <div className="mb-1 flex items-center justify-between text-xs font-bold">
                <span>Profile completeness</span>
                <span>{complete}%</span>
              </div>
              <div className="h-2 rounded-full bg-white/30">
                <div className="h-2 rounded-full bg-white" style={{ width: `${complete}%` }} />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 md:grid-cols-5">
            <a href="#edit-profile" className="rounded-2xl bg-white p-4 text-center text-sm font-extrabold shadow-sm hover:bg-slate-50">
              Edit Profile
            </a>
            <Link href="/job-seeker/resumes" className="rounded-2xl bg-white p-4 text-center text-sm font-extrabold shadow-sm hover:bg-slate-50">
              My Resume
            </Link>
            <Link href="/job-seeker/packages" className="rounded-2xl bg-white p-4 text-center text-sm font-extrabold shadow-sm hover:bg-slate-50">
              Plans &amp; Packages
            </Link>
            <Link href="/job-seeker/packages" className="rounded-2xl bg-white p-4 text-center text-sm font-extrabold shadow-sm hover:bg-slate-50">
              Purchase History
            </Link>
            <Link href="/job-seeker/settings" className="rounded-2xl bg-white p-4 text-center text-sm font-extrabold shadow-sm hover:bg-slate-50">
              Settings
            </Link>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Contact Information</h2>
            {loading ? <p className="mt-3 text-sm font-semibold text-[var(--text-hint)]">Loading profile...</p> : null}
            <div className="mt-4 grid gap-3 text-sm font-semibold md:grid-cols-2">
              <p>Email: {profile?.email || "—"}</p>
              <p>Phone: {profile?.phone || "—"}</p>
              <p className="md:col-span-2">Location: {location || "—"}</p>
            </div>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">About Me</h2>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">{profile?.bio || "Tell employers about yourself."}</p>
            <p className="mt-3 text-sm font-bold text-[var(--primary)]">{profile?.headline || "Add your professional headline."}</p>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Skills</h2>
            <div className="mt-3 flex flex-wrap gap-2">
              {skills.length ? (
                skills.map((skill) => (
                  <span key={skill} className="rounded-lg bg-[var(--accent-light)] px-3 py-1 text-xs font-extrabold text-[var(--primary)]">
                    {skill}
                  </span>
                ))
              ) : (
                <p className="text-sm font-semibold text-[var(--text-hint)]">No skills added yet.</p>
              )}
            </div>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Career Preferences</h2>
            <div className="mt-3 grid gap-2 text-sm font-semibold">
              <p>Experience: {String(profile?.experience_years ?? "").trim() || "Not set"} years</p>
              <p>
                Expected salary: {String(profile?.expected_salary_min ?? "").trim() || "—"} - {String(profile?.expected_salary_max ?? "").trim() || "—"}
              </p>
            </div>
          </div>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-extrabold">Education</h2>
            <div className="mt-3 space-y-3">
              {education.length ? (
                education.map((item, idx) => (
                  <div key={`${item.title || item.institution || "edu"}-${idx}`} className="rounded-xl border border-slate-200 p-3">
                    <p className="font-extrabold">{item.title || item.institution || "Education"}</p>
                    <p className="text-sm font-semibold text-[var(--text-hint)]">{item.institution || "—"}</p>
                    <p className="text-xs font-semibold text-[var(--text-hint)]">
                      {[item.board_or_stream, item.marks_or_grade, item.year_completed].filter(Boolean).join(" · ") || "—"}
                    </p>
                  </div>
                ))
              ) : (
                <p className="text-sm font-semibold text-[var(--text-hint)]">No education items added yet.</p>
              )}
            </div>
          </div>

          <form id="edit-profile" onSubmit={submit} className="rounded-2xl bg-white p-6 shadow-sm">
            <h2 className="text-xl font-black">Edit Profile</h2>
            <div className="mt-5 grid gap-4 md:grid-cols-2">
              {Object.entries(form).map(([key, value]) => (
                <label key={key} className={key === "bio" ? "md:col-span-2" : ""}>
                  <span className="mb-1 block text-sm font-bold capitalize">{key}</span>
                  {key === "bio" ? (
                    <textarea
                      value={value}
                      onChange={(e) => setForm((prev) => ({ ...prev, [key]: e.target.value }))}
                      className="min-h-28 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    />
                  ) : (
                    <input
                      value={value}
                      onChange={(e) => setForm((prev) => ({ ...prev, [key]: e.target.value }))}
                      className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    />
                  )}
                </label>
              ))}
            </div>
            {message ? <p className="mt-4 text-sm font-bold text-[var(--primary)]">{message}</p> : null}
            <div className="mt-5 max-w-56">
              <PrimaryButton type="submit">Save Changes</PrimaryButton>
            </div>
          </form>

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <PrimaryButton
              type="button"
              onClick={() => {
                window.location.href = "/";
              }}
            >
              Logout
            </PrimaryButton>
          </div>
        </section>
      </SiteShell>
    </Protected>
  );
}

export { JobSeekerProfilePage };
export default JobSeekerProfilePage;
