import { getToken } from "@/services/auth-storage";
import { env } from "@/config/env";

type ApiEnvelope<T> = {
  success: boolean;
  message?: string;
  data: T;
  meta?: {
    current_page?: number;
    last_page?: number;
    per_page?: number;
    total?: number;
  };
  errors?: Record<string, string[]>;
};

function normalizeArray<T>(value: unknown, preferredKeys: string[] = []): T[] {
  if (Array.isArray(value)) return value as T[];
  if (!value || typeof value !== "object") return [];

  const record = value as Record<string, unknown>;
  for (const key of preferredKeys) {
    const candidate = record[key];
    if (Array.isArray(candidate)) return candidate as T[];
  }

  for (const candidate of Object.values(record)) {
    if (Array.isArray(candidate)) return candidate as T[];
  }

  return [];
}

let resolvedBasePrefix: string | null = null;

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, "");
}

function candidateApiBases(): string[] {
  const origin = trimTrailingSlash(env.apiOrigin);
  return [`${origin}${env.apiPrefix}`, origin];
}

function buildUrl(base: string, path: string): string {
  return `${trimTrailingSlash(base)}${path}`;
}

async function parseEnvelope<T>(response: Response): Promise<ApiEnvelope<T>> {
  try {
    return (await response.json()) as ApiEnvelope<T>;
  } catch {
    return {
      success: false,
      message: `Unexpected response (${response.status})`,
      data: null as T,
    };
  }
}

async function fetchWithBase<T>(base: string, path: string, init: RequestInit): Promise<T> {
  const response = await fetch(buildUrl(base, path), init);
  const payload = await parseEnvelope<T>(response);
  if (!response.ok || payload.success === false) {
    throw new Error(payload.message ?? "Request failed");
  }
  return payload.data;
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  const hasBody = init.body !== undefined && init.body !== null;
  const isFormData = typeof FormData !== "undefined" && init.body instanceof FormData;
  if (hasBody && !isFormData) headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);

  const requestInit: RequestInit = {
    ...init,
    headers,
  };

  if (resolvedBasePrefix) {
    return fetchWithBase<T>(resolvedBasePrefix, path, requestInit);
  }

  const candidates = candidateApiBases();
  let lastError: Error | null = null;

  for (const base of candidates) {
    try {
      const data = await fetchWithBase<T>(base, path, requestInit);
      resolvedBasePrefix = base;
      return data;
    } catch (error) {
      lastError = error instanceof Error ? error : new Error("Request failed");
    }
  }

  throw lastError ?? new Error("Request failed");
}

