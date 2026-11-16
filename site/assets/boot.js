// Runs before the page is drawn: the language (saved, or the browser's) and the theme.
(() => {
  const d = document.documentElement;
  let lang = null;
  let theme = null;
  try {
    lang = localStorage.getItem("rg-site-lang");
    theme = localStorage.getItem("rg-site-theme");
  } catch {}
  if (lang !== "it" && lang !== "en") {
    const langs = navigator.languages?.length ? navigator.languages : [navigator.language || "en"];
    const first = langs.find((l) => /^(it|en)\b/i.test(l));
    lang = first && /^it/i.test(first) ? "it" : "en";
  }
  d.lang = lang;
  d.dataset.theme = theme === "light" || theme === "dark" ? theme : "system";
})();
