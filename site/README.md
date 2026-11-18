# Rasgeth's website

A small static site for **https://rasgeth.it** (the old address, `https://smpdigital.it/redgiant/`, is
to send visitors there): the home page (`index.html`) and the downloads (`download.html`). Plain HTML, CSS and a little JavaScript, outside pnpm and Biome; every
path is relative, so it works from any folder of any host. Nothing is loaded from elsewhere (no
fonts, scripts or trackers from a CDN); the only outside requests are GitHub's public API, made by
the visitor's browser.

```
site/
  index.html, download.html   the pages; every text twice, lang="it" and lang="en"
  assets/
    config.js                 every release file name the buttons link (one place to change)
    boot.js                   language (saved, or the browser's) and theme, before the page draws
    site.js                   switches, download links, latest version and OS images from GitHub
    site.css                  colours and type from packages/web/src/styles.css, light and dark
    icons.svg                 generated: drawn icons (packages/web/src/icons.tsx) + logos (simple-icons)
    mascot-motion.css         generated: the mascots' motion (@redgiant/mascot)
    img/                      generated: logo, favicon and docs/screenshots; by hand: wordmark.png
                              (the written name) and share.jpg (1200x630, for links shared in chats)
  tools/
    build.mjs                 regenerates the generated files, and the self-contained "tavola"
    shots.mjs                 screenshots of both pages (computer and phone, light and dark, it and en)
```

## Downloads

- Buttons point to `https://github.com/Frostmoore/redgiant2/releases/latest/download/<name>` (the
  repository keeps that address until it is renamed `Frostmoore/rasgeth`; GitHub then redirects), with
  the names in `assets/config.js`: the site stays valid at every release without being uploaded
  again. Without JavaScript they open the latest release's page.
- The "latest version" box reads `api.github.com/repos/Frostmoore/redgiant2/releases/latest`; if
  the API does not answer (offline, rate limit) it simply stays hidden.
- Rasgeth OS images carry their version in the name and sit on the latest release that has them
  (the one `rasgeth-os-release` names): the page looks through the latest releases for the first
  one with `rasgeth-os-*-x86_64.iso` (or `redgiant-os-*`, the name of the images before 3.9.0) and
  links its files; otherwise the buttons open the latest release, whose notes link the images.

## Rebuilding

After a change to the screenshots, the logo, the page's icons or the mascots (needs `pnpm build`
once, for `packages/mascot/dist`):

```sh
node site/tools/build.mjs
# and a self-contained copy of the home page (images as data: URIs), to show around:
node site/tools/build.mjs --tavola /path/to/tavole-sito/index.html
```

Look at it before uploading (Playwright image, `playwright-core` from the repository):

```sh
docker run --rm -v "$PWD:$PWD" -w "$PWD" mcr.microsoft.com/playwright:v1.64.1-noble \
  node site/tools/shots.mjs /mnt/archive1/officina-dati/rg-test/site-rasgeth   # add --live for GitHub's API
```

`wordmark.png` and `share.jpg` come from the name's artwork (`RASGETH-SCRITTA.png`, `RASGETH-HEADER.png`):
to make them again, scale the first to 880 px wide and cut the second to 1200x630 around the star.

## Uploading

Only with the owner's yes. Copy the contents of `site/` except `tools/` and this README into the
document root of rasgeth.it, for example:

```sh
rsync -av --delete --exclude tools --exclude README.md site/ user@host:/path/to/rasgeth.it/
```

The canonical addresses and the share image's address in the pages' `<head>` say `https://rasgeth.it/`:
on another host, change them too.

or the same files by SFTP/FTP. There is no build step on the server and nothing to configure;
only release file names that change need an upload (`assets/config.js`).
