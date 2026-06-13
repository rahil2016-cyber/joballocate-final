"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { api } from "@/services/api";

type BannerItem = {
  id: string | number;
  title?: string;
  content?: string;
  below_line?: string;
  target_url?: string;
  background_color?: string;
  image_url?: string;
};

function isHttpUrl(value?: string) {
  if (!value) return false;
  return /^https?:\/\//i.test(value.trim());
}

export function RoleBanners({ audience }: { audience: "job_seeker" | "employer" }) {
  const [banners, setBanners] = useState<BannerItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    api
      .listBanners(audience)
      .then((rows) => {
        if (!active) return;
        setBanners((rows as BannerItem[]) ?? []);
      })
      .catch(() => {
        if (!active) return;
        setBanners([]);
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [audience]);

  if (loading) {
    return <p className="text-xs font-bold text-[var(--text-hint)]">Loading banners...</p>;
  }

  if (!banners.length) {
    return null;
  }

  return (
    <section className="space-y-3">
      {banners.map((banner) => {
        const href = isHttpUrl(banner.target_url) ? banner.target_url : undefined;
        return (
          <article
            key={String(banner.id)}
            className="overflow-hidden rounded-2xl p-4 text-white shadow-sm"
            style={{
              background: banner.background_color || "linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)",
            }}
          >
            <p className="text-lg font-black">{banner.title || "Featured update"}</p>
            {banner.content ? <p className="mt-1 text-sm font-semibold opacity-95">{banner.content}</p> : null}
            {banner.image_url ? (
              href ? (
                <a href={href} target="_blank" rel="noopener noreferrer" className="mt-3 block overflow-hidden rounded-xl border border-white/20 bg-white/10">
                  <Image
                    src={banner.image_url}
                    alt={banner.title || "Banner"}
                    width={1200}
                    height={560}
                    className="h-[180px] w-full object-cover md:h-[260px]"
                  />
                </a>
              ) : (
                <div className="mt-3 overflow-hidden rounded-xl border border-white/20 bg-white/10">
                  <Image
                    src={banner.image_url}
                    alt={banner.title || "Banner"}
                    width={1200}
                    height={560}
                    className="h-[180px] w-full object-cover md:h-[260px]"
                  />
                </div>
              )
            ) : null}
            {banner.below_line ? <p className="mt-2 text-sm font-bold opacity-95">{banner.below_line}</p> : null}
          </article>
        );
      })}
    </section>
  );
}
