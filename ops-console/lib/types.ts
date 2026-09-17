export type Profile = {
  id: string;
  full_name: string;
  role: 'customer' | 'admin' | 'delivery_partner';
  is_active: boolean;
  created_at: string;
};

export type Product = {
  id: string;
  name: string;
  category: string;
  unit: string;
  price_paise: number;
  original_price_paise: number;
  image: string;
  badge: string;
  stock: number;
  active: boolean;
  sort_order: number;
};

export type OrderItem = {
  id: number;
  name: string;
  unit: string;
  quantity: number;
  price_paise: number;
};

export type DeliveryAddress = {
  name?: string;
  phone?: string;
  line1?: string;
  city?: string;
  pincode?: string;
};

export type Order = {
  id: string;
  customer_id: string;
  delivery_partner_id: string | null;
  assigned_at: string | null;
  delivered_at: string | null;
  address: DeliveryAddress;
  subtotal_paise: number;
  delivery_fee_paise: number;
  total_paise: number;
  status: 'placed' | 'preparing' | 'out_for_delivery' | 'delivered' | 'cancelled';
  created_at: string;
  order_items: OrderItem[];
};
