// محرك الفيديو والصوت على الويب (يعمل داخل المتصفح بدون رفع الملفات).
// الأولوية لـ Mediabunny (WebCodecs: سريع وبذاكرة قليلة)، وإن لم يدعم الصيغة أو فشل نرجع تلقائيًا لـ ffmpeg.wasm بنفس الأوامر.
import * as MB from 'mediabunny';
import { registerMp3Encoder } from '@mediabunny/mp3-encoder';
import { registerAacEncoder } from '@mediabunny/aac-encoder';
import { FFmpeg } from '@ffmpeg/ffmpeg';

const files = new Map(); // المسار الافتراضي -> Blob
let seq = 0;
let cancelled = false;
let activeConv = null;
let ff = null, ffLoading = null, ffBusy = false;

class Fallback extends Error {}

const MIME = {
  mp4: 'video/mp4', m4v: 'video/mp4', mov: 'video/quicktime', mkv: 'video/x-matroska',
  webm: 'video/webm', avi: 'video/x-msvideo', gif: 'image/gif', '3gp': 'video/3gpp',
  mp3: 'audio/mpeg', m4a: 'audio/mp4', aac: 'audio/aac', wav: 'audio/wav',
  ogg: 'audio/ogg', opus: 'audio/ogg', flac: 'audio/flac',
};
const extOf = (p) => { const m = /\.([a-z0-9]+)$/i.exec(p || ''); return m ? m[1].toLowerCase() : ''; };
const baseName = (p) => String(p).split('/').pop();
const blobOf = (p) => {
  const b = files.get(p);
  if (!b) throw new Error('الملف غير موجود (ربما حُذف). اختره من جديد.');
  return b;
};

// ───────────── Mediabunny ─────────────
let encReady = null;
function ensureEncoders() {
  if (!encReady) {
    encReady = (async () => {
      try { if (!(await MB.canEncodeAudio('mp3'))) registerMp3Encoder(); } catch (_) {}
      try { if (!(await MB.canEncodeAudio('aac'))) registerAacEncoder(); } catch (_) {}
    })();
  }
  return encReady;
}

function fmtFor(ext) {
  const name = {
    mp4: 'Mp4OutputFormat', m4v: 'Mp4OutputFormat', m4a: 'Mp4OutputFormat',
    mov: 'MovOutputFormat', mkv: 'MkvOutputFormat', webm: 'WebMOutputFormat',
    mp3: 'Mp3OutputFormat', wav: 'WavOutputFormat', opus: 'OggOutputFormat',
    aac: 'AdtsOutputFormat',
  }[ext];
  const C = name && MB[name];
  return C ? new C() : null;
}
const AUDIO_CODEC = { mp3: 'mp3', m4a: 'aac', aac: 'aac', wav: 'pcm-s16', opus: 'opus' };

function parseArgs(args) {
  const out = args[args.length - 1];
  const get = (f) => { const i = args.indexOf(f); return i >= 0 ? args[i + 1] : undefined; };
  return { args, out, input: get('-i'), get, has: (f) => args.includes(f), outExt: extOf(out) };
}

function classify(a) {
  if (a.args.includes('lavfi')) return 'ffmpeg'; // صوت إلى فيديو (خلفية ملونة)
  if (a.outExt === 'gif' || a.outExt === 'avi' || a.outExt === 'ogg' || a.outExt === 'flac') return 'ffmpeg';
  if (a.has('-filter_complex')) return 'overlay';
  if (a.has('-vf')) return /^fps=/.test(a.get('-vf') || '') ? 'ffmpeg' : 'compress';
  if (a.has('-vn')) return 'audio';
  if (a.has('-an')) return 'mute';
  if (a.has('-ss')) return 'trim';
  return 'convert';
}

const kbps = (s) => { const n = parseFloat(s); return isFinite(n) ? n * (/k$/i.test(s) ? 1000 : 1) : 0; };

function videoQuality(a) {
  const q = parseFloat(a.get('-q:v') || '5');
  const k = q <= 5 ? 'QUALITY_HIGH' : q <= 8 ? 'QUALITY_MEDIUM' : 'QUALITY_LOW';
  return MB[k];
}

