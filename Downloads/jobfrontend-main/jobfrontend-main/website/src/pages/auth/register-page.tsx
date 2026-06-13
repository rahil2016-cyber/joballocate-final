"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useEffect, useMemo, useState } from "react";
import { BrandLogo } from "@/components/common/brand-logo";
import { PrimaryButton } from "@/components/common/primary-button";
import { useAuth } from "@/hooks/use-auth";
import { api } from "@/services/api";

type RegisterRole = "job_seeker" | "company" | "consultancy";

function RegisterPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [role, setRole] = useState<RegisterRole>("job_seeker");
  const [step, setStep] = useState<"details" | "otp">("details");
  const [isPhone, setIsPhone] = useState(true);

  const [name, setName] = useState("");
  const [contact, setContact] = useState("");
  const [companyName, setCompanyName] = useState("");
  const [gstNumber, setGstNumber] = useState("");
  const [city, setCity] = useState("");
  const [state, setState] = useState("");
  const [district, setDistrict] = useState("");
  const [states, setStates] = useState<string[]>([]);
  const [districts, setDistricts] = useState<string[]>([]);
  const [mockOtp, setMockOtp] = useState<string | null>(null);
  const [otp, setOtp] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const apiRole = role === "job_seeker" ? "job_seeker" : "company";

  useEffect(() => {
    api
      .listStates()
      .then((rows) => setStates(rows))
      .catch(() => setStates([]));
  }, []);

  async function handleStateChange(nextState: string) {
    setState(nextState);
    setDistrict("");
    if (!nextState) {
      setDistricts([]);
      return;
    }
    try {
      const rows = await api.listDistricts(nextState);
      setDistricts(rows);
    } catch {
      setDistricts([]);
    }
  }

  const canSubmitDetails = useMemo(() => {
    if (!name.trim()) return false;
    if (!contact.trim()) return false;
    if (!state || !district) return false;
    if (role !== "job_seeker" && !companyName.trim()) return false;
    return true;
  }, [contact, district, name, role, state, companyName]);

  async function sendOtp(e: FormEvent) {
    e.preventDefault();
    if (!canSubmitDetails) return;
    setLoading(true);
    setError(null);
    try {
      if (role === "job_seeker" && !isPhone && (!contact.includes("@") || !contact.includes("."))) {
        throw new Error("Please enter a valid email for job seeker registration.");
      }
      const result = await api.sendOtp(contact.trim(), "register", apiRole);
      setMockOtp(result.mock_otp ?? null);
      if (result.mock_otp) setOtp(result.mock_otp);
      setStep("otp");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to send OTP");
    } finally {
      setLoading(false);
    }
  }

  async function verifyOtp(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const result = await api.verifyOtp({
        identifier: contact.trim(),
        code: otp.trim(),
        intent: "register",
        role: apiRole,
        name: name.trim(),
        company_name: role !== "job_seeker" ? companyName.trim() : undefined,
        gst_number: gstNumber.trim() || undefined,
        state,
        district,
        city: city.trim() || undefined,
      });
      login(result.token, result.user as { id?: string; name?: string; role?: string; email?: string });
      router.push(apiRole === "job_seeker" ? "/job-seeker/home" : "/employer/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to verify OTP");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <div className="mx-auto flex w-full max-w-lg flex-col gap-6 px-4 py-10">
        <BrandLogo />
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h1 className="text-2xl font-black">Create account</h1>
          <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
            Register with OTP using the same flow as your mobile app.
          </p>
          <div className="mt-4 grid grid-cols-3 gap-2 rounded-xl bg-[var(--accent-light)] p-1">
            <button
              onClick={() => setRole("job_seeker")}
              className={`rounded-lg px-3 py-2 text-sm font-extrabold ${role === "job_seeker" ? "bg-white text-[var(--primary)]" : ""}`}
            >
              Job Seeker
            </button>
            <button
              onClick={() => setRole("company")}
              className={`rounded-lg px-3 py-2 text-sm font-extrabold ${role === "company" ? "bg-white text-[var(--primary)]" : ""}`}
            >
              Company
            </button>
            <button
              onClick={() => setRole("consultancy")}
              className={`rounded-lg px-3 py-2 text-sm font-extrabold ${role === "consultancy" ? "bg-white text-[var(--primary)]" : ""}`}
            >
              Consultancy
            </button>
          </div>

          <form onSubmit={step === "otp" ? verifyOtp : sendOtp} className="mt-5 space-y-4">
            {step === "details" ? (
              <>
                <div>
                  <label className="mb-1 block text-sm font-bold">Full Name</label>
                  <input
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    placeholder="Your full name"
                  />
                </div>
                {role !== "job_seeker" ? (
                  <div>
                    <label className="mb-1 block text-sm font-bold">
                      {role === "consultancy" ? "Consultancy Name" : "Company Name"}
                    </label>
                    <input
                      required
                      value={companyName}
                      onChange={(e) => setCompanyName(e.target.value)}
                      className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                      placeholder="Registered business name"
                    />
                  </div>
                ) : null}

                {role === "job_seeker" ? (
                  <div className="grid grid-cols-2 gap-2 rounded-xl bg-[var(--accent-light)] p-1">
                    <button
                      type="button"
                      onClick={() => setIsPhone(true)}
                      className={`rounded-lg px-3 py-2 text-sm font-bold ${isPhone ? "bg-white text-[var(--primary)]" : ""}`}
                    >
                      Phone
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsPhone(false)}
                      className={`rounded-lg px-3 py-2 text-sm font-bold ${!isPhone ? "bg-white text-[var(--primary)]" : ""}`}
                    >
                      Email
                    </button>
                  </div>
                ) : null}

                <div>
                  <label className="mb-1 block text-sm font-bold">
                    {role === "job_seeker" ? (isPhone ? "Phone Number" : "Email Address") : "Business Email"}
                  </label>
                  <input
                    required
                    value={contact}
                    onChange={(e) => setContact(e.target.value)}
                    className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    placeholder={role === "job_seeker" ? (isPhone ? "+91 98765 43210" : "name@email.com") : "hr@company.com"}
                  />
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <div>
                    <label className="mb-1 block text-sm font-bold">State</label>
                    <select
                      value={state}
                      onChange={(e) => handleStateChange(e.target.value)}
                      className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    >
                      <option value="">Select state</option>
                      {states.map((item) => (
                        <option key={item} value={item}>
                          {item}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-bold">District</label>
                    <select
                      value={district}
                      onChange={(e) => setDistrict(e.target.value)}
                      className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                    >
                      <option value="">Select district</option>
                      {districts.map((item) => (
                        <option key={item} value={item}>
                          {item}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <div>
                    <label className="mb-1 block text-sm font-bold">City (optional)</label>
                    <input
                      value={city}
                      onChange={(e) => setCity(e.target.value)}
                      className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                      placeholder="Writeable city"
                    />
                  </div>
                  {role !== "job_seeker" ? (
                    <div>
                      <label className="mb-1 block text-sm font-bold">GST Number (optional)</label>
                      <input
                        value={gstNumber}
                        onChange={(e) => setGstNumber(e.target.value)}
                        className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                        placeholder="GST number"
                      />
                    </div>
                  ) : null}
                </div>
              </>
            ) : (
              <div>
                <label className="mb-1 block text-sm font-bold">OTP</label>
                <input
                  required
                  value={otp}
                  onChange={(e) => setOtp(e.target.value)}
                  className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  placeholder="6-digit code"
                />
                {mockOtp ? (
                  <p className="mt-1 text-xs font-semibold text-[var(--primary)]">Dev OTP detected and prefilled: {mockOtp}</p>
                ) : null}
              </div>
            )}
            {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
            <PrimaryButton disabled={loading || (step === "details" && !canSubmitDetails)} type="submit">
              {loading ? "Please wait..." : step === "otp" ? "Verify & Create Account" : "Send Verification Code"}
            </PrimaryButton>
            {step === "otp" ? (
              <button
                type="button"
                onClick={() => setStep("details")}
                className="w-full text-sm font-bold text-[var(--primary)] underline"
              >
                Edit details
              </button>
            ) : null}
          </form>
          <p className="mt-5 text-sm font-semibold text-[var(--text-hint)]">
            Already registered?{" "}
            <Link href={role === "job_seeker" ? "/auth/login/job-seeker" : "/auth/login/employer"} className="font-extrabold text-[var(--primary)] underline">
              Login here
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export { RegisterPage };
export default RegisterPage;