export const api = {
  sendOtp(identifier: string, intent: "login" | "register", role: "job_seeker" | "company") {
    return request<{ mock_otp?: string }>("/auth/send-otp", {
      method: "POST",
      body: JSON.stringify({ identifier, intent, role }),
    });
  },
  verifyOtp(payload: {
    identifier: string;
    code: string;
    intent: "login" | "register";
    role: "job_seeker" | "company";
    name?: string;
    company_name?: string;
    state?: string;
    district?: string;
    city?: string;
    gst_number?: string;
  }) {
    return request<{ token: string; user: Record<string, unknown> }>("/auth/verify-otp", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  me() {
    return request<Record<string, unknown>>("/me");
  },
  listJobs(params?: {
    search?: string;
    location?: string;
    industry_type?: string;
    company_id?: number | string;
    published_after?: string;
    from_top_companies?: boolean;
    page?: number;
    per_page?: number;
  }) {
    const query = new URLSearchParams();
    if (params?.search) query.set("search", params.search);
    if (params?.location) query.set("location", params.location);
    if (params?.industry_type) query.set("industry_type", params.industry_type);
    if (params?.company_id !== undefined) query.set("company_id", String(params.company_id));
    if (params?.published_after) query.set("published_after", params.published_after);
    if (params?.from_top_companies) query.set("from_top_companies", "1");
    if (params?.page) query.set("page", String(params.page));
    if (params?.per_page) query.set("per_page", String(params.per_page));
    return request<unknown>(`/jobs${query.size ? `?${query}` : ""}`).then((data) => normalizeArray<unknown>(data, ["jobs", "items", "rows"]));
  },
  reportSeekerActivityTime(payload: { seconds: number }) {
    return request<Record<string, unknown>>("/job-seeker/activity/time", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  uploadJobSeekerResumePdf(file: File) {
    const formData = new FormData();
    formData.append("resume", file);
    return request<Record<string, unknown>>("/job-seeker/profile/resume", {
      method: "POST",
      body: formData,
    });
  },
  listTopCompanies() {
    return request<unknown>("/companies/top").then((data) => normalizeArray<unknown>(data, ["companies", "items", "rows"]));
  },
  getJob(jobId: string) {
    return request<Record<string, unknown>>(`/jobs/${jobId}`);
  },
  getJobSeekerProfile() {
    return request<Record<string, unknown>>("/job-seeker/profile");
  },
  updateJobSeekerProfile(payload: Record<string, unknown>) {
    return request<Record<string, unknown>>("/job-seeker/profile", {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },
  listMyApplications() {
    return request<unknown>("/job-seeker/applications").then((data) => normalizeArray<unknown>(data, ["applications", "items", "rows"]));
  },
  getApplication(applicationId: string) {
    return request<unknown>("/job-seeker/applications").then((data) => {
      const rows = normalizeArray<Record<string, unknown>>(data, ["applications", "items", "rows"]);
      return rows.find((item) => String(item.id) === applicationId) ?? null;
    });
  },
  applyToJob(jobId: string, payload: Record<string, unknown> = {}) {
    return request<Record<string, unknown>>(`/job-seeker/jobs/${jobId}/apply`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  withdrawApplication(applicationId: string) {
    return request<Record<string, unknown>>(`/job-seeker/applications/${applicationId}`, {
      method: "DELETE",
    });
  },
  listSavedJobs() {
    return request<unknown>("/job-seeker/saved-jobs").then((data) => normalizeArray<unknown>(data, ["jobs", "saved_jobs", "items", "rows"]));
  },
  listRecommendedJobs() {
    return request<unknown>("/job-seeker/recommended-jobs").then((data) => normalizeArray<unknown>(data, ["jobs", "items", "rows"]));
  },
  listRelatedJobs() {
    return request<unknown>("/job-seeker/related-jobs").then((data) => normalizeArray<unknown>(data, ["jobs", "items", "rows"]));
  },
  saveJob(jobId: string) {
    return request<Record<string, unknown>>(`/job-seeker/jobs/${jobId}/save`, { method: "POST" });
  },
  unsaveJob(jobId: string) {
    return request<Record<string, unknown>>(`/job-seeker/jobs/${jobId}/save`, { method: "DELETE" });
  },
  getCompanyProfile() {
    return request<Record<string, unknown>>("/company/profile");
  },
  updateCompanyProfile(payload: Record<string, unknown>) {
    return request<Record<string, unknown>>("/company/profile", {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },
  companyJobPosts() {
    return request<unknown>("/company/job-posts").then((data) => normalizeArray<unknown>(data, ["jobs", "posts", "items", "rows"]));
  },
  createJobPost(payload: Record<string, unknown>) {
    return request<Record<string, unknown>>("/company/job-posts", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  updateJobPost(jobId: string, payload: Record<string, unknown>) {
    return request<Record<string, unknown>>(`/company/job-posts/${jobId}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },
  companyApplications(jobId: string) {
    return request<unknown>(`/company/job-posts/${jobId}/applications`).then((data) => normalizeArray<unknown>(data, ["applications", "items", "rows"]));
  },
  companyUpdateApplicationStatus(jobId: string, applicationId: string, payload: { status: string; employer_note?: string }) {
    return request<Record<string, unknown>>(`/company/job-posts/${jobId}/applications/${applicationId}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });
  },
  companyPurchaseSubscription(payload: { coupon_code?: string }) {
    return request<Record<string, unknown>>("/company/subscription/purchase", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  companySubscriptionOffer() {
    return request<Record<string, unknown>>("/company/subscription/offer");
  },
  companySubscriptionHistory() {
    return request<unknown>("/company/subscription/history").then((data) => normalizeArray<unknown>(data, ["history", "subscriptions", "items", "rows"]));
  },
  listBanners(forAudience?: "job_seeker" | "employer") {
    const query = new URLSearchParams();
    if (forAudience) query.set("for", forAudience);
    return request<unknown>(`/banners${query.size ? `?${query.toString()}` : ""}`).then((data) =>
      normalizeArray<unknown>(data, ["banners", "items", "rows"]),
    );
  },
  listStates() {
    return request<unknown>("/locations/states").then((data) => normalizeArray<string>(data, ["states", "items", "rows"]));
  },
  listDistricts(state: string) {
    const query = new URLSearchParams({ state });
    return request<unknown>(`/locations/districts?${query.toString()}`).then((data) => normalizeArray<string>(data, ["districts", "items", "rows"]));
  },
  seekerPackageCatalog() {
    return request<unknown>("/job-seeker/packages/catalog").then((data) => normalizeArray<unknown>(data, ["packages", "items", "rows"]));
  },
  seekerPackagePurchases() {
    return request<unknown>("/job-seeker/packages/purchases").then((data) => normalizeArray<unknown>(data, ["purchases", "items", "rows"]));
  },
  seekerPackagePurchasesPaged(params?: { page?: number; per_page?: number }) {
    const query = new URLSearchParams();
    if (params?.page) query.set("page", String(params.page));
    if (params?.per_page) query.set("per_page", String(params.per_page));
    return request<Record<string, unknown>>(`/job-seeker/packages/purchases${query.size ? `?${query}` : ""}`);
  },
  seekerSelectPackage(payload: { package_key: string }) {
    return request<Record<string, unknown>>("/job-seeker/packages/select", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  careerContents(type?: string) {
    const query = new URLSearchParams();
    if (type) query.set("type", type);
    return request<unknown>(`/job-seeker/career/contents${query.size ? `?${query}` : ""}`).then((data) =>
      normalizeArray<unknown>(data, ["contents", "items", "rows"]),
    );
  },
  careerContentsRaw(type?: string) {
    const query = new URLSearchParams();
    if (type) query.set("type", type);
    return request<Record<string, unknown>>(`/job-seeker/career/contents${query.size ? `?${query}` : ""}`);
  },
  markCareerContentHelpful(careerContentId: string, payload: { is_helpful: boolean }) {
    return request<Record<string, unknown>>(`/job-seeker/career/contents/${careerContentId}/helpful`, {
      method: "POST",
      body: JSON.stringify({ helpful: payload.is_helpful }),
    });
  },
  resumeDrafts() {
    return request<unknown>("/job-seeker/resume/drafts").then((data) => normalizeArray<unknown>(data, ["drafts", "items", "rows"]));
  },
  resumeDraftById(resumeDraftId: number | string) {
    return request<unknown>("/job-seeker/resume/drafts").then((data) => {
      const rows = normalizeArray<Record<string, unknown>>(data, ["drafts", "items", "rows"]);
      return rows.find((item) => Number(item.id) === Number(resumeDraftId)) ?? null;
    });
  },
  saveResumeDraft(payload: { title: string; template_id: string; content: Record<string, unknown> }) {
    return request<Record<string, unknown>>("/job-seeker/resume/save", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  setPrimaryResume(payload: { resume_draft_id: number }) {
    return request<Record<string, unknown>>("/job-seeker/resume/primary", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  resumeAiAssist(payload: {
    section_name: string;
    current_text?: string;
    instruction?: string;
    job_context?: string;
  }) {
    return request<Record<string, unknown>>("/job-seeker/resume/ai-assist", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  resumePdfPurchase(payload: { resume_template_id: number; resume_template_title: string }) {
    return request<Record<string, unknown>>("/job-seeker/resume/pdf-purchase", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  resumeOneOffPurchase() {
    return request<Record<string, unknown>>("/job-seeker/resume/one-off-purchase", {
      method: "POST",
    });
  },
  careerCoach(payload: { kind: "career_path" | "interview_prep"; focus?: string }) {
    return request<Record<string, unknown>>("/job-seeker/career/ai-coach", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  seekerFeedbackHistory() {
    return request<unknown>("/job-seeker/feedback").then((data) => normalizeArray<unknown>(data, ["feedback", "items", "rows"]));
  },
  submitSeekerFeedback(payload: { rating: number; message?: string }) {
    return request<Record<string, unknown>>("/job-seeker/feedback", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
};