async function runMB(kind, a, onProgress) {
  await ensureEncoders();
  const format = fmtFor(a.outExt);
  if (!format) throw new Fallback('format');
  const input = new MB.Input({ source: new MB.BlobSource(blobOf(a.input)), formats: MB.ALL_FORMATS });
  const output = new MB.Output({ format, target: new MB.BufferTarget() });
  const opts = { input, output };

  if (kind === 'audio') {
    const codec = AUDIO_CODEC[a.outExt];
    if (!codec) throw new Fallback('audio-codec');
    opts.video = { discard: true };
    opts.audio = { codec };
    const br = kbps(a.get('-b:a'));
    if (br && codec !== 'pcm-s16' && MB.Quality) opts.audio.quality = new MB.Quality({ bitrate: br });
  } else if (kind === 'mute') {
    opts.audio = { discard: true };
  } else if (kind === 'trim') {
    const s = parseFloat(a.get('-ss') || '0') || 0;
    const t = a.get('-t');
    opts.trim = t != null ? { start: s, end: s + parseFloat(t) } : { start: s };
  } else if (kind === 'compress') {
    const m = /min\(ih\\*,(\d+)\)/.exec(a.get('-vf') || '');
    const H = m ? parseInt(m[1], 10) : 0;
    opts.video = {};
    const q = videoQuality(a);
    if (q) opts.video.quality = q;
    if (H) {
      const vt = await input.getPrimaryVideoTrack();
      const sh = vt ? (typeof vt.getDisplayHeight === 'function' ? await vt.getDisplayHeight() : vt.displayHeight) : 0;
      if (sh > H) opts.video.height = H;
    }
    const ab = kbps(a.get('-b:a'));
    if (ab && MB.Quality) opts.audio = { quality: new MB.Quality({ bitrate: ab }) };
  } else if (kind === 'convert') {
    const q = videoQuality(a);
    if (q) opts.video = { quality: q };
  } else if (kind === 'overlay') {
    // الأوامر: -i فيديو -i overlay.png -filter_complex ...between(t,S,E)...
    const idx = a.args.reduce((r, v, i) => (v === '-i' ? r.concat(i) : r), []);
    const pngPath = a.args[idx[1] + 1];
    const fc = a.get('-filter_complex') || '';
    const mm = /between\(t,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)/.exec(fc);
    const s = mm ? parseFloat(mm[1]) : 0, e = mm ? parseFloat(mm[2]) : Infinity;
    const bmp = await createImageBitmap(blobOf(pngPath));
    let cv = null, ctx = null;
    opts.video = {
      forceTranscode: true,
      process: (sample) => {
        if (!ctx) {
          const w = sample.displayWidth, h = sample.displayHeight;
          cv = typeof OffscreenCanvas !== 'undefined'
            ? new OffscreenCanvas(w, h)
            : Object.assign(document.createElement('canvas'), { width: w, height: h });
          ctx = cv.getContext('2d');
        }
        sample.draw(ctx, 0, 0);
        const t = sample.timestamp;
        if (t >= s && t <= e) ctx.drawImage(bmp, 0, 0, cv.width, cv.height);
        return cv;
      },
    };
  }

  const conv = await MB.Conversion.init(opts);
  if (!conv.isValid) throw new Fallback('invalid');
  const lost = (conv.discardedTracks || []).filter((d) => {
    if (d.reason === 'discarded_by_user') return false;
    const t = d.track || {};
    const isVA = (t.isVideoTrack && t.isVideoTrack()) || (t.isAudioTrack && t.isAudioTrack())
      || t.type === 'video' || t.type === 'audio' || (!t.isVideoTrack && !t.isAudioTrack && !t.type);
    return isVA;
  });
  if (lost.length) throw new Fallback('track-lost');
  activeConv = conv;
  conv.onProgress = (p) => { if (onProgress) onProgress(p); };
  try {
    await conv.execute();
  } finally {
    activeConv = null;
  }
  const buf = output.target.buffer;
  if (!buf || !buf.byteLength) throw new Fallback('empty');
  files.set(a.out, new Blob([buf], { type: MIME[a.outExt] || 'application/octet-stream' }));
}

