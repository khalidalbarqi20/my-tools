// إزالة الخلفية داخل المتصفح (بدون سيرفر وبدون رفع الصور): Transformers.js + نموذج ormbg (Apache-2.0).
// يعمل على أندرويد وآيفون وويندوز وأي متصفح حديث. أول استخدام ينزّل النموذج (~45MB) ثم يُحفظ في كاش المتصفح.
const TJS = 'https://cdn.jsdelivr.net/npm/@huggingface/transformers@3.8.1';
const MAX_SIDE = 1024; // مقاس النموذج الأصلي؛ تصغير الصورة قبل التحليل يوفّر الذاكرة على الجوال

let segPromise = null;

async function loadSegmenter() {
  const { pipeline, env } = await import(TJS);
  env.allowLocalModels = false;
  try { env.backends.onnx.wasm.proxy = true; } catch (_) {} // تحليل بعيدًا عن واجهة التطبيق حتى لا تتجمد
  const tries = [
    ['onnx-community/ormbg-ONNX', 'q8'], // عام الأغراض (الأفضل)
    ['Xenova/modnet', 'q8'],             // احتياطي: للأشخاص
  ];
  let last;
  for (const [id, dtype] of tries) {
    try {
      return await pipeline('background-removal', id, { device: 'wasm', dtype });
    } catch (e) { last = e; }
  }
  throw last || new Error('تعذر تحميل نموذج إزالة الخلفية');
}

async function shrink(bytes) {
  const bmp = await createImageBitmap(new Blob([bytes], { type: 'image/png' }));
  const k = Math.min(1, MAX_SIDE / Math.max(bmp.width, bmp.height));
  const w = Math.max(1, Math.round(bmp.width * k));
  const h = Math.max(1, Math.round(bmp.height * k));
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  c.getContext('2d').drawImage(bmp, 0, 0, w, h);
  if (bmp.close) bmp.close();
  return await new Promise((res, rej) =>
    c.toBlob((b) => (b ? res(b) : rej(new Error('تعذر قراءة الصورة'))), 'image/png'));
}

// تُرجع { w, h, a } حيث a = Uint8Array لقناع الشفافية (0..255) بحجم w*h.
window.mtRemoveBg = async function (pngBytes) {
  if (!segPromise) {
    segPromise = loadSegmenter().catch((e) => { segPromise = null; throw e; });
  }
  const seg = await segPromise;
  const blob = await shrink(pngBytes);
  const url = URL.createObjectURL(blob);
  try {
    let out = await seg(url);
    if (Array.isArray(out)) out = out[0];
    const w = out.width, h = out.height, c = out.channels, d = out.data;
    const a = new Uint8Array(w * h);
    if (c === 4) { for (let i = 0; i < a.length; i++) a[i] = d[i * 4 + 3]; }
    else if (c === 1) { a.set(d.subarray ? d.subarray(0, a.length) : d); }
    else { for (let i = 0; i < a.length; i++) a[i] = d[i * c]; }
    return { w, h, a };
  } finally {
    URL.revokeObjectURL(url);
  }
};
