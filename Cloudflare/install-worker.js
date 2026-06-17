addEventListener("fetch", event => {
  const url = new URL(event.request.url)
  if (url.pathname !== "/" && url.pathname !== "/install.sh") {
    event.respondWith(new Response("not found\n", { status: 404 }))
    return
  }

  event.respondWith(Response.redirect(
    "https://github.com/sushruth/termer/releases/latest/download/install.sh",
    302
  ))
})
