// Service worker خاص بتطبيق «أدواتي اليومية» فقط: نطاقه /my-tools/ واسم الكاش خاص به،
// ولا يلمس أي كاش لمشاريع أخرى على نفس النطاق (github.io).
// الشبكة أولًا حتى يظهر آخر إصدار دائمًا، والكاش احتياطي عند انقطاع الإنترنت.
const CACHE = 'my-tools-pwa-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys.filter((k) => k.startsWith('my-tools-pwa-') && k !== CACHE).map((k) => caches.delete(k))
    );
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;
  if (!url.pathname.startsWith(new URL(self.registration.scope).pathname)) return;
  e.respondWith((async () => {
    try {
      const res = await fetch(req);
      if (res && res.ok && res.status === 200) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
      }
      return res;
    } catch (err) {
      const hit = await caches.match(req);
      if (hit) return hit;
      if (req.mode === 'navigate') {
        const home = await caches.match(self.registration.scope);
        if (home) return home;
      }
      throw err;
    }
  })());
});