// ───────────── ffmpeg.wasm (احتياطي) ─────────────
function getFF() {
  if (ff) return Promise.resolve(ff);
  if (!ffLoading) {
    ffLoading = (async () => {
      const f = new FFmpeg();
      const base = new URL('ffmpeg/', import.meta.url).href;
      await f.load({
        classWorkerURL: base + 'worker.js',
        coreURL: base + 'ffmpeg-core.js',
        wasmURL: base + 'ffmpeg-core.wasm',
      });
      ff = f;
      return f;
    })().catch((e) => { ffLoading = null; throw e; });
  }
  return ffLoading;
}

async function runFF(a, onProgress) {
  const f = await getFF();
  const logs = [];
  const onLog = (e) => { logs.push(e.message); if (logs.length > 40) logs.shift(); };
  const onProg = (e) => {
    if (onProgress && isFinite(e.progress)) onProgress(Math.min(1, Math.max(0, e.progress)));
  };
  f.on('log', onLog);
  f.on('progress', onProg);
  const outName = baseName(a.out);
  const written = [];
  ffBusy = true;
  try {
    const mapped = [];
    for (const arg of a.args) {
      if (files.has(arg)) {
        const n = baseName(arg);
        await f.writeFile(n, new Uint8Array(await files.get(arg).arrayBuffer()));
        written.push(n);
        mapped.push(n);
      } else if (arg === a.out) {
        mapped.push(outName);
      } else {
        mapped.push(arg);
      }
    }
    const code = await f.exec(mapped);
    if (cancelled) throw new Error('تم الإلغاء');
    if (code !== 0) throw new Error('فشلت المعالجة.\n' + logs.slice(-3).join('\n'));
    const data = await f.readFile(outName);
    files.set(a.out, new Blob([data], { type: MIME[a.outExt] || 'application/octet-stream' }));
  } finally {
    ffBusy = false;
    try { f.off('log', onLog); f.off('progress', onProg); } catch (_) {}
    for (const n of written.concat([outName])) { try { await f.deleteFile(n); } catch (_) {} }
  }
}

// ───────────── الواجهة المستدعاة من Dart ─────────────
async function run(args, onProgress) {
  cancelled = false;
  const a = parseArgs(args);
  blobOf(a.input);
  const kind = classify(a);
  if (kind !== 'ffmpeg') {
    try {
      await runMB(kind, a, onProgress);
      return;
    } catch (e) {
      if (cancelled || (e && /cancel/i.test(e.name || e.constructor?.name || ''))) throw new Error('تم الإلغاء');
      files.delete(a.out);
      if (onProgress) onProgress(0);
      // نكمل بالمحرك الاحتياطي
    }
  }
  try {
    await runFF(a, onProgress);
  } catch (e) {
    if (cancelled) throw new Error('تم الإلغاء');
    const msg = (e && e.message) || String(e);
    if (/Failed to (fetch|load)|importScripts|dynamically imported|NetworkError|worker/i.test(msg)) {
      throw new Error('تعذر تحميل محرك المعالجة. تأكد من الإنترنت (أول استخدام) وأعد المحاولة.');
    }
    throw e;
  }
}

function cancel() {
  cancelled = true;
  try { if (activeConv) activeConv.cancel(); } catch (_) {}
  if (ffBusy && ff) {
    try { ff.terminate(); } catch (_) {}
    ff = null;
    ffLoading = null;
  }
}

