# RedGiant's website

A small static site for `https://smpdigital.it/redgiant/`: the home page (`index.html`) and the
downloads (`download.html`). Plain HTML, CSS and a little JavaScript, outside pnpm and Biome; every
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
    img/                      generated: logo, favicon and docs/screenshots
  tools/
    build.mjs                 regenerates the generated files, and the self-contained "tavola"
    shots.mjs                 screenshots of both pages (computer and phone, light and dark, it and en)
```

## Downloads

- Buttons point to `https://github.com/Frostmoore/redgiant2/releases/latest/download/<name>`, with
  the names in `assets/config.js`: the site stays valid at every release without being uploaded
  again. Without JavaScript they open the latest release's page.
- The "latest version" box reads `api.github.com/repos/Frostmoore/redgiant2/releases/latest`; if
  the API does not answer (offline, rate limit) it simply stays hidden.
- RedGiant OS images carry their version in the name and sit on the latest release that has them
  (the one `redgiant-os-release` names): the page looks through the latest releases for the first
  one with `redgiant-os-*-x86_64.iso` and links its files; otherwise the buttons open the latest
  release, whose notes link the images.

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
  node site/tools/shots.mjs /mnt/archive1/officina-dati/rg-test/site-redgiant   # add --live for GitHub's API
```

## Uploading

Copy the contents of `site/` except `tools/` and this README into the `redgiant/` folder of the
web space, for example:

```sh
rsync -av --delete --exclude tools --exclude README.md site/ user@host:/path/to/public_html/redgiant/
```

or the same files by SFTP/FTP. There is no build step on the server and nothing to configure;
only release file names that change need an upload (`assets/config.js`).
