type BrandProps = { small?: boolean };

export function Brand({ small = false }: BrandProps) {
  return (
    <span className={`brand-lockup${small ? ' brand-small' : ''}`}>
      <span className="brand-mark" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m13 2-10 12h9l-1 8 10-12h-9z" /></svg></span>
      <span className="brand-name">GET IT<br />NOW</span>
    </span>
  );
}