async function probe(path) {
  const blob = blobOf(path);
  try {
    const input = new MB.Input({ source: new MB.BlobSource(blob), formats: MB.ALL_FORMATS });
    const duration = await input.computeDuration();
    const v = await input.getPrimaryVideoTrack();
    const au = await input.getPrimaryAudioTrack();
    let w = -1, h = -1;
    if (v) {
      w = typeof v.getDisplayWidth === 'function' ? await v.getDisplayWidth() : v.displayWidth;
      h = typeof v.getDisplayHeight === 'function' ? await v.getDisplayHeight() : v.displayHeight;
    }
    return { duration: isFinite(duration) ? duration : -1, hasAudio: !!au, hasVideo: !!v, width: w || -1, height: h || -1 };
  } catch (_) {
    // صيغة لا يقرؤها Mediabunny: نسأل المتصفح نفسه
    const url = URL.createObjectURL(blob);
    try {
      const el = document.createElement('video');
      el.preload = 'metadata';
      el.muted = true;
      const meta = await new Promise((res, rej) => {
        const t = setTimeout(() => rej(new Error('timeout')), 10000);
        el.onloadedmetadata = () => { clearTimeout(t); res(); };
        el.onerror = () => { clearTimeout(t); rej(new Error('bad')); };
        el.src = url;
      }).then(() => true, () => false);
      if (!meta) throw new Error('تعذر قراءة الملف. قد يكون تالفًا أو بصيغة غير مدعومة.');
      const hasVideo = el.videoWidth > 0;
      return {
        duration: isFinite(el.duration) ? el.duration : -1,
        hasAudio: true,
        hasVideo,
        width: hasVideo ? el.videoWidth : -1,
        height: hasVideo ? el.videoHeight : -1,
      };
    } finally {
      URL.revokeObjectURL(url);
    }
  }
}

function pick(kind) {
  return new Promise((resolve) => {
    const inp = document.createElement('input');
    inp.type = 'file';
    inp.accept = kind === 'video' ? 'video/*' : kind === 'audio' ? 'audio/*' : 'video/*,audio/*';
    inp.style.display = 'none';
    document.body.appendChild(inp);
    let done = false;
    const finish = (v) => { if (!done) { done = true; inp.remove(); resolve(v); } };
    inp.addEventListener('change', () => {
      const f = inp.files && inp.files[0];
      if (!f) return finish(null);
      const ext = extOf(f.name) || 'bin';
      const path = '/tmp/mt_in_' + (++seq) + '.' + ext;
      files.set(path, f);
      finish({ path, name: f.name, size: f.size });
    });
    inp.addEventListener('cancel', () => finish(null));
    inp.click();
  });
}

function put(path, bytes) { files.set(path, new Blob([bytes], { type: MIME[extOf(path)] || 'application/octet-stream' })); }
async function read(path) { return new Uint8Array(await blobOf(path).arrayBuffer()); }
async function size(path) { const b = files.get(path); return b ? b.size : 0; }
function del(path) { files.delete(path); }

function save(path, name, mime) {
  const blob = blobOf(path);
  const url = URL.createObjectURL(new Blob([blob], { type: mime || blob.type }));
  const el = document.createElement('a');
  el.href = url;
  el.download = name;
  el.style.display = 'none';
  document.body.appendChild(el);
  el.click();
  el.remove();
  setTimeout(() => URL.revokeObjectURL(url), 120000);
  return true;
}

async function share(path, name, mime) {
  try {
    const file = new File([blobOf(path)], name, { type: mime });
    if (navigator.canShare && navigator.share && navigator.canShare({ files: [file] })) {
      await navigator.share({ files: [file] });
      return true;
    }
  } catch (e) {
    if (e && e.name === 'AbortError') return true;
  }
  return false;
}

function preview(path, mime) {
  const blob = blobOf(path);
  const url = URL.createObjectURL(new Blob([blob], { type: mime || blob.type }));
  window.open(url, '_blank');
  setTimeout(() => URL.revokeObjectURL(url), 600000);
}

// ───────────── مشغّل داخل الصفحة (معاينة/قص بالشريط) ─────────────
function makePlayer(path, kind) {
  const blob = blobOf(path);
  const url = URL.createObjectURL(blob);
  let el;
  if (kind === 'image') {
    el = document.createElement('img');
    el.style.objectFit = 'contain';
  } else {
    el = document.createElement(kind === 'audio' ? 'audio' : 'video');
    el.controls = true;
    el.preload = 'metadata';
    el.playsInline = true;
    el.setAttribute('playsinline', '');
  }
  el.src = url;
  el.dataset.url = url;
  Object.assign(el.style, {
    width: '100%', height: '100%', borderRadius: '12px',
    background: kind === 'video' ? '#000' : 'transparent',
  });
  return el;
}
function releasePlayer(el) {
  try { if (el.pause) el.pause(); } catch (_) {}
  try { if (el.dataset && el.dataset.url) URL.revokeObjectURL(el.dataset.url); } catch (_) {}
}

