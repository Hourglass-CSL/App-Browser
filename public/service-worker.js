// service-worker.js

const CACHE_VERSION = 'v1.0.1';            // <-- súbelo cuando cambies el SW
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const OFFLINE_URL = '/offline.html';

const PRECACHE = [
  '/',
  '/offline.html',
  '/manifest.webmanifest',
  '/icons/icon-192.png',
  '/icons/icon-512.png'
];

// ---------- Utils ----------
function isHttp(req) {
  try { return new URL(req.url).protocol.startsWith('http'); }
  catch { return false; }
}

function sameOrigin(req) {
  try { return new URL(req.url).origin === self.location.origin; }
  catch { return false; }
}

function isActiveStorage(req) {
  try { return new URL(req.url).pathname.startsWith('/rails/active_storage/'); }
  catch { return false; }
}

function isCable(req) {
  try { return new URL(req.url).pathname.startsWith('/cable'); }
  catch { return false; }
}

function shouldSkip(req) {
  // No GET, no http(s), cross-origin, ActiveStorage, cable → no interceptar
  return req.method !== 'GET' ||
         !isHttp(req) ||
         !sameOrigin(req) ||
         isActiveStorage(req) ||
         isCable(req);
}

async function cachePutSafe(cache, req, res) {
  // Solo cachear 200 "basic" (misma origen), sin redirects/opaques, y si no hay no-store
  try {
    const cc = res.headers.get('Cache-Control') || '';
    if (
      res.ok &&
      res.status === 200 &&
      res.type === 'basic' &&
      !res.redirected &&
      !cc.includes('no-store') &&
      req.method === 'GET'
    ) {
      await cache.put(req, res.clone());
    }
  } catch (_) { /* silencioso */ }
}

// ---------- Install ----------
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(PRECACHE))
  );
  self.skipWaiting();
});

// ---------- Activate ----------
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.map((k) => (k.startsWith('static-') && k !== STATIC_CACHE) ? caches.delete(k) : undefined)
      )
    )
  );
  self.clients.claim();
});

// ---------- Fetch ----------
self.addEventListener('fetch', (event) => {
  const req = event.request;

  if (shouldSkip(req)) return; // dejar pasar al navegador

  const acceptsHtml = req.headers.get('accept')?.includes('text/html');

  // HTML → network first con fallback a cache/offline
  if (acceptsHtml) {
    event.respondWith((async () => {
      try {
        const res = await fetch(req);
        const cache = await caches.open(STATIC_CACHE);
        await cachePutSafe(cache, req, res);
        return res;
      } catch {
        const cached = await caches.match(req);
        return cached || caches.match(OFFLINE_URL);
      }
    })());
    return;
  }

  // Otros (CSS/JS/IMG…) → cache first con actualización en segundo plano
  event.respondWith((async () => {
    const cached = await caches.match(req);
    const fetchPromise = (async () => {
      try {
        const res = await fetch(req);
        const cache = await caches.open(STATIC_CACHE);
        await cachePutSafe(cache, req, res);
        return res;
      } catch {
        return cached; // si hay cache, úsalo en fallo de red
      }
    })();
    return cached || fetchPromise;
  })());
});
