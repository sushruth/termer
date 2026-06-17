addEventListener("fetch", event => {
  const url = new URL(event.request.url)
  if (url.pathname === "/install" || url.pathname === "/install.sh") {
    event.respondWith(fetch("https://github.com/sushruth/termer/releases/latest/download/install.sh", {
      headers: { "Cache-Control": "no-cache" },
      cf: { cacheTtl: 0, cacheEverything: false }
    }).then(response => response.text()).then(body => new Response(body, {
      headers: {
        "content-type": "application/x-sh; charset=utf-8",
        "cache-control": "no-store, no-cache, must-revalidate, max-age=0",
        "pragma": "no-cache",
        "expires": "0"
      }
    })))
    return
  }

  if (url.pathname !== "/") {
    event.respondWith(new Response("not found\n", { status: 404 }))
    return
  }

  event.respondWith(new Response(`<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Termer</title>
<style>
  :root { color-scheme: light dark; font: 16px/1.45 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: Canvas; color: CanvasText; }
  main { width: min(560px, calc(100vw - 48px)); }
  h1 { font-size: 40px; letter-spacing: 0; margin: 0 0 10px; }
  p { margin: 0 0 22px; color: color-mix(in srgb, CanvasText 68%, Canvas); }
  code { display: block; padding: 14px 16px; border: 1px solid color-mix(in srgb, CanvasText 14%, Canvas); border-radius: 8px; overflow-x: auto; }
  a { color: LinkText; }
</style>
<main>
  <h1>Termer</h1>
  <p>Create macOS apps for terminal UI commands.</p>
  <code>curl -fsSL https://termer.sushruth.dev/install | zsh</code>
  <p><a href="https://github.com/sushruth/termer">GitHub</a></p>
</main>`, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store, no-cache, must-revalidate, max-age=0"
    }
  }))
})