// ───────────── تخزين دائم (IndexedDB) ─────────────
let dbp = null;
function idb() {
  if (!dbp) {
    dbp = new Promise((res, rej) => {
      const r = indexedDB.open('mt_store', 1);
      r.onupgradeneeded = () => {
        const d = r.result;
        for (const n of ['hist', 'html_meta', 'html_blob']) {
          if (!d.objectStoreNames.contains(n)) d.createObjectStore(n);
        }
      };
      r.onsuccess = () => res(r.result);
      r.onerror = () => { dbp = null; rej(r.error); };
    });
  }
  return dbp;
}
async function tx(store, mode, fn) {
  const d = await idb();
  return new Promise((res, rej) => {
    const t = d.transaction(store, mode);
    const rq = fn(t.objectStore(store));
    t.oncomplete = () => res(rq ? rq.result : undefined);
    t.onerror = () => rej(t.error);
    t.onabort = () => rej(t.error || new Error('تعذر الحفظ (قد تكون مساحة المتصفح ممتلئة).'));
  });
}

// سجل «عملياتي السابقة»: نسخة دائمة من نتيجة العملية
async function persist(path, id) {
  const b = blobOf(path);
  await tx('hist', 'readwrite', (s) => s.put(b, id));
  const vp = '/hist/' + id + '.' + (extOf(path) || 'bin');
  files.set(vp, b);
  return vp;
}
async function restore(path, id) {
  if (files.has(path)) return true;
  const b = await tx('hist', 'readonly', (s) => s.get(id));
  if (!b) return false;
  files.set(path, b);
  return true;
}
async function unpersist(path, id) {
  files.delete(path);
  await tx('hist', 'readwrite', (s) => s.delete(id));
}

window.mtMedia = {
  run, cancel, probe, pick, put, read, size, del, save, share, preview,
  makePlayer, releasePlayer, persist, restore, unpersist,
};

// ───────────── تشغيل صفحة HTML / مشروع ZIP ─────────────
export async function unzip(blob) {
  const buf = new Uint8Array(await blob.arrayBuffer());
  const dv = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  let e = buf.length - 22;
  while (e >= 0 && dv.getUint32(e, true) !== 0x06054b50) e--;
  if (e < 0) throw new Error('ملف ZIP غير صالح');
  const total = dv.getUint16(e + 10, true);
  let p = dv.getUint32(e + 16, true);
  const dec = new TextDecoder();
  const raw = [];
  for (let i = 0; i < total; i++) {
    if (p + 46 > buf.length || dv.getUint32(p, true) !== 0x02014b50) break;
    const method = dv.getUint16(p + 10, true);
    const csize = dv.getUint32(p + 20, true);
    const nlen = dv.getUint16(p + 28, true);
    const xlen = dv.getUint16(p + 30, true);
    const clen = dv.getUint16(p + 32, true);
    const off = dv.getUint32(p + 42, true);
    const name = dec.decode(buf.subarray(p + 46, p + 46 + nlen)).replace(/\\/g, '/');
    p += 46 + nlen + xlen + clen;
    if (name.endsWith('/')) continue;
    if (name.split('/').some((x) => x === '' || x === '.' || x === '..')) continue;
    raw.push({ name, method, csize, off });
  }
  if (!raw.length) throw new Error('ملف ZIP فارغ');
  // مجلد جذري واحد يضم كل شيء؟ نزيله
  const first = raw[0].name.split('/')[0];
  const strip = raw.every((r) => r.name.includes('/') && r.name.split('/')[0] === first) ? first.length + 1 : 0;
  const out = new Map();
  for (const r of raw) {
    const ln = dv.getUint16(r.off + 26, true);
    const lx = dv.getUint16(r.off + 28, true);
    const start = r.off + 30 + ln + lx;
    const data = buf.subarray(start, start + r.csize);
    let b;
    if (r.method === 0) b = new Blob([data]);
    else if (r.method === 8) b = await new Response(new Blob([data]).stream().pipeThrough(new DecompressionStream('deflate-raw'))).blob();
    else continue;
    out.set(r.name.slice(strip), b);
  }
  return out;
}

