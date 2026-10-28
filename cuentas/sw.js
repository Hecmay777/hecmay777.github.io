/* Cuentas de Casa: permite instalar la app y abrirla sin conexión.
   Siempre intenta la versión más nueva de internet; si no hay conexión, usa la guardada. */
const CACHE='cuentas-v2';
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(CACHE).then(c=>c.addAll(['./','./index.html','./manifest.webmanifest','./icon-192.png','./icon-512.png'])).catch(()=>{}))});
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE&&k!=='cc-compartido').map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{
  const r=e.request;
  /* «Compartir» desde la galería o el navegador del móvil (Android): guarda el archivo y abre la app para leerlo */
  if(r.method==='POST'&&new URL(r.url).searchParams.has('compartido')){
    e.respondWith((async()=>{
      try{const fd=await r.formData();const f=fd.get('archivo');
        if(f&&f.size){const c=await caches.open('cc-compartido');await c.put('archivo',new Response(f,{headers:{'Content-Type':f.type||'application/octet-stream','X-Nombre':encodeURIComponent(f.name||'')}}))}
      }catch(err){}
      return Response.redirect(new URL('./?compartido=1',self.registration.scope).href,303);
    })());
    return;
  }
  if(r.method!=='GET')return;                          // las sincronizaciones con Google no se tocan
  const u=new URL(r.url);
  const propio=u.origin===self.location.origin;
  const libreria=/cdnjs\.cloudflare\.com/.test(u.host); // lectores de Excel y PDF
  if(!propio&&!libreria)return;
  e.respondWith(fetch(r).then(res=>{if(res&&res.ok){const copia=res.clone();caches.open(CACHE).then(c=>c.put(r,copia))}return res})
    .catch(()=>caches.match(r).then(m=>m||(r.mode==='navigate'?caches.match('./'):undefined))));
});
