import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Get It Now | Operations',
  description: 'Admin and delivery operations for Get It Now.',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
