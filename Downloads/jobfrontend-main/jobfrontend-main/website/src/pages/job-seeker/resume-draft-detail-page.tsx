"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Protected } from "@/components/common/protected";
import { PrimaryButton } from "@/components/common/primary-button";
import { SiteShell } from "@/components/layout/site-shell";
import { api } from "@/services/api";

type ResumeDraft = {
  id: number;
  title?: string;
  template_id?: string;
  content?: Record<string, unknown>;
};

type ExperienceRow = { years: string; company: string; position: string; points: string[] };
type EducationRow = { years: string; degree: string; school: string };
type CertificationRow = { title: string; org: string };
type ProjectRow = { title: string; date: string; description: string };
type PairRow = { key: string; value: string };

export default function ResumeDraftDetailPage({ draftId }: { draftId: string }) {
  const photoInputId = "resume-photo-upload";
  const router = useRouter();
  const [draft, setDraft] = useState<ResumeDraft | null>(null);
  const [latestDraftId, setLatestDraftId] = useState<string>(draftId);
  const [title, setTitle] = useState("");
  const [templateId, setTemplateId] = useState("22");
  const [name, setName] = useState("Mohammed Rahil B");
  const [role, setRole] = useState("Full Stack Developer | AI/ML Enthusiast");
  const [phone, setPhone] = useState("+91-8431463400");
  const [email, setEmail] = useState("rahil2016ok@gmail.com");
  const [linkedin, setLinkedin] = useState("https://www.linkedin.com/in/rahil");
  const [address, setAddress] = useState("Davangere, Karnataka");
  const [summary, setSummary] = useState("I am a passionate tech enthusiast skilled in AI, ML, and full-stack development.");
  const [skillsText, setSkillsText] = useState("DSA\nFrontend Design\nBackend\nDeployment");
  const [languagesText, setLanguagesText] = useState("English");
  const [personalStatusText, setPersonalStatusText] = useState("Current Location|Davangere\nDate of Birth|July 23, 2003");
  const [educationText, setEducationText] = useState("2021|B.Tech in AI & ML|BIET Davangere");
  const [experienceText, setExperienceText] = useState("Sep 2024 - Feb 2026|Thinkzeal|Full Stack Developer|Created 20+ websites;Built full-stack apps");
  const [internshipsText, setInternshipsText] = useState("Null Classes|Apr 2025 - Oct 2025|I have worked on many realtime projects");
  const [projectsText, setProjectsText] = useState("JobAllocate|Feb 2026 - Mar 2026|Job portal where candidates apply and companies post jobs.");
  const [certificationsText, setCertificationsText] = useState("Data Analyst and Job Simulation|Forage");
  const [publicationsText, setPublicationsText] = useState("The Future of Cybersecurity in Industrial IOT|UPREMS");
  const [photoUrl, setPhotoUrl] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    api
      .resumeDraftById(draftId)
      .then((row) => {
        if (!mounted) return;
        const data = row as ResumeDraft | null;
        setDraft(data);
        setTitle(String(data?.title ?? ""));
        setTemplateId(String(data?.template_id ?? "22"));
        const content = data?.content;
        const sectionRows = Array.isArray(content?.sections) ? (content?.sections as Array<Record<string, unknown>>) : [];
        const byId = (id: string) => {
          const match = sectionRows.find((r) => String(r.id || "") === id);
          return String(match?.body ?? "");
        };
        setName(byId("name") || String(content?.name ?? name));
        setRole(byId("role") || String(content?.role ?? role));
        setPhone(byId("phone") || String(content?.phone ?? phone));
        setEmail(byId("email") || String(content?.email ?? email));
        setLinkedin(byId("linkedin") || String(content?.linkedin ?? linkedin));
        setAddress(byId("address") || String(content?.address ?? address));
        setSummary(byId("summary") || String(content?.summary ?? summary));
        setSkillsText(byId("skills") || String(content?.skills ?? skillsText));
        setLanguagesText(byId("languages") || String(content?.languages ?? languagesText));
        setPersonalStatusText(byId("personal_status") || String(content?.personal_status ?? personalStatusText));
        setEducationText(byId("education") || String(content?.education ?? educationText));
        setExperienceText(byId("experience") || String(content?.experience ?? experienceText));
        setInternshipsText(byId("internships") || String(content?.internships ?? internshipsText));
        setProjectsText(byId("projects") || String(content?.projects ?? projectsText));
        setCertificationsText(byId("certifications") || String(content?.certifications ?? certificationsText));
        setPublicationsText(byId("publications") || String(content?.publications ?? publicationsText));
        setPhotoUrl(byId("profile_photo_url") || String(content?.profile_photo_url ?? ""));
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err instanceof Error ? err.message : "Unable to load resume draft");
      });
    return () => {
      mounted = false;
    };
  }, [draftId]);

  const skills = skillsText.split("\n").map((x) => x.trim()).filter(Boolean);
  const languages = languagesText.split("\n").map((x) => x.trim()).filter(Boolean);
  const personalStatus: PairRow[] = personalStatusText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [k = "", v = ""] = line.split("|");
      return { key: k.trim(), value: v.trim() };
    });
  const educationRows: EducationRow[] = educationText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [years = "", degree = "", school = ""] = line.split("|");
      return { years: years.trim(), degree: degree.trim(), school: school.trim() };
    });
  const experiences: ExperienceRow[] = experienceText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [years = "", company = "", position = "", points = ""] = line.split("|");
      return { years: years.trim(), company: company.trim(), position: position.trim(), points: points.split(";").map((p) => p.trim()).filter(Boolean) };
    });
  const projects: ProjectRow[] = projectsText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [title = "", date = "", description = ""] = line.split("|");
      return { title: title.trim(), date: date.trim(), description: description.trim() };
    });
  const certifications: CertificationRow[] = certificationsText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [title = "", org = ""] = line.split("|");
      return { title: title.trim(), org: org.trim() };
    });
  const internships: ProjectRow[] = internshipsText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [title = "", date = "", description = ""] = line.split("|");
      return { title: title.trim(), date: date.trim(), description: description.trim() };
    });
  const publications = publicationsText
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean)
    .map((line) => {
      const [title = "", publisher = ""] = line.split("|");
      return { title: title.trim(), publisher: publisher.trim() };
    });
  const isNimraTemplate = templateId.trim() === "23";

  function writeEducationRows(next: EducationRow[]) {
    setEducationText(next.map((r) => `${r.years}|${r.degree}|${r.school}`).join("\n"));
  }
  function writeInternships(next: ProjectRow[]) {
    setInternshipsText(next.map((r) => `${r.title}|${r.date}|${r.description}`).join("\n"));
  }
  function writeProjects(next: ProjectRow[]) {
    setProjectsText(next.map((r) => `${r.title}|${r.date}|${r.description}`).join("\n"));
  }
  function writeExperiences(next: ExperienceRow[]) {
    setExperienceText(next.map((r) => `${r.years}|${r.company}|${r.position}|${r.points.join(";")}`).join("\n"));
  }

  function updateEducationRow(index: number, patch: Partial<EducationRow>) {
    const next = educationRows.map((r, i) => (i === index ? { ...r, ...patch } : r));
    writeEducationRows(next);
  }
  function addEducationRow() {
    writeEducationRows([...educationRows, { years: "", degree: "", school: "" }]);
  }
  function removeEducationRow(index: number) {
    writeEducationRows(educationRows.filter((_, i) => i !== index));
  }

  function updateInternshipRow(index: number, patch: Partial<ProjectRow>) {
    const next = internships.map((r, i) => (i === index ? { ...r, ...patch } : r));
    writeInternships(next);
  }
  function addInternshipRow() {
    writeInternships([...internships, { title: "", date: "", description: "" }]);
  }
  function removeInternshipRow(index: number) {
    writeInternships(internships.filter((_, i) => i !== index));
  }

  function updateProjectRow(index: number, patch: Partial<ProjectRow>) {
    const next = projects.map((r, i) => (i === index ? { ...r, ...patch } : r));
    writeProjects(next);
  }
  function addProjectRow() {
    writeProjects([...projects, { title: "", date: "", description: "" }]);
  }
  function removeProjectRow(index: number) {
    writeProjects(projects.filter((_, i) => i !== index));
  }

  function updateExperienceRow(index: number, patch: Partial<ExperienceRow>) {
    const next = experiences.map((r, i) => (i === index ? { ...r, ...patch } : r));
    writeExperiences(next);
  }
  function addExperienceRow() {
    writeExperiences([...experiences, { years: "", company: "", position: "", points: [] }]);
  }
  function removeExperienceRow(index: number) {
    writeExperiences(experiences.filter((_, i) => i !== index));
  }

  function onPhotoPick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.onload = () => setPhotoUrl(typeof reader.result === "string" ? reader.result : "");
    reader.readAsDataURL(file);
  }

  function clearPhoto() {
    setPhotoUrl("");
    const el = document.getElementById(photoInputId) as HTMLInputElement | null;
    if (el) el.value = "";
  }

  async function saveAsNewVersion(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    setError(null);
    try {
      const saved = (await api.saveResumeDraft({
        title: title.trim(),
        template_id: templateId.trim(),
        content: {
          format: "sections_v2",
          sections: [
            { id: "name", title: "Name", body: name },
            { id: "role", title: "Role", body: role },
            { id: "phone", title: "Phone", body: phone },
            { id: "email", title: "Email", body: email },
            { id: "linkedin", title: "LinkedIn", body: linkedin },
            { id: "address", title: "Address", body: address },
            { id: "summary", title: "Summary", body: summary },
            { id: "skills", title: "Skills", body: skillsText },
            { id: "languages", title: "Languages", body: languagesText },
            { id: "personal_status", title: "Personal Status", body: personalStatusText },
            { id: "education", title: "Education", body: educationText },
            { id: "experience", title: "Experience", body: experienceText },
            { id: "internships", title: "Internships", body: internshipsText },
            { id: "projects", title: "Projects", body: projectsText },
            { id: "certifications", title: "Certifications", body: certificationsText },
            { id: "publications", title: "Publications", body: publicationsText },
            { id: "profile_photo_url", title: "Profile Photo", body: photoUrl },
          ],
        },
      })) as Record<string, unknown>;
      const nextId = Number(saved.id ?? saved.resume_draft_id ?? 0);
      if (nextId > 0) {
        setLatestDraftId(String(nextId));
        router.replace(`/job-seeker/resumes/${nextId}`);
      }
      setMessage("Saved. Download now will use this updated template.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to save draft");
    }
  }

  function esc(v: string) {
    return v.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
  }

  function downloadCurrentResume() {
    const w = window.open("", "_blank", "width=1100,height=1400");
    if (!w) return;
    const isNimraTemplate = templateId.trim() === "23";
    if (isNimraTemplate) {
      const contactLine = [email, phone, address].filter(Boolean).join("   •   ");
      const nimraHtml = `
      <div class="resume">
        <header class="head">
          <h1>${esc(name)}</h1>
          <p class="sub"><a href="${esc(linkedin)}">${esc(linkedin)}</a></p>
          <p class="sub">${esc(contactLine)}</p>
        </header>
        <section><h2>Summary</h2><p>${esc(summary)}</p></section>
        <section><h2>Skills</h2><div class="skills-grid"><div>${skills.slice(0, Math.ceil(skills.length / 2)).map((s) => `<p>• ${esc(s)}</p>`).join("")}</div><div>${skills.slice(Math.ceil(skills.length / 2)).map((s) => `<p>• ${esc(s)}</p>`).join("")}</div></div></section>
        <section><h2>Education</h2>${educationRows.map((e) => `<div class="row"><div><h3>${esc(e.degree)}</h3><p>${esc(e.school)}</p></div><p class="meta">${esc(e.years)}</p></div>`).join("")}</section>
        <section><h2>Projects</h2>${projects.map((p) => `<div class="item"><h3>${esc(p.title)}</h3><p class="meta">${esc(p.date)}</p><p>• ${esc(p.description)}</p></div>`).join("")}</section>
        <section><h2>Certifications</h2>${certifications.map((c) => `<div class="item"><h3>${esc(c.title)}</h3>${c.org ? `<p>• ${esc(c.org)}</p>` : ""}</div>`).join("")}</section>
        <section><h2>Publications</h2>${publications.map((p) => `<div class="item"><h3>${esc(p.title)}</h3>${p.publisher ? `<p>• [${esc(p.publisher)}]</p>` : ""}</div>`).join("")}</section>
        <section><h2>Internships</h2>${internships.map((i) => `<div class="item"><h3>${esc(i.title)}</h3><p class="meta">${esc(i.date)}</p><p>• ${esc(i.description)}</p></div>`).join("")}</section>
        <section><h2>Work Experience</h2>${experiences.map((e) => `<div class="item"><h3>${esc(e.company)}</h3><p class="meta">${esc(e.years)}</p><p>• ${esc(e.position)}</p>${e.points.map((pt) => `<p>• ${esc(pt)}</p>`).join("")}</div>`).join("")}</section>
      </div>`;
      w.document.open();
      w.document.write(`<!doctype html><html><head><meta charset="utf-8" /><title>Resume</title><style>
        *{margin:0;padding:0;box-sizing:border-box;font-family:"Times New Roman",Georgia,serif;color:#111;}
        @page{size:A4;margin:10mm;}
        body{-webkit-print-color-adjust:exact !important;print-color-adjust:exact !important;background:#fff;}
        .resume{width:190mm;margin:0 auto;background:#fff;padding:2mm 4mm;}
        .head{text-align:center;border-bottom:1px solid #111;padding-bottom:6px;margin-bottom:8px;}
        .head h1{font-size:48px;font-weight:700;line-height:1.05;}
        .sub{margin-top:2px;font-size:13px;}
        .sub a{color:#2b6cb0;text-decoration:none;}
        section{margin-bottom:8px;}
        h2{font-size:38px;font-weight:700;border-bottom:1px solid #111;padding-bottom:2px;margin-bottom:4px;}
        p{font-size:13px;line-height:1.22;}
        .skills-grid{display:grid;grid-template-columns:1fr 1fr;gap:6px;}
        .row{display:flex;justify-content:space-between;gap:12px;margin-bottom:5px;}
        h3{font-size:14px;font-weight:700;line-height:1.2;}
        .meta{font-size:12px;white-space:nowrap;}
        .item{margin-bottom:5px;}
      </style></head><body>${nimraHtml}</body></html>`);
      w.document.close();
      w.addEventListener("load", () => setTimeout(() => {
        w.focus();
        w.print();
      }, 300));
      w.onafterprint = () => w.close();
      return;
    }
    const resumeHtml = `
      <div class="resume">
        <div class="left">
          <div class="photo-wrap">${photoUrl ? `<img class="photo" src="${esc(photoUrl)}" alt="Profile" />` : `<div class="photo-placeholder">${esc((name || "U")[0] || "U")}</div>`}</div>
          <div class="section contact"><h2>Get In Touch</h2><p>${esc(phone)}</p><p>${esc(email)}</p><p>${esc(address)}</p></div>
          <div class="section"><h2>Skills</h2><div class="skills">${skills.map((s) => `<span class="skill">${esc(s)}</span>`).join("")}</div></div>
          <div class="section"><h2>Languages Known</h2><ul>${languages.map((l) => `<li>${esc(l)}</li>`).join("")}</ul></div>
          <div class="section"><h2>Certifications</h2><ul>${certifications.map((c) => `<li>${esc(c.title)}</li>`).join("")}</ul></div>
        </div>
        <div class="right">
          <div class="header"><h1>${esc(name)}</h1><p class="role">${esc(role)}</p></div>
          <div class="section"><h2>Resume Summary</h2><p class="summary">${esc(summary)}</p></div>
          <div class="section"><h2>Personal Details</h2><div class="status-grid">${personalStatus
            .map((row) => `<div class="status-item"><strong>${esc(row.key)}</strong><span>${esc(row.value)}</span></div>`)
            .join("")}</div></div>
          <div class="section"><h2>Education</h2>${educationRows.map((e) => `<div class="item"><h3>${esc(e.degree)}</h3><p>${esc(e.school)}</p><p class="date">${esc(e.years)}</p></div>`).join("")}</div>
          <div class="section"><h2>Internships</h2>${internships.map((i) => `<div class="item"><h3>${esc(i.title)}</h3><p class="date">${esc(i.date)}</p><p>${esc(i.description)}</p></div>`).join("")}</div>
          <div class="section"><h2>Work Experience</h2>${experiences.map((e) => `<div class="item"><h3>${esc(e.company)} — ${esc(e.position)}</h3><p class="date">${esc(e.years)}</p><ul>${e.points.map((p) => `<li>${esc(p)}</li>`).join("")}</ul></div>`).join("")}</div>
          <div class="section"><h2>Projects</h2>${projects.map((p) => `<div class="item"><h3>${esc(p.title)}</h3><p class="date">${esc(p.date)}</p><p>${esc(p.description)}</p></div>`).join("")}</div>
        </div>
      </div>
    `;
    w.document.open();
    w.document.write(`<!doctype html><html><head><meta charset="utf-8" /><title>Resume</title><style>
      *{margin:0;padding:0;box-sizing:border-box;font-family:Calibri,Arial,sans-serif;}
      @page{size:A4;margin:0;}
      html,body{width:210mm;min-height:297mm;}
      body{
        background:#fff;
        padding:0;
        -webkit-print-color-adjust:exact !important;
        print-color-adjust:exact !important;
      }
      .resume{
        width:210mm;
        min-height:297mm;
        margin:0 auto;
        background:#fff;
        display:grid;
        grid-template-columns:30% 70%;
      }
      .left{background:#fff;color:#111;padding:16px 14px 14px 16px;border-right:1px solid #d5d5d5;}
      .right{padding:16px 16px 14px 16px;}
      .photo-wrap{display:flex;justify-content:flex-start;margin-bottom:8px;}
      .photo{width:98px;height:98px;border-radius:50%;object-fit:cover;border:4px solid #e5e7eb;}
      .photo-placeholder{width:98px;height:98px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:#e5e7eb;color:#334155;font-size:32px;font-weight:800;}
      h1{font-size:16px;margin:0;color:#18b8cb;font-weight:800;letter-spacing:.2px}
      .header{margin:0 0 8px 0}
      .role{font-size:10px;color:#111;margin-top:3px}
      .section{margin-bottom:8px}
      .section h2{font-size:10px;margin-bottom:4px;border-top:1px solid #111;padding-top:4px;text-transform:uppercase;font-weight:800;letter-spacing:.2px}
      .right .section h2{font-size:11px;margin-bottom:4px;border-top:none;border-bottom:1px solid #00b8ff;padding-top:0;padding-bottom:3px;text-transform:uppercase;letter-spacing:.1px}
      .summary{line-height:1.35;color:#111;font-size:10px}
      .contact p{margin-bottom:2px;font-size:10px}
      .skills{display:flex;flex-wrap:wrap;gap:2px 4px}
      .skill{background:transparent;padding:0;border-radius:0;color:#0f172a;font-size:10px;display:block;width:100%}
      .skill::before{content:"- ";color:#111}
      ul{padding-left:14px}
      li{margin-bottom:1px;line-height:1.25;font-size:10px}
      .item{margin-bottom:5px}
      .item h3{font-size:11px}
      .date{color:#6b7280;font-size:9px;margin:1px 0}
      .status-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:4px 16px}
      .status-item{display:flex;flex-direction:column;font-size:10px;color:#111}
      .status-item strong{font-weight:700}
      .right .item h3{color:#0aaec3;font-weight:800;letter-spacing:.1px}
      .right .date{color:#10aec4;font-weight:700}
      @media print{
        html,body{margin:0 !important;padding:0 !important;}
        .resume{break-inside:avoid;page-break-inside:avoid;}
      }
    </style></head><body>${resumeHtml}</body></html>`);
    w.document.close();
    const triggerPrint = () => {
      w.focus();
      w.print();
    };
    w.addEventListener("load", () => {
      setTimeout(triggerPrint, 300);
    });
    w.onafterprint = () => {
      w.close();
    };
  }

  return (
    <Protected role="job_seeker">
      <SiteShell
        navItems={[
          { label: "Home", href: "/job-seeker/home" },
          { label: "Dashboard", href: "/job-seeker/dashboard" },
          { label: "Applications", href: "/job-seeker/applications" },
          { label: "Saved", href: "/job-seeker/saved" },
          { label: "Profile", href: "/job-seeker/profile" },
        ]}
      >
        <section className="space-y-4">
          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <h1 className="text-2xl font-black">Resume Draft Detail</h1>
            <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">Edit and save this draft as a new version.</p>
          </div>
          {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
          {message ? <p className="text-sm font-bold text-[var(--primary)]">{message}</p> : null}
          {draft ? (
            <form onSubmit={saveAsNewVersion} className="rounded-2xl bg-white p-6 shadow-sm">
              <div className="grid gap-6 lg:grid-cols-2">
                <div className="space-y-3">
                  <input value={title} onChange={(e) => setTitle(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Resume title" />
                  <input value={templateId} onChange={(e) => setTemplateId(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Template ID" />
                  <input value={name} onChange={(e) => setName(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Name" />
                  <input value={role} onChange={(e) => setRole(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Role" />
                  <textarea value={summary} onChange={(e) => setSummary(e.target.value)} className="min-h-20 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold" placeholder="Summary" />
                  <input value={phone} onChange={(e) => setPhone(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Phone" />
                  <input value={email} onChange={(e) => setEmail(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Email" />
                  <input value={linkedin} onChange={(e) => setLinkedin(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="LinkedIn" />
                  <input value={address} onChange={(e) => setAddress(e.target.value)} className="h-11 w-full rounded-lg border border-slate-200 px-3 text-sm font-semibold" placeholder="Location" />
                  <div className="rounded-lg border border-slate-200 p-3">
                    <p className="text-xs font-extrabold text-slate-700">Upload Photo</p>
                    <p className="mt-1 text-[11px] font-semibold text-slate-500">Used in left profile circle for preview and download.</p>
                    <div className="mt-2 flex items-center gap-2">
                      <label
                        htmlFor={photoInputId}
                        className="cursor-pointer rounded-md bg-[#16213e] px-3 py-2 text-xs font-extrabold text-white"
                      >
                        Choose Image
                      </label>
                      {photoUrl ? (
                        <button
                          type="button"
                          onClick={clearPhoto}
                          className="rounded-md border border-slate-300 px-3 py-2 text-xs font-extrabold text-slate-700"
                        >
                          Remove
                        </button>
                      ) : null}
                    </div>
                    <input id={photoInputId} type="file" accept="image/*" onChange={onPhotoPick} className="hidden" />
                    <p className="mt-2 text-[11px] font-semibold text-slate-600">
                      {photoUrl ? "Photo selected" : "No photo selected"}
                    </p>
                  </div>
                  <textarea value={skillsText} onChange={(e) => setSkillsText(e.target.value)} className="min-h-16 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold" placeholder="Skills (one per line)" />
                  <textarea value={languagesText} onChange={(e) => setLanguagesText(e.target.value)} className="min-h-12 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold" placeholder="Languages (one per line)" />
                  <textarea value={personalStatusText} onChange={(e) => setPersonalStatusText(e.target.value)} className="min-h-16 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold" placeholder="Personal status lines: label|value" />
                  <div className="rounded-lg border border-slate-200 p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-extrabold text-slate-700">Education</p>
                      <button type="button" onClick={addEducationRow} className="rounded-md bg-slate-900 px-2 py-1 text-[11px] font-extrabold text-white">Add Education</button>
                    </div>
                    <div className="space-y-2">
                      {educationRows.map((row, idx) => (
                        <div key={idx} className="rounded-md border border-slate-200 p-2">
                          <div className="grid gap-2">
                            <input value={row.years} onChange={(e) => updateEducationRow(idx, { years: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Year / Duration" />
                            <input value={row.degree} onChange={(e) => updateEducationRow(idx, { degree: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Degree / Course" />
                            <input value={row.school} onChange={(e) => updateEducationRow(idx, { school: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Institute / School" />
                            <button type="button" onClick={() => removeEducationRow(idx)} className="rounded border border-red-200 px-2 py-1 text-[11px] font-extrabold text-red-600">Remove</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="rounded-lg border border-slate-200 p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-extrabold text-slate-700">Work Experience</p>
                      <button type="button" onClick={addExperienceRow} className="rounded-md bg-slate-900 px-2 py-1 text-[11px] font-extrabold text-white">Add Experience</button>
                    </div>
                    <div className="space-y-2">
                      {experiences.map((row, idx) => (
                        <div key={idx} className="rounded-md border border-slate-200 p-2">
                          <div className="grid gap-2">
                            <input value={row.company} onChange={(e) => updateExperienceRow(idx, { company: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Company" />
                            <input value={row.position} onChange={(e) => updateExperienceRow(idx, { position: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Role / Position" />
                            <input value={row.years} onChange={(e) => updateExperienceRow(idx, { years: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Duration (e.g. Sep 2024 - Feb 2026)" />
                            <textarea
                              value={row.points.join("\n")}
                              onChange={(e) => updateExperienceRow(idx, { points: e.target.value.split("\n").map((x) => x.trim()).filter(Boolean) })}
                              className="min-h-16 w-full rounded border border-slate-200 px-2 py-1 text-xs font-semibold"
                              placeholder="Points (one per line)"
                            />
                            <button type="button" onClick={() => removeExperienceRow(idx)} className="rounded border border-red-200 px-2 py-1 text-[11px] font-extrabold text-red-600">Remove</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="rounded-lg border border-slate-200 p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-extrabold text-slate-700">Internships</p>
                      <button type="button" onClick={addInternshipRow} className="rounded-md bg-slate-900 px-2 py-1 text-[11px] font-extrabold text-white">Add Internship</button>
                    </div>
                    <div className="space-y-2">
                      {internships.map((row, idx) => (
                        <div key={idx} className="rounded-md border border-slate-200 p-2">
                          <div className="grid gap-2">
                            <input value={row.title} onChange={(e) => updateInternshipRow(idx, { title: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Internship Title / Company" />
                            <input value={row.date} onChange={(e) => updateInternshipRow(idx, { date: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Duration" />
                            <textarea value={row.description} onChange={(e) => updateInternshipRow(idx, { description: e.target.value })} className="min-h-14 w-full rounded border border-slate-200 px-2 py-1 text-xs font-semibold" placeholder="Description" />
                            <button type="button" onClick={() => removeInternshipRow(idx)} className="rounded border border-red-200 px-2 py-1 text-[11px] font-extrabold text-red-600">Remove</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="rounded-lg border border-slate-200 p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-extrabold text-slate-700">Projects</p>
                      <button type="button" onClick={addProjectRow} className="rounded-md bg-slate-900 px-2 py-1 text-[11px] font-extrabold text-white">Add Project</button>
                    </div>
                    <div className="space-y-2">
                      {projects.map((row, idx) => (
                        <div key={idx} className="rounded-md border border-slate-200 p-2">
                          <div className="grid gap-2">
                            <input value={row.title} onChange={(e) => updateProjectRow(idx, { title: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Project Title" />
                            <input value={row.date} onChange={(e) => updateProjectRow(idx, { date: e.target.value })} className="h-9 w-full rounded border border-slate-200 px-2 text-xs font-semibold" placeholder="Duration" />
                            <textarea value={row.description} onChange={(e) => updateProjectRow(idx, { description: e.target.value })} className="min-h-14 w-full rounded border border-slate-200 px-2 py-1 text-xs font-semibold" placeholder="Description" />
                            <button type="button" onClick={() => removeProjectRow(idx)} className="rounded border border-red-200 px-2 py-1 text-[11px] font-extrabold text-red-600">Remove</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                  <textarea value={certificationsText} onChange={(e) => setCertificationsText(e.target.value)} className="min-h-16 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold" placeholder="Certifications lines: title|org" />
                  <textarea value={publicationsText} onChange={(e) => setPublicationsText(e.target.value)} className="min-h-16 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold" placeholder="Publications lines: title|publisher" />
                </div>
                <div className="print-resume rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                  {isNimraTemplate ? (
                    <div className="mx-auto min-h-[760px] w-full max-w-[780px] border border-slate-200 bg-white p-5 font-['Times_New_Roman',Georgia,serif] text-slate-900">
                      <header className="border-b border-black pb-2 text-center">
                        <h1 className="text-5xl font-bold">{name}</h1>
                        <p className="mt-1 text-xs text-blue-700">{linkedin}</p>
                        <p className="mt-1 text-xs">{[email, phone, address].filter(Boolean).join("   •   ")}</p>
                      </header>
                      <section className="mt-2">
                        <h2 className="border-b border-black text-[34px] font-bold">Summary</h2>
                        <p className="mt-1 text-xs leading-5">{summary}</p>
                      </section>
                      <section className="mt-2">
                        <h2 className="border-b border-black text-[34px] font-bold">Skills</h2>
                        <div className="mt-1 grid grid-cols-2 gap-x-4">
                          <div>{skills.slice(0, Math.ceil(skills.length / 2)).map((s, i) => <p key={i} className="text-xs">• {s}</p>)}</div>
                          <div>{skills.slice(Math.ceil(skills.length / 2)).map((s, i) => <p key={i} className="text-xs">• {s}</p>)}</div>
                        </div>
                      </section>
                      <section className="mt-2">
                        <h2 className="border-b border-black text-[34px] font-bold">Education</h2>
                        <div className="space-y-1 pt-1">
                          {educationRows.map((e, i) => (
                            <div key={i} className="flex justify-between gap-3 text-xs">
                              <div><p className="font-bold">{e.degree}</p><p>{e.school}</p></div>
                              <p className="whitespace-nowrap">{e.years}</p>
                            </div>
                          ))}
                        </div>
                      </section>
                      <section className="mt-2"><h2 className="border-b border-black text-[34px] font-bold">Projects</h2>{projects.map((p, i) => <div key={i} className="pt-1 text-xs"><p className="font-bold">{p.title} <span className="font-semibold text-slate-700">| {p.date}</span></p><p>• {p.description}</p></div>)}</section>
                      <section className="mt-2"><h2 className="border-b border-black text-[34px] font-bold">Certifications</h2>{certifications.map((c, i) => <div key={i} className="pt-1 text-xs"><p className="font-bold">{c.title}</p>{c.org ? <p>• {c.org}</p> : null}</div>)}</section>
                      <section className="mt-2"><h2 className="border-b border-black text-[34px] font-bold">Publications</h2>{publications.map((p, i) => <div key={i} className="pt-1 text-xs"><p className="font-bold">{p.title}</p>{p.publisher ? <p>• [{p.publisher}]</p> : null}</div>)}</section>
                      <section className="mt-2"><h2 className="border-b border-black text-[34px] font-bold">Internships</h2>{internships.map((r, i) => <div key={i} className="pt-1 text-xs"><p className="font-bold">{r.title} <span className="font-semibold text-slate-700">| {r.date}</span></p><p>• {r.description}</p></div>)}</section>
                      <section className="mt-2"><h2 className="border-b border-black text-[34px] font-bold">Work Experience</h2>{experiences.map((e, i) => <div key={i} className="pt-1 text-xs"><p className="font-bold">{e.company} <span className="font-semibold text-slate-700">| {e.years}</span></p><p>• {e.position}</p>{e.points.map((pt, j) => <p key={j}>• {pt}</p>)}</div>)}</section>
                    </div>
                  ) : (
                    <div className="grid min-h-[760px] grid-cols-[30%_70%] border border-slate-300 font-[Calibri,Arial,sans-serif]">
                      <aside className="border-r border-slate-300 bg-white p-4 text-slate-900">
                        <div className="mb-2 flex justify-start">
                          {photoUrl ? (
                            <img src={photoUrl} alt={name} className="h-24 w-24 rounded-full border-4 border-slate-200 object-cover" />
                          ) : (
                            <div className="flex h-24 w-24 items-center justify-center rounded-full bg-slate-200 text-2xl font-extrabold text-slate-600">
                              {(name || "U")[0]}
                            </div>
                          )}
                        </div>
                        <section className="mt-3">
                          <h2 className="border-t border-black pt-1 text-[11px] font-extrabold uppercase tracking-wide">Get In Touch</h2>
                          <p className="mt-1 text-[10px]">{phone}</p>
                          <p className="text-[10px]">{email}</p>
                          <p className="text-[10px]">{address}</p>
                        </section>
                        <section className="mt-3">
                          <h2 className="border-t border-black pt-1 text-[11px] font-extrabold uppercase tracking-wide">Skills</h2>
                          <div className="mt-1 space-y-0.5">
                            {skills.map((s, i) => <p key={i} className="text-[10px]">- {s}</p>)}
                          </div>
                        </section>
                        <section className="mt-3">
                          <h2 className="border-t border-black pt-1 text-[11px] font-extrabold uppercase tracking-wide">Languages Known</h2>
                          <p className="mt-1 text-[10px]">{languages.join(" | ") || "-"}</p>
                        </section>
                        <section className="mt-3">
                          <h2 className="border-t border-black pt-1 text-[11px] font-extrabold uppercase tracking-wide">Certifications</h2>
                          <div className="mt-1 space-y-0.5">
                            {certifications.map((c, i) => <p key={i} className="text-[10px]">- {c.title}</p>)}
                          </div>
                        </section>
                      </aside>
                      <main className="p-4">
                        <div className="mb-2">
                          <h1 className="text-[16px] font-extrabold leading-none tracking-[0.2px] text-cyan-500">{name}</h1>
                          <p className="mt-1 text-[10px]">{role}</p>
                        </div>
                        <section className="mb-3"><h2 className="border-b border-cyan-400 pb-1 text-[11px] font-extrabold uppercase">Resume Summary</h2><p className="mt-1 text-[10px] leading-5">{summary}</p></section>
                        <section className="mb-4">
                          <h2 className="border-b border-cyan-400 pb-1 text-[11px] font-extrabold uppercase">Personal Details</h2>
                          <div className="mt-1 grid grid-cols-2 gap-x-5 gap-y-1">
                            {personalStatus.map((row, idx) => (
                              <div key={`${row.key}-${idx}`} className="text-[10px]">
                                <p className="font-bold text-slate-700">{row.key}</p>
                                <p className="text-slate-600">{row.value}</p>
                              </div>
                            ))}
                          </div>
                        </section>
                        <section className="mb-3"><h2 className="border-b border-cyan-400 pb-1 text-[11px] font-extrabold uppercase">Education</h2>{educationRows.map((e, i) => <div key={i} className="mt-1 text-[10px]"><p className="font-extrabold text-cyan-500">{e.degree}</p><p>{e.school}</p><p className="font-bold text-cyan-500">{e.years}</p></div>)}</section>
                        <section className="mb-3"><h2 className="border-b border-cyan-400 pb-1 text-[11px] font-extrabold uppercase">Internships</h2>{internships.map((i, idx) => <div key={idx} className="mt-1 text-[10px]"><p className="font-extrabold text-cyan-500">{i.title}</p><p className="font-bold text-cyan-500">{i.date}</p><p>- {i.description}</p></div>)}</section>
                        <section className="mb-3"><h2 className="border-b border-cyan-400 pb-1 text-[11px] font-extrabold uppercase">Projects</h2>{projects.map((p, i) => <div key={i} className="mt-1 text-[10px]"><p className="font-extrabold text-cyan-500">{p.title}</p><p className="font-bold text-cyan-500">{p.date}</p><p>- {p.description}</p></div>)}</section>
                        <section className="mb-3"><h2 className="border-b border-cyan-400 pb-1 text-[11px] font-extrabold uppercase">Work Experience</h2>{experiences.map((e, i) => <div key={i} className="mt-1 text-[10px]"><p className="font-extrabold text-cyan-500">{e.company}</p><p className="font-bold text-cyan-500">{e.years}</p><p>- {e.position}</p><p>{e.points.join(" | ")}</p></div>)}</section>
                      </main>
                    </div>
                  )}
                </div>
              </div>
              <div className="mt-5 flex items-center gap-3">
                <PrimaryButton type="submit">Save as New Draft</PrimaryButton>
                <button type="button" onClick={downloadCurrentResume} className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-extrabold">Download Current Resume (PDF)</button>
                <Link href={`/job-seeker/resumes/${latestDraftId}/preview`} className="text-sm font-extrabold text-[var(--primary)] underline">Open preview / Print PDF</Link>
              </div>
            </form>
          ) : (
            <div className="rounded-2xl bg-white p-6 text-sm font-semibold text-[var(--text-hint)] shadow-sm">Draft not found.</div>
          )}
        </section>
      </SiteShell>
    </Protected>
  );
}
