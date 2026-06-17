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
  :root { color-scheme: light dark; font: 14px/1.45 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: Canvas; color: CanvasText; }
  main { width: min(340px, calc(100vw - 40px)); }
  .logo { width: 44px; height: 44px; border-radius: 10px; display: block; margin: 0 0 12px; }
  h1 { font-size: 24px; letter-spacing: 0; margin: 0 0 6px; }
  p { margin: 0 0 14px; color: color-mix(in srgb, CanvasText 68%, Canvas); }
  .shot { display: block; max-width: 100%; filter: drop-shadow(0 1px 2px rgba(0,0,0,.1)) drop-shadow(0 8px 20px rgba(0,0,0,.18)); margin: 4px 0 18px; }
  code { display: block; padding: 10px 12px; font-size: 12px; border: 1px solid color-mix(in srgb, CanvasText 14%, Canvas); border-radius: 8px; overflow-x: auto; }
  a { color: LinkText; }
  .gh { display: inline-flex; margin-top: 16px; color: color-mix(in srgb, CanvasText 70%, Canvas); }
  .gh svg { width: 22px; height: 22px; fill: currentColor; }
</style>
<main>
  <img class="logo" src="https://raw.githubusercontent.com/usually-frustrated/termer/main/icons/web/icon-512.png" alt="Termer">
  <h1>Termer</h1>
  <p>Create macOS apps for terminal UI commands.</p>
  <img class="shot" src="https://raw.githubusercontent.com/usually-frustrated/termer/main/docs/screenshot.png" alt="Termer screenshot">
  <code>curl -fsSL https://termer.frustrated.dev/install | zsh</code>
  <p><a class="gh" href="https://github.com/usually-frustrated/termer" aria-label="GitHub"><svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>GitHub</title><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg></a></p>
</main>`, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store, no-cache, must-revalidate, max-age=0"
    }
  })
}
