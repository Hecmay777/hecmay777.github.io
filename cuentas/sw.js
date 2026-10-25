/* Cuentas de Casa: permite instalar la app y abrirla sin conexión.
   Siempre intenta la versión más nueva de internet; si no hay conexión, usa la guardada. */
const CACHE='cuentas-v1';
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(CACHE).then(c=>c.addAll(['./','./index.html','./manifest.webmanifest','./icon-192.png','./icon-512.png'])).catch(()=>{}))});
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{
  const r=e.request;
  if(r.method!=='GET')return;                          // las sincronizaciones con Google no se tocan
  const u=new URL(r.url);
  const propio=u.origin===self.location.origin;
  const libreria=/cdnjs\.cloudflare\.com/.test(u.host); // lectores de Excel y PDF
  if(!propio&&!libreria)return;
  e.respondWith(fetch(r).then(res=>{if(res&&res.ok){const copia=res.clone();caches.open(CACHE).then(c=>c.put(r,copia))}return res})
    .catch(()=>caches.match(r).then(m=>m||(r.mode==='navigate'?caches.match('./'):undefined))));
});
