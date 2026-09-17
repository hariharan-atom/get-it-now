'use client';

import { useCallback, useEffect, useState } from 'react';
import { getSupabase } from '@/lib/supabase';

type DeliveryOrder = Record<string, unknown>;

function text(value: unknown) {
  return typeof value === 'string' || typeof value === 'number' ? String(value) : '';
}

function addressFor(order: DeliveryOrder) {
  const address = order.delivery_address ?? order.address;
  if (typeof address === 'string') return address;
  if (address && typeof address === 'object') return Object.values(address as Record<string, unknown>).filter(Boolean).join(', ');
  return [order.address_line, order.city, order.pin_code].map(text).filter(Boolean).join(', ');
}

export default function DeliveryLayout({ children }: { children: React.ReactNode }) {
  const [isPartner, setIsPartner] = useState(false);
  const [active, setActive] = useState<boolean | null>(null);
  const [orders, setOrders] = useState<DeliveryOrder[]>([]);
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    const client = getSupabase();
    const { data: { user } } = await client.auth.getUser();
    if (!user) return;

    const { data: profile } = await client
      .from('profiles')
      .select('role, is_active')
      .eq('id', user.id)
      .maybeSingle();

    const partner = profile?.role === 'delivery_partner';
    setIsPartner(partner);
    setActive(partner ? Boolean(profile?.is_active) : null);

    if (partner) {
      const { data } = await client.rpc('delivery_my_orders');
      setOrders(Array.isArray(data) ? (data as DeliveryOrder[]) : []);
    } else {
      setOrders([]);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  async function setAvailability(next: boolean) {
    setBusy(true);
    setMessage('');
    const { error } = await getSupabase().rpc('set_delivery_availability', { p_is_active: next });
    setBusy(false);
    if (error) {
      setMessage(error.message);
      return;
    }
    setActive(next);
    setMessage(next ? 'You are active and can now receive orders.' : 'You are inactive and will not receive new orders.');
  }

  async function complete(orderId: string) {
    setBusy(true);
    const { error } = await getSupabase().rpc('delivery_complete_order', { p_order_id: orderId });
    setBusy(false);
    if (error) {
      setMessage(error.message);
      return;
    }
    setMessage('Delivery marked as completed.');
    await load();
  }

  return (
    <>
      <section style={{ maxWidth: 966, margin: '20px auto 0', padding: '0 20px' }} aria-label="Delivery availability">
        {isPartner ? (
          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', padding: 16, border: '1px solid #e1dfe8', borderRadius: 16, background: '#fff' }}>
            <strong>Availability: {active ? 'Active' : 'Inactive'}</strong>
            <button className="button" disabled={busy || active === true} onClick={() => void setAvailability(true)}>Go active</button>
            <button className="button secondary" disabled={busy || active === false} onClick={() => void setAvailability(false)}>Go inactive</button>
            <button className="button secondary" disabled={busy} onClick={() => void load()}>Refresh orders</button>
          </div>
        ) : null}
        {message ? <p role="status" style={{ color: '#174d2a', fontWeight: 700 }}>{message}</p> : null}
        {isPartner && active && orders.length > 0 ? (
          <div style={{ marginTop: 16, display: 'grid', gap: 12 }}>
            {orders.map((order) => {
              const id = text(order.id);
              const address = addressFor(order);
              const phone = text(order.customer_phone ?? order.phone);
              return <article key={id} style={{ padding: 18, borderRadius: 16, background: '#174d2a', color: '#fff' }}>
                <strong>New order #{id.slice(0, 8)}</strong>
                {address ? <p>{address}</p> : null}
                <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                  {address ? <a className="button secondary" href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`} target="_blank" rel="noreferrer">Directions</a> : null}
                  {phone ? <a className="button secondary" href={`tel:${phone}`}>Call customer</a> : null}
                  <button className="button" disabled={busy} onClick={() => void complete(id)}>Mark delivered</button>
                </div>
              </article>;
            })}
          </div>
        ) : null}
      </section>
      {children}
    </>
  );
}
