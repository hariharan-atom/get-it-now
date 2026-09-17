'use client';

import { useEffect, useState } from 'react';
import { getSupabase } from '@/lib/supabase';

async function compress(file: File) {
  const source = await createImageBitmap(file);
  const scale = Math.min(1, 1200 / Math.max(source.width, source.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(source.width * scale));
  canvas.height = Math.max(1, Math.round(source.height * scale));
  canvas.getContext('2d')?.drawImage(source, 0, 0, canvas.width, canvas.height);
  source.close();
  for (const quality of [.82, .68, .54, .4]) {
    const blob = await new Promise<Blob | null>(resolve => canvas.toBlob(resolve, 'image/webp', quality));
    if (blob && blob.size <= 200 * 1024) return blob;
  }
  throw new Error('Choose a smaller image; this one cannot be compressed below 200 KB.');
}

function ProductImageUpload() {
  const [message, setMessage] = useState('');
  useEffect(() => {
    const urlField = document.getElementById('image') as HTMLInputElement | null;
    if (!urlField || document.getElementById('product-image-upload')) return;
    const picker = document.createElement('input');
    picker.id = 'product-image-upload'; picker.type = 'file'; picker.accept = 'image/jpeg,image/png,image/webp'; picker.hidden = true;
    const button = document.createElement('button');
    button.type = 'button'; button.className = 'button secondary small'; button.textContent = 'Upload & compress image (max 200 KB)';
    button.addEventListener('click', () => picker.click());
    picker.addEventListener('change', async () => {
      const file = picker.files?.[0]; if (!file) return;
      button.disabled = true; setMessage('Compressing image…');
      try {
        const image = await compress(file);
        const path = `${crypto.randomUUID()}.webp`;
        const { error } = await getSupabase().storage.from('product-images').upload(path, image, { contentType: 'image/webp' });
        if (error) throw error;
        const { data } = getSupabase().storage.from('product-images').getPublicUrl(path);
        Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(urlField, data.publicUrl);
        urlField.dispatchEvent(new Event('input', { bubbles: true }));
        setMessage('Uploaded and compressed below 200 KB.');
      } catch (caught) { setMessage(caught instanceof Error ? caught.message : 'Image upload failed.'); }
      finally { button.disabled = false; picker.value = ''; }
    });
    urlField.insertAdjacentElement('afterend', picker); urlField.insertAdjacentElement('afterend', button);
    return () => { button.remove(); picker.remove(); };
  }, []);
  return message ? <p className="form-help" role="status">{message}</p> : null;
}

export default function AdminTemplate({ children }: { children: React.ReactNode }) {
  return <><ProductImageUpload />{children}</>;
}
