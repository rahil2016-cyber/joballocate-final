"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { BrandLogo } from "@/components/common/brand-logo";
import { PrimaryButton } from "@/components/common/primary-button";
import { api } from "@/services/api";
import { useAuth } from "@/hooks/use-auth";

type Role = "job_seeker" | "company";

function OtpLoginPage({ role }: { role: Role }) {
  const router = useRouter();
  const { login } = useAuth();
  const [isPhone, setIsPhone] = useState(true);
  const [identifier, setIdentifier] = useState("");
  const [otp, setOtp] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [mockOtp, setMockOtp] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function sendOtp(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const clean = identifier.trim();
      if (!clean) throw new Error("Please enter your contact details.");
      if (role === "job_seeker" && !isPhone && (!clean.includes("@") || !clean.includes("."))) {
        throw new Error("Please enter a valid email address.");
      }
      const result = await api.sendOtp(clean, "login", role);
      setOtpSent(true);
      setMockOtp(result.mock_otp ?? null);
      if (result.mock_otp) setOtp(result.mock_otp);
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
        identifier: identifier.trim(),
        code: otp.trim(),
        intent: "login",
        role,
      });
      login(result.token, result.user as { id?: string; name?: string; role?: string; email?: string });
      router.push(role === "job_seeker" ? "/job-seeker/home" : "/employer/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to verify OTP");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <div className="mx-auto flex w-full max-w-md flex-col gap-6 px-4 py-10">
        <BrandLogo />
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <p className="text-xs font-extrabold uppercase tracking-wide text-[var(--primary)]">
            {role === "job_seeker" ? "Job Seeker Login" : "Employer Login"}
          </p>
          <h1 className="mt-2 text-2xl font-black">Welcome Back</h1>
          <p className="mt-2 text-sm font-semibold text-[var(--text-hint)]">
            Login with OTP to continue your existing mobile app flow on web.
          </p>
          <form onSubmit={otpSent ? verifyOtp : sendOtp} className="mt-6 space-y-4">
            {role === "job_seeker" && !otpSent ? (
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
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                placeholder={
                  role === "job_seeker"
                    ? isPhone
                      ? "+91 98765 43210"
                      : "name@email.com"
                    : "company@example.com"
                }
              />
            </div>
            {otpSent ? (
              <div>
                <label className="mb-1 block text-sm font-bold">Verification Code</label>
                <input
                  required
                  value={otp}
                  onChange={(e) => setOtp(e.target.value)}
                  className="h-12 w-full rounded-xl border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[var(--primary)]"
                  placeholder="6-digit OTP"
                />
                {mockOtp ? (
                  <p className="mt-1 text-xs font-semibold text-[var(--primary)]">Dev OTP detected and prefilled: {mockOtp}</p>
                ) : null}
              </div>
            ) : null}
            {error ? <p className="text-sm font-bold text-[var(--error)]">{error}</p> : null}
            <PrimaryButton type="submit" disabled={loading}>
              {loading ? "Please wait..." : otpSent ? "Verify & Continue" : "Send Verification Code"}
            </PrimaryButton>
            {otpSent ? (
              <button
                type="button"
                onClick={() => {
                  setOtpSent(false);
                  setOtp("");
                }}
                className="w-full text-sm font-bold text-[var(--primary)] underline"
              >
                Edit contact details
              </button>
            ) : null}
          </form>
          <p className="mt-5 text-sm font-semibold text-[var(--text-hint)]">
            New here?{" "}
            <Link href="/auth/register" className="font-extrabold text-[var(--primary)] underline">
              Create account
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export { OtpLoginPage };
export default OtpLoginPage;
