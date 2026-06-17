addEventListener("fetch", event => {
  event.respondWith(handle(event.request))
})

async function handle(request) {
  const url = new URL(request.url)

  if (url.pathname === "/install" || url.pathname === "/install.sh") {
    const release = await fetch("https://api.github.com/repos/usually-frustrated/termer/releases/latest", {
      headers: {
        "Accept": "application/vnd.github+json",
        "User-Agent": "termer-install",
        "Cache-Control": "no-cache"
      },
      cf: { cacheTtl: 0, cacheEverything: false }
    }).then(response => response.json())

    return Response.redirect(
      `https://github.com/usually-frustrated/termer/releases/download/${release.tag_name}/install.sh`,
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
<link rel="icon" href="https://raw.githubusercontent.com/usually-frustrated/termer/main/icons/web/favicon.ico">
<link rel="apple-touch-icon" href="https://raw.githubusercontent.com/usually-frustrated/termer/main/icons/web/apple-touch-icon.png">
<style>
  :root { color-scheme: light dark; font: 16px/1.45 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: Canvas; color: CanvasText; }
  main { width: min(560px, calc(100vw - 48px)); }
  .logo { width: 72px; height: 72px; border-radius: 16px; display: block; margin: 0 0 18px; }
  h1 { font-size: 40px; letter-spacing: 0; margin: 0 0 10px; }
  p { margin: 0 0 22px; color: color-mix(in srgb, CanvasText 68%, Canvas); }
  .shot { display: block; max-width: 100%; border-radius: 10px; border: 1px solid color-mix(in srgb, CanvasText 14%, Canvas); margin: 0 0 22px; }
  code { display: block; padding: 14px 16px; border: 1px solid color-mix(in srgb, CanvasText 14%, Canvas); border-radius: 8px; overflow-x: auto; }
  a { color: LinkText; }
</style>
<main>
  <img class="logo" src="https://raw.githubusercontent.com/usually-frustrated/termer/main/icons/web/icon-512.png" alt="Termer">
  <h1>Termer</h1>
  <p>Create macOS apps for terminal UI commands.</p>
  <img class="shot" src="https://raw.githubusercontent.com/usually-frustrated/termer/main/docs/screenshot.png" alt="Termer screenshot">
  <code>curl -fsSL https://termer.frustrated.dev/install | zsh</code>
  <p><a href="https://github.com/usually-frustrated/termer">GitHub</a></p>
</main>`, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store, no-cache, must-revalidate, max-age=0"
    }
  })
}
