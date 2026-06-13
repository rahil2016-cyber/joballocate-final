import { BrandLogo } from "@/components/common/brand-logo";

function AboutPage() {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      <div className="mx-auto w-full max-w-4xl px-4 py-10">
        <BrandLogo />
        <section className="mt-6 rounded-2xl bg-white p-6 shadow-sm">
          <h1 className="text-2xl font-black">About JobAllocate</h1>
          <p className="mt-3 text-sm font-semibold leading-6 text-[var(--text-hint)]">
            JobAllocate connects job seekers and employers with OTP-first authentication, reliable backend APIs,
            and role-focused dashboards. This website version preserves your app branding, colors, and navigation
            flow while adapting layouts for desktop, tablet, and mobile.
          </p>
        </section>
      </div>
    </div>
  );
}

export { AboutPage };
export default AboutPage;
