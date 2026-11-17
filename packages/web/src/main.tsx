import { render } from "preact";
import { App } from "./components/App.js";
import "./styles.css";
import { listenPreviewLinks } from "./preview-links.js";
import { applyTheme } from "./theme.js";

applyTheme();
listenPreviewLinks();

const root = document.getElementById("app");
// The page inside RGCompanion has an entry of its own (embed.html, G42.0): a link to `/#embed=…`
// goes there with its fragment.
if (new URLSearchParams(location.hash.slice(1)).has("embed"))
  location.replace(`/embed.html${location.hash}`);
else if (root && location.hash === "#ui-gallery")
  void import("./dev/Gallery.js").then(({ Gallery }) => render(<Gallery />, root));
else if (root) render(<App />, root);

// Installable as an app (G20.9); the worker caches nothing, see public/sw.js.
if ("serviceWorker" in navigator && location.protocol !== "file:")
  void navigator.serviceWorker.register("/sw.js").catch(() => {});
