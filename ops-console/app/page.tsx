import Link from 'next/link';

export default function Home() {
  return (
    <main className="portal-page">
      <section className="portal-card" aria-labelledby="portal-title">
        <div className="brand-lockup"><span className="brand-mark" aria-hidden="true">G</span><strong>GET IT NOW</strong></div>
        <p className="eyebrow">OPERATIONS PORTAL</p>
        <h1 id="portal-title">Run the store. Deliver with confidence.</h1>
        <p className="lede">A single secure workspace for inventory, fulfilment, delivery assignment, and partner delivery.</p>
        <div className="portal-actions">
          <Link className="button primary" href="/admin">Open admin panel</Link>
          <Link className="button secondary" href="/delivery">Open delivery panel</Link>
        </div>
      </section>
    </main>
  );
}
