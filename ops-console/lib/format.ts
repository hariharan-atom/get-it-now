import type { DeliveryAddress } from './types';

export const money = (paise: number) =>
  new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(paise / 100);

export const orderDate = (value: string) =>
  new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value));

export const addressLine = (address: DeliveryAddress) =>
  [address.line1, address.city, address.pincode].filter(Boolean).join(', ');

export const mapsLink = (address: DeliveryAddress) =>
  `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(addressLine(address))}`;