const HTML_MIME = {
  html: 'text/html', htm: 'text/html', css: 'text/css', js: 'text/javascript', mjs: 'text/javascript',
  json: 'application/json', svg: 'image/svg+xml', png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg',
  gif: 'image/gif', webp: 'image/webp', ico: 'image/x-icon', woff: 'font/woff', woff2: 'font/woff2',
  ttf: 'font/ttf', otf: 'font/otf', mp3: 'audio/mpeg', mp4: 'video/mp4', webm: 'video/webm',
  wav: 'audio/wav', ogg: 'audio/ogg', txt: 'text/plain', xml: 'application/xml', wasm: 'application/wasm',
};

export function findEntry(names) {
  const htmls = names.filter((n) => /\.html?$/i.test(n));
  if (!htmls.length) return null;
  if (htmls.includes('index.html')) return 'index.html';
  htmls.sort((a, b) => (a.split('/').length - b.split('/').length) || (a.length - b.length));
  return htmls[0];
}

const dirOf = (p) => (p.includes('/') ? p.slice(0, p.lastIndexOf('/') + 1) : '');
const isExternal = (u) => !u || /^([a-z][a-z0-9+.-]*:|\/\/|#)/i.test(u);

// يحوّل مسارًا نسبيًا إلى مسار داخل المشروع (أو null)
export function resolvePath(baseDir, ref) {
  if (isExternal(ref)) return null;
  const clean = ref.split('#')[0].split('?')[0];
  if (!clean) return null;
  const parts = (clean.startsWith('/') ? clean.slice(1) : baseDir + clean).split('/');
  const st = [];
  for (const x of parts) {
    if (x === '' || x === '.') continue;
    if (x === '..') st.pop(); else st.push(x);
  }
  let r = st.join('/');
  try { r = decodeURIComponent(r); } catch (_) {}
  return r;
}

async function buildProjectUrl(map) {
  const entry = findEntry([...map.keys()]);
  if (!entry) throw new Error('لا يوجد ملف HTML داخل ZIP.');
  const urls = new Map();
  const typed = (name, blob) => new Blob([blob], { type: HTML_MIME[extOf(name)] || blob.type || 'application/octet-stream' });
  const urlOf = (name) => {
    if (!urls.has(name)) urls.set(name, URL.createObjectURL(typed(name, map.get(name))));
    return urls.get(name);
  };
  // ملفات CSS: نحوّل url(...) فيها لروابط الملفات الأخرى
  for (const name of [...map.keys()]) {
    if (extOf(name) !== 'css') continue;
    let css = await map.get(name).text();
    const bd = dirOf(name);
    css = css.replace(/url\(\s*(['"]?)([^)'"]+)\1\s*\)/g, (m, q, u) => {
      const t = resolvePath(bd, u.trim());
      return t && map.has(t) && extOf(t) !== 'css' ? 'url("' + urlOf(t) + '")' : m;
    });
    urls.set(name, URL.createObjectURL(new Blob([css], { type: 'text/css' })));
  }
  const ed = dirOf(entry);
  const text = await map.get(entry).text();
  const doc = new DOMParser().parseFromString(text, 'text/html');
  for (const el of doc.querySelectorAll('[src],[href],[poster]')) {
    if (el.tagName === 'A') continue;
    for (const a of ['src', 'href', 'poster']) {
      const v = el.getAttribute(a);
      if (v == null) continue;
      const t = resolvePath(ed, v.trim());
      if (t && map.has(t)) el.setAttribute(a, urlOf(t));
    }
  }
  for (const st of doc.querySelectorAll('style')) {
    st.textContent = st.textContent.replace(/url\(\s*(['"]?)([^)'"]+)\1\s*\)/g, (m, q, u) => {
      const t = resolvePath(ed, u.trim());
      return t && map.has(t) && extOf(t) !== 'css' ? 'url("' + urlOf(t) + '")' : m;
    });
  }
  // fetch / XMLHttpRequest للملفات النسبية (مثل data.json) تُوجَّه لملفات المشروع
  const table = {};
  for (const n of map.keys()) table[n] = urlOf(n);
  const shim = '(function(){var T=' + JSON.stringify(table).replace(/</g, '\\u003c') + ',D=' + JSON.stringify(ed) +
    ';function R(u){if(typeof u!=="string"||/^([a-z][a-z0-9+.-]*:|\\/\\/|#)/i.test(u))return u;var c=u.split("#")[0].split("?")[0];' +
    'var s=(c.charAt(0)==="/"?c.slice(1):D+c).split("/"),o=[];for(var i=0;i<s.length;i++){if(s[i]===""||s[i]===".")continue;if(s[i]==="..")o.pop();else o.push(s[i]);}' +
    'var k=o.join("/");try{k=decodeURIComponent(k);}catch(e){}return T[k]||u;}' +
    'var f=window.fetch;if(f)window.fetch=function(i,n){return f.call(this,R(i),n);};' +
    'var x=XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open=function(m,u){var a=Array.prototype.slice.call(arguments);a[1]=R(u);return x.apply(this,a);};})();';
  const sc = doc.createElement('script');
  sc.textContent = shim;
  doc.head.insertBefore(sc, doc.head.firstChild);
  const html = '<!doctype html>\n' + doc.documentElement.outerHTML;
  return URL.createObjectURL(new Blob([html], { type: 'text/html;charset=utf-8' }));
}

async function htmlUrl(id) {
  const meta = await tx('html_meta', 'readonly', (s) => s.get(id));
  const blob = await tx('html_blob', 'readonly', (s) => s.get(id));
  if (!meta || !blob) throw new Error('المشروع غير موجود (ربما حُذف).');
  if (!meta.zip) return URL.createObjectURL(new Blob([blob], { type: 'text/html;charset=utf-8' }));
  return buildProjectUrl(await unzip(blob));
}

function pickHtml() {
  return new Promise((resolve) => {
    const inp = document.createElement('input');
    inp.type = 'file';
    inp.accept = '.html,.htm,.zip,text/html,application/zip,application/x-zip-compressed';
    inp.style.display = 'none';
    document.body.appendChild(inp);
    let done = false;
    const finish = (v) => { if (!done) { done = true; inp.remove(); resolve(v); } };
    inp.addEventListener('change', () => finish((inp.files && inp.files[0]) || null));
    inp.addEventListener('cancel', () => finish(null));
    inp.click();
  });
}

window.mtHtml = {
  async listJson() {
    const all = await tx('html_meta', 'readonly', (s) => s.getAll());
    return JSON.stringify((all || []).sort((a, b) => b.ts - a.ts));
  },
  async add() {
    const f = await pickHtml();
    if (!f) return null;
    const low = f.name.toLowerCase();
    const zip = low.endsWith('.zip');
    if (!zip && !/\.html?$/.test(low)) throw new Error('اختر ملف HTML أو مشروع ZIP.');
    if (zip) {
      const m = await unzip(f);
      if (!findEntry([...m.keys()])) throw new Error('لا يوجد ملف HTML داخل ZIP.');
    }
    const id = String(Date.now()) + String(++seq);
    const meta = { id, name: f.name.replace(/\.(html?|zip)$/i, ''), zip, ts: Date.now() };
    await tx('html_blob', 'readwrite', (s) => s.put(f, id));
    await tx('html_meta', 'readwrite', (s) => s.put(meta, id));
    return JSON.stringify(meta);
  },
  async del(id) {
    await tx('html_blob', 'readwrite', (s) => s.delete(id));
    await tx('html_meta', 'readwrite', (s) => s.delete(id));
  },
  view(id) {
    const fr = document.createElement('iframe');
    Object.assign(fr.style, { border: '0', width: '100%', height: '100%', background: '#fff' });
    fr.setAttribute('allow', 'camera; microphone; geolocation; clipboard-read; clipboard-write; fullscreen');
    fr.setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms allow-modals allow-popups allow-downloads allow-pointer-lock');
    htmlUrl(id).then((u) => { fr.dataset.url = u; fr.src = u; }).catch((e) => {
      fr.srcdoc = '<meta charset="utf-8"><body style="font-family:sans-serif;padding:24px;direction:rtl">' +
        String((e && e.message) || e).replace(/[<&]/g, '') + '</body>';
    });
    return fr;
  },
  release(el) { try { if (el.dataset && el.dataset.url) URL.revokeObjectURL(el.dataset.url); } catch (_) {} },
};
