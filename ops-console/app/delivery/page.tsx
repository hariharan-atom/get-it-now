
'use client';

import Link from 'next/link';
import { FormEvent, useCallback, useEffect, useState } from 'react';
import { addressLine, mapsLink, money, orderDate } from '@/lib/format';
import { getSupabase } from '@/lib/supabase';
import type { Order, Profile } from '@/lib/types';

const fail = (value: unknown) => value instanceof Error ? value.message : 'Something went wrong. Please try again.';

export default function DeliveryPage() {
  const [mode, setMode] = useState<'signIn' | 'signUp'>('signIn');
  const [name, setName] = useState(''); const [email, setEmail] = useState(''); const [password, setPassword] = useState('');
  const [profile, setProfile] = useState<Profile | null>(null); const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true); const [working, setWorking] = useState(false); const [error, setError] = useState(''); const [notice, setNotice] = useState('');

  const load = useCallback(async () => {
    try {
      const sb = getSupabase(); const { data, error: sessionError } = await sb.auth.getSession(); if (sessionError) throw sessionError;
      const user = data.session?.user; if (!user) { setProfile(null); return; }
      const result = await sb.from('profiles').select('*').eq('id', user.id).maybeSingle(); if (result.error) throw result.error;
      const next = result.data as Profile | null; setProfile(next);
      if (next?.role === 'delivery_partner' && next.is_active) {
        const orderResult = await sb.from('orders').select('*, order_items(*)').eq('delivery_partner_id', user.id).order('created_at', { ascending: false });
        if (orderResult.error) throw orderResult.error; setOrders((orderResult.data ?? []) as Order[]);
      } else setOrders([]);
    } catch (caught) { setError(fail(caught)); } finally { setLoading(false); }
  }, []);
  useEffect(() => { void load(); }, [load]);
  const act = async (work: () => Promise<void>) => { setWorking(true); setError(''); setNotice(''); try { await work(); await load(); } catch (caught) { setError(fail(caught)); } finally { setWorking(false); } };

  async function authenticate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await act(async () => {
      const sb = getSupabase();
      if (mode === 'signIn') {
        const { error } = await sb.auth.signInWithPassword({ email, password }); if (error) throw error;
      } else {
        const { error } = await sb.auth.signUp({ email, password, options: { data: { display_name: name.trim() } } }); if (error) throw error;
        setNotice('Account created. Activate delivery below to become available for assignments.');
      }
    });
  }
  const activate = async () => await act(async () => { const { error } = await getSupabase().rpc('activate_delivery_partner'); if (error) throw error; setNotice('You are active and can now receive orders.'); });
  const deliver = async (id: string) => await act(async () => { const { error } = await getSupabase().rpc('mark_order_delivered', { p_order_id: id }); if (error) throw error; setNotice('Order marked delivered. Nice work!'); });
  const signOut = async () => { await getSupabase().auth.signOut(); setProfile(null); setOrders([]); };

  if (loading) return <main className="auth-page"><div className="auth-card"><div className="skeleton" aria-label="Loading delivery workspace" /></div></main>;
  if (!profile) return <main className="auth-page"><section className="auth-card" aria-labelledby="rider-auth"><Link className="brand-lockup" href="/"><span className="brand-mark" aria-hidden="true">G</span><strong>GET IT NOW</strong></Link><p className="eyebrow">DELIVERY PARTNER</p><h1 id="rider-auth">{mode === 'signIn' ? 'Ready for your next delivery?' : 'Join the delivery team.'}</h1><p className="lede">Use your email and password. No OTP is required when the Supabase auto-confirm migration is enabled.</p><form className="form-stack" onSubmit={authenticate}>{mode === 'signUp' && <div className="field"><label htmlFor="name">Full name</label><input id="name" autoComplete="name" value={name} onChange={e => setName(e.target.value)} required /></div>}<div className="field"><label htmlFor="email">Email</label><input id="email" type="email" autoComplete="email" value={email} onChange={e => setEmail(e.target.value)} required /></div><div className="field"><label htmlFor="password">Password</label><input id="password" type="password" autoComplete={mode === 'signIn' ? 'current-password' : 'new-password'} minLength={8} value={password} onChange={e => setPassword(e.target.value)} required /></div><button className="button primary" disabled={working}>{working ? 'Please wait…' : mode === 'signIn' ? 'Sign in' : 'Create account'}</button></form>{error && <p className="message error" role="alert">{error}</p>}<p className="auth-switch">{mode === 'signIn' ? 'New delivery partner?' : 'Already have an account?'} <button className="link-button" onClick={() => setMode(mode === 'signIn' ? 'signUp' : 'signIn')}>{mode === 'signIn' ? 'Create account' : 'Sign in'}</button></p><p className="auth-switch"><Link href="/admin">Store admin panel</Link></p></section></main>;

  const active = profile.role === 'delivery_partner' && profile.is_active;
  return <main className="rider-shell"><header className="rider-header"><Link className="brand-lockup" href="/"><span className="brand-mark" aria-hidden="true">G</span><strong>GET IT NOW</strong></Link><button className="button ghost small" onClick={() => void signOut()}>Sign out</button></header>
    <section className="rider-intro"><p className="eyebrow">DELIVERY WORKSPACE</p><h2>{active ? 'You are active.' : 'Go active to receive orders.'}</h2><p>{active ? 'Assigned orders show below. Open directions, call the customer, then confirm delivery.' : 'Once active, your name appears in the admin assignment list.'}</p>{!active && <button className="button primary" style={{ marginTop: 18 }} onClick={() => void activate()} disabled={working}>{working ? 'Activating…' : 'Activate delivery account'}</button>}</section>
    {(error || notice) && <p className={'message ' + (error ? 'error' : 'success')} role={error ? 'alert' : 'status'}>{error || notice}</p>}
    {active && <section aria-labelledby="assigned-orders"><div className="section-heading"><div><h1 id="assigned-orders">Your deliveries</h1><p>{orders.filter(item => item.status === 'out_for_delivery').length} out for delivery</p></div><button className="button secondary small" onClick={() => void load()} disabled={working}>Refresh</button></div>{orders.length === 0 && <div className="empty">No assigned orders yet. Keep this page open and refresh when the admin assigns one.</div>}{orders.map(order => <article className="rider-card" key={order.id}><div className="order-card-header"><div><h3>Order #{order.id.slice(0, 8)}</h3><p className="muted">{orderDate(order.created_at)} · Cash on delivery</p></div><span className={'pill ' + order.status}>{order.status.replaceAll('_', ' ')}</span></div><p className="delivery-total">{money(order.total_paise)}</p><ul className="items">{(order.order_items || []).map(item => <li key={item.id}>{item.quantity} × {item.name} · {item.unit}</li>)}</ul><div className="address"><strong>{order.address?.name || 'Customer'}</strong><p>{addressLine(order.address || {})}</p><p>{order.address?.phone || 'No phone number'}</p></div><div className="action-row"><a className="button secondary" href={mapsLink(order.address || {})} target="_blank" rel="noreferrer">Open directions</a>{order.address?.phone && <a className="button secondary" href={'tel:' + order.address.phone}>Call customer</a>}{order.status === 'out_for_delivery' && <button className="button primary" onClick={() => void deliver(order.id)} disabled={working}>{working ? 'Updating…' : 'Mark delivered'}</button>}</div></article>)}</section>}
  </main>;
}

