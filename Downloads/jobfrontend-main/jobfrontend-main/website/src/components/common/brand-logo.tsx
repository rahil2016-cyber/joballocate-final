import Link from "next/link";
import Image from "next/image";

export function BrandLogo({ withTagline = true }: { withTagline?: boolean }) {
  return (
    <Link href="/" className="inline-flex items-center gap-3">
      <Image src="/api/logo" alt="Job Allocate" width={200} height={56} priority className="h-10 w-auto object-contain md:h-12" />
      <div>
        <p className="text-lg font-extrabold tracking-tight">JOB ALLOCATE</p>
        {withTagline ? (
          <p className="text-xs font-semibold text-[var(--text-hint)]">RIGHT JOB RIGHT CANDIDATE</p>
        ) : null}
      </div>
    </Link>
  );
}
