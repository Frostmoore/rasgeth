// RedGiant's site: language and theme switches, download links from config.js, the latest
// version and the RedGiant OS images read from GitHub's public API (silently skipped when it
// does not answer). No cookies, no tracking: only the two choices, kept in localStorage.
(() => {
  const cfg = window.RG_SITE;
  const d = document.documentElement;
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  const repoUrl = `https://github.com/${cfg.repo}`;
  const latestDl = `${repoUrl}/releases/latest/download/`;
  const save = (k, v) => {
    try {
      localStorage.setItem(k, v);
    } catch {}
  };

  // ---------- Language ----------
  // Texts are written twice in the HTML (lang="it" / lang="en"); attributes come from
  // data-<attr>-it / data-<attr>-en.
  const ATTRS = ["alt", "aria-label", "title", "content"];
  function applyLang(lang) {
    d.lang = lang;
    for (const el of $$("[data-i18n]")) {
      for (const a of ATTRS) {
        const v = el.getAttribute(`data-${a}-${lang}`);
        if (v !== null) el.setAttribute(a, v);
      }
    }
    const title = document.querySelector("title");
    const t = title?.getAttribute(`data-${lang}`);
    if (title && t) title.textContent = t;
    for (const b of $$("[data-set-lang]")) {
      b.setAttribute("aria-pressed", String(b.dataset.setLang === lang));
    }
    renderLatest();
  }

  // ---------- Theme ----------
  function applyTheme(theme) {
    d.dataset.theme = theme;
    for (const b of $$("[data-set-theme]")) {
      b.setAttribute("aria-pressed", String(b.dataset.setTheme === theme));
    }
  }

  document.addEventListener("click", (e) => {
    const target = e.target instanceof Element ? e.target : null;
    const lb = target?.closest("[data-set-lang]");
    if (lb) {
      save("rg-site-lang", lb.dataset.setLang);
      applyLang(lb.dataset.setLang);
      return;
    }
    const tb = target?.closest("[data-set-theme]");
    if (tb) {
      save("rg-site-theme", tb.dataset.setTheme);
      applyTheme(tb.dataset.setTheme);
      return;
    }
    const cb = target?.closest("[data-copy]");
    if (cb) copy(cb);
  });

  // ---------- Copy a command ----------
  async function copy(button) {
    const code = button.parentElement?.querySelector("code");
    if (!code) return;
    try {
      await navigator.clipboard.writeText(code.textContent.trim());
    } catch {
      const r = document.createRange();
      r.selectNodeContents(code);
      const s = getSelection();
      s?.removeAllRanges();
      s?.addRange(r);
      return;
    }
    button.classList.add("done");
    const live = document.getElementById("live");
    if (live) live.textContent = d.lang === "it" ? "Comando copiato" : "Command copied";
    setTimeout(() => button.classList.remove("done"), 1800);
  }

  // ---------- Download links ----------
  for (const a of $$("[data-dl]")) {
    const name = cfg.files[a.dataset.dl];
    if (name) a.href = latestDl + encodeURIComponent(name);
  }
  for (const el of $$("[data-dl-name]")) {
    const name = cfg.files[el.dataset.dlName];
    if (name) el.textContent = name;
  }

  // ---------- GitHub's public API ----------
  const API = `https://api.github.com/repos/${cfg.repo}`;
  async function getJson(path, key) {
    try {
      const cached = sessionStorage.getItem(key);
      if (cached) return JSON.parse(cached);
    } catch {}
    const ctl = new AbortController();
    const timer = setTimeout(() => ctl.abort(), 6000);
    try {
      const r = await fetch(API + path, {
        signal: ctl.signal,
        headers: { Accept: "application/vnd.github+json" },
      });
      if (!r.ok) return null;
      const data = await r.json();
      try {
        sessionStorage.setItem(key, JSON.stringify(data));
      } catch {}
      return data;
    } catch {
      return null;
    } finally {
      clearTimeout(timer);
    }
  }

  let latest = null;
  function renderLatest() {
    const box = document.getElementById("latest");
    if (!box || !latest?.tag_name) return;
    box.querySelector("[data-v]").textContent = latest.tag_name;
    const time = box.querySelector("time");
    if (latest.published_at && time) {
      const date = new Date(latest.published_at);
      time.dateTime = latest.published_at;
      time.textContent = date.toLocaleDateString(d.lang === "it" ? "it-IT" : "en-GB", {
        day: "numeric",
        month: "long",
        year: "numeric",
      });
    }
    const notes = box.querySelector("[data-notes]");
    if (notes && /^https:\/\/github\.com\//.test(latest.html_url)) notes.href = latest.html_url;
    box.hidden = false;
  }

  async function loadLatest() {
    if (!document.getElementById("latest")) return;
    const r = await getJson("/releases/latest", "rg-site-latest");
    if (r && typeof r.tag_name === "string" && /^v?\d+\.\d+\.\d+/.test(r.tag_name)) {
      latest = r;
      renderLatest();
    }
  }

  // RedGiant OS: the newest published release whose assets carry the images (the same release
  // `redgiant-os-release` names for the Proxmox script).
  async function loadOs() {
    const rows = $$("[data-os]");
    if (!rows.length) return;
    const list = await getJson("/releases?per_page=30", "rg-site-releases");
    if (!Array.isArray(list)) return;
    const iso = new RegExp(`^redgiant-os-(.+)-${cfg.osImages.iso.replace(/\./g, "\\.")}$`);
    const rel = list.find(
      (r) => !r.draft && !r.prerelease && r.assets?.some((a) => iso.test(a.name)),
    );
    if (!rel) return;
    const version = rel.assets.map((a) => iso.exec(a.name)?.[1]).find(Boolean);
    for (const a of rows) {
      const suffix = cfg.osImages[a.dataset.os];
      const name = `redgiant-os-${version}-${suffix}`;
      const asset = rel.assets.find((x) => x.name === name);
      if (!asset || !/^https:\/\/github\.com\//.test(asset.browser_download_url)) continue;
      a.href = asset.browser_download_url;
      const file = a.closest(".os-row")?.querySelector(".file");
      if (file) file.textContent = name;
    }
    const note = document.getElementById("os-release");
    if (note) {
      for (const v of $$("[data-os-v]", note)) v.textContent = rel.tag_name;
      for (const l of $$("[data-os-link]", note)) {
        if (/^https:\/\/github\.com\//.test(rel.html_url)) l.href = rel.html_url;
      }
      note.hidden = false;
    }
  }

  // Mascots pause while the page is not in front (as in RedGiant's page).
  const sync = () => d.classList.toggle("rg-hidden", document.hidden);
  document.addEventListener("visibilitychange", sync);
  sync();

  applyTheme(d.dataset.theme || "system");
  applyLang(d.lang === "it" ? "it" : "en");
  loadLatest();
  loadOs();
})();
