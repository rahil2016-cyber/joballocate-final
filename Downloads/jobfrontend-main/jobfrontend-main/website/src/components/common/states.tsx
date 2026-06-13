type InfoStateProps = {
  title: string;
  detail?: string;
};

export function LoadingState({ title, detail }: InfoStateProps) {
  return (
    <div className="rounded-2xl bg-white p-6 shadow-sm" role="status" aria-live="polite">
      <p className="text-sm font-extrabold text-[var(--primary)]">{title}</p>
      {detail ? <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">{detail}</p> : null}
    </div>
  );
}

export function ErrorState({ title, detail }: InfoStateProps) {
  return (
    <div className="rounded-2xl bg-white p-6 shadow-sm" role="alert" aria-live="assertive">
      <p className="text-sm font-extrabold text-[var(--error)]">{title}</p>
      {detail ? <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">{detail}</p> : null}
    </div>
  );
}

export function EmptyState({ title, detail }: InfoStateProps) {
  return (
    <div className="rounded-2xl bg-white p-6 shadow-sm">
      <p className="text-sm font-extrabold text-[var(--text-hint)]">{title}</p>
      {detail ? <p className="mt-1 text-sm font-semibold text-[var(--text-hint)]">{detail}</p> : null}
    </div>
  );
}
