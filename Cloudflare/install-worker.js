addEventListener("fetch", event => {
  event.respondWith(handle(event.request))
})

async function handle(request) {
  const url = new URL(request.url)

  if (url.pathname === "/install" || url.pathname === "/install.sh") {
    const release = await fetch("https://api.github.com/repos/sushruth/termer/releases/latest", {
      headers: {
        "Accept": "application/vnd.github+json",
        "User-Agent": "termer-install",
        "Cache-Control": "no-cache"
      },
      cf: { cacheTtl: 0, cacheEverything: false }
    }).then(response => response.json())

    return Response.redirect(
      `https://github.com/sushruth/termer/releases/download/${release.tag_name}/install.sh`,
      302
    )
  }

  if (url.pathname !== "/") {
    return new Response("not found\n", { status: 404 })
  }

  return new Response(`<!doctype html>
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
  })
}
