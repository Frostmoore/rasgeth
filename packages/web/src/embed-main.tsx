// The page inside RGCompanion (G42.0): `/embed.html#token=…&embed=…`. A root of its own, light:
// the page's App (bar, tabs, conversations, Settings) is never loaded here.
import { render } from "preact";
import "./styles.css";
import { EmbedRoot } from "./components/Embed.js";
import { takeEmbed } from "./embed.js";

const params = takeEmbed();
const root = document.getElementById("app");
if (root && params) render(<EmbedRoot params={params} />, root);
else location.replace("/");
